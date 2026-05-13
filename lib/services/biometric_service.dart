import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  static Future<bool> authenticate({required String reason}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/Pattern fallback if biometrics fail
        ),
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'OTP Defense Vault',
            deviceCredentialsRequiredTitle: 'Authentication Required',
          ),
        ],
      );
      return didAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
