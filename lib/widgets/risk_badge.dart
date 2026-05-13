import 'package:flutter/material.dart';
import 'package:otp_defense/models/risk_classification.dart';
import 'package:otp_defense/theme/app_theme.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel level;

  const RiskBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _badgeProps(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _badgeProps(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe:
        return ('SAFE', AppTheme.successGreen, Icons.verified_user_rounded);
      case RiskLevel.spam:
        return ('SPAM', AppTheme.secondaryLight, Icons.mark_email_read_rounded);
      case RiskLevel.warning:
        return ('WARNING', AppTheme.warningOrange, Icons.warning_amber_rounded);
      case RiskLevel.highRisk:
        return ('CRITICAL', AppTheme.errorRed, Icons.gpp_bad_rounded);
    }
  }
}
