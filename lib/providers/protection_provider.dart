import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otp_defense/services/accessibility_channel.dart';

final protectionProvider = NotifierProvider<ProtectionNotifier, bool>(() {
  return ProtectionNotifier();
});

class ProtectionNotifier extends Notifier<bool> {
  @override
  bool build() {
    checkStatus();
    // Periodically re-check status
    Timer.periodic(const Duration(seconds: 5), (_) => checkStatus());
    return false;
  }

  Future<void> checkStatus() async {
    final enabled = await AccessibilityChannelService.isAccessibilityServiceEnabled();
    if (state != enabled) {
      state = enabled;
    }
  }

  Future<void> toggleProtection() async {
    if (!state) {
      await AccessibilityChannelService.openAccessibilitySettings();
    }
  }
}
