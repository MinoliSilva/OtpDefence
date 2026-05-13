import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otp_defense/models/risk_classification.dart';
import 'package:otp_defense/services/accessibility_channel.dart';

class OtpListNotifier extends Notifier<List<AnalyzedOtp>> {
  static const String _storageKey = 'otp_defense_history_v2';
  SharedPreferences? _prefs;

  @override
  List<AnalyzedOtp> build() {
    state = [];
    _initStorageAndLoad();
    _initAccessibility();
    return state;
  }

  Future<void> _initStorageAndLoad() async {
    _prefs = await SharedPreferences.getInstance();
    final List<String>? storedJson = _prefs?.getStringList(_storageKey);
    
    if (storedJson != null) {
      final now = DateTime.now();
      final List<AnalyzedOtp> loadedOtps = [];
      
      for (final jsonString in storedJson) {
        try {
          final otp = AnalyzedOtp.fromJson(jsonDecode(jsonString));
          
          // Auto-Delete core rule: If it's older than 7 days, drop it completely.
          if (now.difference(otp.timestamp).inDays <= 7) {
            loadedOtps.add(otp);
          }
        } catch (e) {
          // ignore corrupted items
        }
      }
      
      state = loadedOtps;
      // Re-save immediately in case old items were dropped
      _saveToDisk();
    }
  }

  Future<void> _saveToDisk() async {
    if (_prefs == null) return;
    
    final List<String> encodedList = state.map((otp) {
      return jsonEncode(otp.toJson());
    }).toList();
    
    await _prefs?.setStringList(_storageKey, encodedList);
  }

  void _initAccessibility() {
    final channel = AccessibilityChannelService();
    channel.onNewAlert = (otp) {
      state = [otp, ...state]; // Add new OTP to top of list
      _saveToDisk();
    };
    channel.initialize();
  }

  void clearLogs() {
    state = [];
    _saveToDisk();
  }

  void toggleStar(String id) {
    state = [
      for (final otp in state)
        if (otp.id == id) otp.copyWith(isStarred: !otp.isStarred) else otp,
    ];
    _saveToDisk();
  }

  void toggleVault(String id) {
    state = [
      for (final otp in state)
        if (otp.id == id) otp.copyWith(isVaulted: !otp.isVaulted) else otp,
    ];
    _saveToDisk();
  }

  // Moves items to Recycle Bin instead of deleting them entirely
  void deleteOtps(List<String> ids) {
    state = state.map((otp) {
      if (ids.contains(otp.id)) {
        return otp.copyWith(isDeleted: true);
      }
      return otp;
    }).toList();
    _saveToDisk();
  }

  // Restores items from the Recycle Bin
  void restoreOtps(List<String> ids) {
    state = state.map((otp) {
      if (ids.contains(otp.id)) {
        return otp.copyWith(isDeleted: false);
      }
      return otp;
    }).toList();
    _saveToDisk();
  }

  // Permanently purges items
  void permanentDelete(List<String> ids) {
    state = state.where((otp) => !ids.contains(otp.id)).toList();
    _saveToDisk();
  }
}

final otpListProvider = NotifierProvider<OtpListNotifier, List<AnalyzedOtp>>(() {
  return OtpListNotifier();
});
