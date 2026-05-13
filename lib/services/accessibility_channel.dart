import 'package:flutter/services.dart';
import 'package:otp_defense/models/risk_classification.dart';
import 'package:otp_defense/services/risk_scoring_engine.dart';
import 'package:otp_defense/services/local_notification_service.dart';
import 'package:otp_defense/services/supabase_service.dart';

class AccessibilityChannelService {
  static const MethodChannel _accessibilityChannel = MethodChannel('com.example.otp_defense/accessibility');
  static const MethodChannel _permissionChannel = MethodChannel('com.example.otp_defense/permissions');
  
  final RiskScoringEngine _engine = RiskScoringEngine();

  // Callback to inform UI of new alerts
  Function(AnalyzedOtp)? onNewAlert;

  void initialize() {
    _accessibilityChannel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<bool> isAccessibilityServiceEnabled() async {
    return await _permissionChannel.invokeMethod('isAccessibilityServiceEnabled') ?? false;
  }

  static Future<void> openAccessibilitySettings() async {
    await _permissionChannel.invokeMethod('openAccessibilitySettings');
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    await _permissionChannel.invokeMethod('requestIgnoreBatteryOptimizations');
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onNotificationReceived') {
      final Map<dynamic, dynamic> data = call.arguments;
      final String sender = data['sender'] ?? 'Unknown';
      
      final List<dynamic> rawMessages = data['messages'] ?? [];
      final List<String> messages = rawMessages.map((e) => e.toString()).toList();

      for (final message in messages) {
        if (message.isEmpty) continue;

        // Process if it looks like an OTP, contains a URL, or has known phishing/spam keywords
        if (RiskScoringEngine.containsAnalyzableContent(message)) {
          final analysis = await _engine.analyze(sender, message);
          
          // Notify UI state management
          if (onNewAlert != null) {
            onNewAlert!(analysis);
          }

          // Fire native Android heads-up notification if dangerous
          LocalNotificationService.showDefenseAlert(analysis);

          // Sync to Supabase in background
          SupabaseService.logAnalytics(analysis);
        }
      }
    }
  }
}
