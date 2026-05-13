import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keySetupComplete = 'setup_complete';
  static const String _keyScanningEnabled = 'scanning_enabled';
  static const String _keyTrustedSenders = 'trusted_senders';
  static const String _keyBlockedSenders = 'blocked_senders';

  static Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  static Future<bool> isSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySetupComplete) ?? false;
  }

  static Future<void> setSetupComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySetupComplete, value);
  }

  static Future<bool> isScanningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyScanningEnabled) ?? true;
  }

  static Future<void> setScanningEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyScanningEnabled, value);
  }

  static Future<List<String>> getTrustedSenders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyTrustedSenders) ?? [];
  }

  static Future<void> addTrustedSender(String sender) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyTrustedSenders) ?? [];
    if (!list.contains(sender.trim())) {
      list.add(sender.trim());
      await prefs.setStringList(_keyTrustedSenders, list);
    }
  }

  static Future<void> removeTrustedSender(String sender) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyTrustedSenders) ?? [];
    list.remove(sender);
    await prefs.setStringList(_keyTrustedSenders, list);
  }

  static Future<List<String>> getBlockedSenders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyBlockedSenders) ?? [];
  }

  static Future<void> addBlockedSender(String sender) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyBlockedSenders) ?? [];
    if (!list.contains(sender.trim())) {
      list.add(sender.trim());
      await prefs.setStringList(_keyBlockedSenders, list);
    }
  }

  static Future<void> removeBlockedSender(String sender) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyBlockedSenders) ?? [];
    list.remove(sender);
    await prefs.setStringList(_keyBlockedSenders, list);
  }
}
