import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otp_defense/models/risk_classification.dart';
import 'package:otp_defense/providers/otp_provider.dart';
import 'package:otp_defense/providers/protection_provider.dart';
import 'package:otp_defense/providers/theme_provider.dart';
import 'package:otp_defense/services/local_notification_service.dart';
import 'package:otp_defense/services/supabase_service.dart';
import 'package:otp_defense/services/risk_scoring_engine.dart';
import 'package:otp_defense/services/biometric_service.dart';
import 'package:otp_defense/theme/app_theme.dart';
import 'package:otp_defense/widgets/risk_badge.dart';
import 'package:otp_defense/widgets/risk_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  try {
    await LocalNotificationService.initialize();
  } catch (e) {
    debugPrint('Notification service initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: OtpDefenseApp(),
    ),
  );
}

class OtpDefenseApp extends ConsumerWidget {
  const OtpDefenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'OTP Defense',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const InboxTab(),
    const VaultTab(),
    const SecurityLabTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline_rounded),
            selectedIcon: Icon(Icons.mail_rounded),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outline_rounded),
            selectedIcon: Icon(Icons.lock_rounded),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science_rounded),
            label: 'Lab & Sandbox',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. DASHBOARD TAB
// ==========================================
class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProtected = ref.watch(protectionProvider);
    final otpList = ref.watch(otpListProvider).where((otp) => !otp.isDeleted).toList();
    final theme = Theme.of(context);

    // Calculate dynamic security statistics
    final totalScanned = otpList.length;
    final criticalThreats = otpList.where((otp) => otp.riskLevel == RiskLevel.highRisk).length;
    final warnings = otpList.where((otp) => otp.riskLevel == RiskLevel.warning).length;
    final safeOtps = otpList.where((otp) => otp.riskLevel == RiskLevel.safe).length;
    final spams = otpList.where((otp) => otp.riskLevel == RiskLevel.spam).length;

    // Calculate system security score (Default: 100%, drops for each high risk or warning not vaulted/ignored)
    int securityScore = 100;
    if (totalScanned > 0) {
      final deductions = (criticalThreats * 15) + (warnings * 5);
      securityScore = (100 - deductions).clamp(35, 100);
    }
    if (!isProtected) {
      securityScore = (securityScore - 25).clamp(20, 100);
    }

    Color scoreColor = AppTheme.successGreen;
    if (securityScore < 50) {
      scoreColor = AppTheme.errorRed;
    } else if (securityScore < 80) {
      scoreColor = AppTheme.warningOrange;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OTP DEFENSE ENGINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Shield Dashboard',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  theme.brightness == Brightness.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
            ],
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          // Central Pulse Security Score Indicator
          Center(
            child: Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: scoreColor.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
                border: Border.all(
                  color: scoreColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring animation
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: CircularProgressIndicator(
                      value: securityScore / 100,
                      strokeWidth: 10,
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.white10
                          : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                   .shimmer(duration: 3000.ms, color: Colors.white24),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isProtected ? Icons.shield_rounded : Icons.shield_outlined,
                        color: scoreColor,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$securityScore%',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.black,
                          fontSize: 48,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isProtected ? 'SYSTEM PROTECTED' : 'SYSTEM VULNERABLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.backOut),

          const SizedBox(height: 30),

          // Quick Protection Toggle Widget
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (isProtected ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.15),
                    child: Icon(
                      isProtected ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
                      color: isProtected ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isProtected ? 'Active Protection Enabled' : 'Protection Disabled',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isProtected
                              ? 'Scanning SMS notifications in real-time.'
                              : 'Enable accessibility permissions to shield.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isProtected,
                    activeColor: AppTheme.successGreen,
                    onChanged: (val) {
                      ref.read(protectionProvider.notifier).toggleProtection();
                    },
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

          const SizedBox(height: 24),

          // Statistics Header
          Text(
            'Security Insights',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 12),

          // Statistics Grid (2x2 Grid)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(
                title: 'Total Analyzed',
                value: '$totalScanned',
                icon: Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                context: context,
              ),
              _buildStatCard(
                title: 'Safe Messages',
                value: '$safeOtps',
                icon: Icons.security_rounded,
                color: AppTheme.successGreen,
                context: context,
              ),
              _buildStatCard(
                title: 'Phishing Attacks',
                value: '$criticalThreats',
                icon: Icons.gpp_bad_rounded,
                color: AppTheme.errorRed,
                context: context,
              ),
              _buildStatCard(
                title: 'Spam Trivial',
                value: '$spams',
                icon: Icons.mark_email_read_rounded,
                color: AppTheme.warningOrange,
                context: context,
              ),
            ],
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 22),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. INBOX TAB (SMS LOGS)
// ==========================================
class InboxTab extends ConsumerStatefulWidget {
  const InboxTab({super.key});

  @override
  ConsumerState<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends ConsumerState<InboxTab> {
  String _searchQuery = '';
  RiskLevel? _selectedFilter;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final rawOtpList = ref.watch(otpListProvider);
    final theme = Theme.of(context);

    // Filters: ignore deleted, filter by search & risk level
    final filteredOtpList = rawOtpList.where((otp) {
      if (otp.isDeleted) return false;
      
      final matchesSearch = otp.sender.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          otp.message.toLowerCase().contains(_searchQuery.toLowerCase());
          
      final matchesFilter = _selectedFilter == null || otp.riskLevel == _selectedFilter;
      
      return matchesSearch && matchesFilter;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectionMode ? '${_selectedIds.length} Selected' : 'Secure Inbox',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (_selectionMode) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.errorRed),
                      onPressed: () {
                        if (_selectedIds.isNotEmpty) {
                          ref.read(otpListProvider.notifier).deleteOtps(_selectedIds.toList());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Items moved to recycle bin'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          setState(() {
                            _selectedIds.clear();
                            _selectionMode = false;
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        setState(() {
                          _selectedIds.clear();
                          _selectionMode = false;
                        });
                      },
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.select_all_rounded),
                      onPressed: () {
                        setState(() {
                          _selectionMode = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Purge Logs',
                      onPressed: () {
                        _showClearLogsDialog(context);
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Bar
          TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search senders, keywords...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.cardTheme.color,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.dividerColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Quick Filters Row
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(null, 'ALL'),
                _buildFilterChip(RiskLevel.safe, 'SAFE'),
                _buildFilterChip(RiskLevel.warning, 'WARNINGS'),
                _buildFilterChip(RiskLevel.highRisk, 'CRITICAL'),
                _buildFilterChip(RiskLevel.spam, 'SPAM'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Messages List
          Expanded(
            child: filteredOtpList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mail_lock_rounded,
                          size: 64,
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Inbox Clean & Secure',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No messages match your criteria.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredOtpList.length,
                    itemBuilder: (context, index) {
                      final otp = filteredOtpList[index];
                      final isSelected = _selectedIds.contains(otp.id);

                      return RiskCard(
                        otp: otp,
                        isSelected: isSelected,
                        selectionMode: _selectionMode,
                        onTap: () {
                          if (_selectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedIds.remove(otp.id);
                              } else {
                                _selectedIds.add(otp.id);
                              }
                            });
                          } else {
                            // Open detail dialog
                            _showOtpDetailDialog(context, otp);
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            _selectionMode = true;
                            _selectedIds.add(otp.id);
                          });
                        },
                        onStar: () {
                          ref.read(otpListProvider.notifier).toggleStar(otp.id);
                        },
                        onVault: () {
                          ref.read(otpListProvider.notifier).toggleVault(otp.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(otp.isVaulted ? 'Moved to Secure Vault' : 'Removed from Vault'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(RiskLevel? level, String label) {
    final isSelected = _selectedFilter == level;
    final theme = Theme.of(context);
    final color = level == RiskLevel.safe
        ? AppTheme.successGreen
        : level == RiskLevel.warning
            ? AppTheme.warningOrange
            : level == RiskLevel.highRisk
                ? AppTheme.errorRed
                : level == RiskLevel.spam
                    ? AppTheme.secondaryLight
                    : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? level : null;
          });
        },
        selectedColor: color,
        backgroundColor: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        showCheckmark: false,
      ),
    );
  }

  void _showClearLogsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text('This will clear your local scan inbox database history permanently. Active phishing defenses will still remain alert.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () {
              ref.read(otpListProvider.notifier).clearLogs();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inbox cleared successfully')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showOtpDetailDialog(BuildContext context, AnalyzedOtp otp) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otp.sender,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm:ss').format(otp.timestamp),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  RiskBadge(level: otp.riskLevel),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'SMS PAYLOAD MESSAGE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? Colors.white5 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  otp.message,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ANALYSIS SIGNALS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ...otp.triggeredRules.map((sig) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        Icon(Icons.gpp_maybe_outlined, color: theme.colorScheme.primary, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sig,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. SECURE VAULT TAB
// ==========================================
class VaultTab extends ConsumerStatefulWidget {
  const VaultTab({super.key});

  @override
  ConsumerState<VaultTab> createState() => _VaultTabState();
}

class _VaultTabState extends ConsumerState<VaultTab> {
  bool _unlocked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    // Do not auto authenticate so user doesn't get blocked immediately
  }

  Future<void> _unlockVault() async {
    setState(() {
      _authenticating = true;
    });

    final success = await BiometricService.authenticate(
      reason: 'Authenticate to view secure credentials in OTP Vault.',
    );

    setState(() {
      _unlocked = success;
      _authenticating = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vault Access Granted ✅'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vault Access Denied ❌'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultList = ref.watch(otpListProvider).where((otp) => otp.isVaulted && !otp.isDeleted).toList();

    if (!_unlocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.cardTheme.color,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.15), width: 1.5),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 54,
                  color: AppTheme.successGreen,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .slideY(begin: -0.05, end: 0.05, duration: 1500.ms, curve: Curves.easeInOut),
              const SizedBox(height: 32),
              Text(
                'Biometric Secured Vault',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Securely isolate delicate banking OTP notifications and safe credentials in highly encrypted memory storage.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _authenticating ? null : _unlockVault,
                  icon: _authenticating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.fingerprint_rounded),
                  label: Text(_authenticating ? 'Authenticating...' : 'UNLOCK VAULT'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _unlocked = true; // Simulated bypass/fallback
                  });
                },
                child: const Text('Simulate Bypass (Dev Mode)'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_open_rounded, color: AppTheme.successGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Vault Items',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.lock_rounded, color: AppTheme.warningOrange),
                onPressed: () {
                  setState(() {
                    _unlocked = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: vaultList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_zip_outlined,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Encrypted Items',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the lock icon in normal cards to isolate them here.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: vaultList.length,
                    itemBuilder: (context, index) {
                      final otp = vaultList[index];
                      return RiskCard(
                        otp: otp,
                        onStar: () {
                          ref.read(otpListProvider.notifier).toggleStar(otp.id);
                        },
                        onVault: () {
                          ref.read(otpListProvider.notifier).toggleVault(otp.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. SECURITY LAB / SIMULATOR TAB
// ==========================================
class SecurityLabTab extends ConsumerStatefulWidget {
  const SecurityLabTab({super.key});

  @override
  ConsumerState<SecurityLabTab> createState() => _SecurityLabTabState();
}

class _SecurityLabTabState extends ConsumerState<SecurityLabTab> {
  final TextEditingController _senderController = TextEditingController(text: 'ComBank');
  final TextEditingController _messageController = TextEditingController(
      text: 'Dear Customer, your Commercial Bank OTP is 283917. Never share it with anyone.');
  bool _isScanning = false;

  final RiskScoringEngine _engine = RiskScoringEngine();

  @override
  void dispose() {
    _senderController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _runSandboxScan() async {
    final sender = _senderController.text.trim();
    final message = _messageController.text.trim();

    if (sender.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter sender details and text content')),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    // Run engine analysis
    final analysis = await _engine.analyze(sender, message);

    // Save to database/analytics & Riverpod provider
    // Trigger accessibility listener callback simulation
    final notifier = ref.read(otpListProvider.notifier);
    notifier.state = [analysis, ...notifier.state];

    // Trigger local notification trigger
    await LocalNotificationService.showDefenseAlert(analysis);

    setState(() {
      _isScanning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Scan Complete: Detected ${analysis.riskLevel.name.toUpperCase()}'),
        backgroundColor: analysis.riskLevel == RiskLevel.safe
            ? AppTheme.successGreen
            : analysis.riskLevel == RiskLevel.highRisk
                ? AppTheme.errorRed
                : AppTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _loadTemplate(String sender, String message) {
    setState(() {
      _senderController.text = sender;
      _messageController.text = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEMO SECURITY LAB',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'SMS OTP Simulator',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Simulate and test incoming SMS message feeds in real-time. Extremely useful for testing database triggers, heuristics, and semantic AI classifiers.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4),
          ),

          const SizedBox(height: 24),

          // Scan Box Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Sender Identity (ID/Number)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _senderController,
                    decoration: InputDecoration(
                      hintText: 'e.g. SAMPATH, Dialog, +94771234567',
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark ? Colors.white5 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '2. SMS Message Payload Content',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Dear customer, your bank account is suspended...',
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark ? Colors.white5 : Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isScanning ? null : _runSandboxScan,
                      icon: _isScanning
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.bolt_rounded),
                      label: Text(_isScanning ? 'ANALYZING THREAT...' : 'TRIGGER INCOMING MOCK SMS'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),

          const SizedBox(height: 24),

          // Demo Templates Header
          Text(
            'Demo Test Templates',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Template Items List
          _buildTemplateItem(
            title: 'Verified Official Bank OTP',
            subtitle: 'Legitimate Commercial Bank notification.',
            sender: 'ComBank',
            message: 'ComBank OTP: 194852. Valid for 3 mins. Do not share this OTP.',
            level: RiskLevel.safe,
          ),
          _buildTemplateItem(
            title: 'Verified Telecom Promo Campaign',
            subtitle: 'Legitimate bulk promotional broadcast.',
            sender: 'Dialog',
            message: 'Get 10GB Free Data on Dialog reload packs of Rs.450. Dial #121# today.',
            level: RiskLevel.spam,
          ),
          _buildTemplateItem(
            title: 'Critical Phishing URL Scam',
            subtitle: 'Fired by suspicious host heuristic rules.',
            sender: 'BOC',
            message: 'Dear customer, your BOC account has suspicious logins. Re-verify instantly at https://boc-portal-srilanka.net to prevent blockage.',
            level: RiskLevel.highRisk,
          ),
          _buildTemplateItem(
            title: 'High-Urgency Identity Spoofing',
            subtitle: 'Fired by private sender ID combined with urgency.',
            sender: '+94772183918',
            message: 'URGENT HNB ALERT: Your debit card is temporarily blocked. Verify 982173 OTP immediately to restore service.',
            level: RiskLevel.highRisk,
          ),
          _buildTemplateItem(
            title: 'Sinhala Urgent Threat Account Suspended',
            subtitle: 'Heuristic keyword match in Sri Lankan context.',
            sender: 'SampathBank',
            message: 'ගිණුම අත්හිටුවා ඇත. Sampath bank verification, update now.',
            level: RiskLevel.highRisk,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateItem({
    required String title,
    required String subtitle,
    required String sender,
    required String message,
    required RiskLevel level,
  }) {
    final theme = Theme.of(context);
    final indicatorColor = level == RiskLevel.safe
        ? AppTheme.successGreen
        : level == RiskLevel.warning
            ? AppTheme.warningOrange
            : level == RiskLevel.highRisk
                ? AppTheme.errorRed
                : AppTheme.secondaryLight;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _loadTemplate(sender, message),
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }
}
