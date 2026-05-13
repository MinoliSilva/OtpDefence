import 'package:otp_defense/models/risk_classification.dart';

class SecurityScoreService {
  static double calculateMaturityScore(List<AnalyzedOtp> otps, bool isAccessibilityEnabled) {
    if (otps.isEmpty) return isAccessibilityEnabled ? 70.0 : 30.0;

    double score = 50.0;

    // Protection Status (Critical)
    if (isAccessibilityEnabled) score += 30.0;

    // Threat Mitigation
    final highRisk = otps.where((o) => o.riskLevel == RiskLevel.highRisk).length;
    final warning = otps.where((o) => o.riskLevel == RiskLevel.warning).length;
    
    // Penalize if there are many ignored warnings (in a real app we'd track clicks on "Ignore")
    // For now, having high risk messages in history without being deleted/starred is the metric
    if (highRisk > 5) score -= 10;
    
    // Reward for active usage
    if (otps.length > 20) score += 10;

    return score.clamp(0.0, 100.0);
  }
}
