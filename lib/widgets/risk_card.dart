import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp_defense/models/risk_classification.dart';
import 'package:otp_defense/theme/app_theme.dart';
import 'package:otp_defense/services/bank_registry_service.dart';
import 'package:otp_defense/widgets/risk_badge.dart';
import 'package:intl/intl.dart';

import 'package:flutter_animate/flutter_animate.dart';

class RiskCard extends StatelessWidget {
  final AnalyzedOtp otp;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onStar;
  final VoidCallback? onVault;
  final VoidCallback? onReport;

  const RiskCard({
    super.key,
    required this.otp,
    this.isSelected = false,
    this.selectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onStar,
    this.onVault,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _scoreColor(otp.riskLevel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected 
            ? theme.colorScheme.primary.withValues(alpha: 0.08) 
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (selectionMode) ...[
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? theme.colorScheme.primary : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                      ],
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: scoreColor.withValues(alpha: 0.1),
                        child: Icon(_levelIcon(otp.riskLevel), color: scoreColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          otp.sender,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (BankRegistryService.isVerified(otp.sender)) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 10),
                                      const SizedBox(width: 4),
                                      Text('AI SCANNED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              DateFormat('HH:mm • dd MMM').format(otp.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                        IconButton(
                          icon: Icon(
                            otp.isVaulted ? Icons.lock_rounded : Icons.lock_outline_rounded,
                            color: otp.isVaulted ? AppTheme.successGreen : Colors.grey.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          onPressed: onVault,
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Vault',
                        ),
                        IconButton(
                          icon: Icon(
                            otp.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: otp.isStarred ? Colors.amber : Colors.grey.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          onPressed: onStar,
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Star',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    otp.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Risk Score: ${otp.riskScore}%',
                                  style: TextStyle(
                                    fontSize: 11, 
                                    fontWeight: FontWeight.bold, 
                                    color: scoreColor,
                                  ),
                                ),
                                RiskBadge(level: otp.riskLevel),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: otp.riskScore / 100,
                                backgroundColor: scoreColor.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (otp.hasCode) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: otp.extractedCode!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('OTP ${otp.extractedCode} copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              width: 250,
                              backgroundColor: AppTheme.successGreen,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text('COPY ${otp.extractedCode}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: otp.riskLevel == RiskLevel.safe 
                              ? AppTheme.successGreen 
                              : otp.riskLevel == RiskLevel.warning 
                                  ? AppTheme.warningOrange 
                                  : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Standard reporting logic
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reporting to Security Community...'))
                              );
                            },
                            icon: const Icon(Icons.report_problem_rounded, size: 16),
                            label: const Text('REPORT THREAT'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorRed,
                              side: const BorderSide(color: AppTheme.errorRed),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, curve: Curves.easeOut);
  }

  Color _scoreColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe: return AppTheme.successGreen;
      case RiskLevel.spam: return AppTheme.secondaryLight;
      case RiskLevel.warning: return AppTheme.warningOrange;
      case RiskLevel.highRisk: return AppTheme.errorRed;
    }
  }

  IconData _levelIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.safe: return Icons.verified_user_rounded;
      case RiskLevel.spam: return Icons.mark_email_read_rounded;
      case RiskLevel.warning: return Icons.warning_amber_rounded;
      case RiskLevel.highRisk: return Icons.gpp_bad_rounded;
    }
  }
}
