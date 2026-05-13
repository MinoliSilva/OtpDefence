import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:otp_defense/models/risk_classification.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _plugin.initialize(settings: initializationSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showDefenseAlert(AnalyzedOtp otp) async {
    // Always show notification for safe OTPs for convenience (Magic OTP Feature)
    // For Warning/HighRisk, we show an alert. 
    // For Spam, we might silent it, but let's show it for now in a specific category.

    final bool isSafe = otp.riskLevel == RiskLevel.safe;
    
    if (otp.riskLevel == RiskLevel.spam) return; // Silent spam

    final String title = isSafe
        ? '✅ Safe OTP Received'
        : otp.riskLevel == RiskLevel.highRisk
            ? '🚨 HIGH RISK OTP DETECTED'
            : '⚠️ Suspicious OTP Warning';

    final String body = isSafe 
        ? 'Sender: ${otp.sender}\nOTP: ${otp.extractedCode ?? "Detected"}' 
        : 'From: ${otp.sender}\nFlagged for: ${otp.triggeredRules.join(", ")}';

    final Color color = isSafe ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isSafe ? 'otp_safe_channel' : 'otp_defense_channel',
      isSafe ? 'Safe OTPs' : 'OTP Alerts',
      channelDescription: isSafe ? 'Convenient access to safe OTPs' : 'Security alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'OTP Defense',
      color: color,
      // Adding action buttons for Safe OTPs
      actions: otp.hasCode && isSafe
          ? [
              const AndroidNotificationAction(
                'copy_otp',
                'Copy OTP',
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ]
          : null,
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: otp.timestamp.millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: otp.extractedCode, // Pass the code in payload for handling clicks
    );
  }
}
