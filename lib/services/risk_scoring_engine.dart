import 'package:otp_defense/models/risk_classification.dart';
import 'package:otp_defense/services/hybrid_risk_engine.dart';

class RiskScoringEngine {
  final _hybridEngine = HybridRiskEngine();

  static bool containsAnalyzableContent(String message) {
    // Check for common OTP or link patterns to avoid processing pure generic texts
    final hasOtp = HybridRiskEngine.extractOtp(message) != null;
    final hasLink = RegExp(r'https?:\/\/[^\s]+').hasMatch(message);
    
    // Check if it's a known telecom promo sender content (often contains free/gb/mb)
    final isPromoLike = message.toLowerCase().contains('free') || 
                       message.toLowerCase().contains('gb') || 
                       message.toLowerCase().contains('mb');

    return hasOtp || hasLink || isPromoLike;
  }

  Future<AnalyzedOtp> analyze(String sender, String message) async {
    return await _hybridEngine.analyze(sender, message);
  }
}
