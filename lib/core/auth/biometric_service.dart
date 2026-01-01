import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

/// Handles local device security (Fingerprint, Facial Recognition, and Passkey/PIN)
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the hardware supports biometrics OR has a device lock (PIN/Passkey)
  Future<bool> isSecure() async {
    final bool canCheck = await _auth.canCheckBiometrics;
    final bool isSupported = await _auth.isDeviceSupported();
    return canCheck || isSupported;
  }

  /// General authentication method
  Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          // Set to false to allow PIN/Passkey fallback 
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      // Log specific errors for debugging 
      print("Auth Error Code: ${e.code} - ${e.message}");
      return false;
    }
  }

  /// Specific handler for App Entry
  /// Supports: Facial Recognition, Fingerprint, and Passkey
  Future<bool> authenticateForEntry() async {
    return await authenticate(
      reason: 'Unlock BlockPay to manage your wallet',
      biometricOnly: false,
    );
  }

  /// Specific handler for Payments
  Future<bool> authenticateForPayment(double amount, String symbol) async {
    return await authenticate(
      reason: 'Confirm payment of $amount $symbol',
      biometricOnly: false,
    );
  }

  /// Returns the list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
  }
}