import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles encrypted storage of sensitive data (JWT, Private Keys, DeviceID)
class SecureStorage {
  final _storage = const FlutterSecureStorage();

  // Keys
  static const _keyJwt = 'jwt_token';
  static const _keyWalletAddress = 'wallet_address';
  static const _keyPrivateKey = 'private_key';
  static const _keyDeviceId = 'device_id';

  // --- Auth Checks ---

  /// Returns true if a JWT exists (session is active)
  Future<bool> hasToken() async {
    final token = await getJwt();
    return token != null && token.isNotEmpty;
  }

  /// Returns true if a Private Key exists (user has a wallet on this device)
  Future<bool> hasWallet() async {
    final key = await getPrivateKey();
    return key != null && key.isNotEmpty;
  }

  // --- Storage Operations ---

  Future<void> saveJwt(String token) async => await _storage.write(key: _keyJwt, value: token);
  Future<String?> getJwt() async => await _storage.read(key: _keyJwt);
  Future<void> deleteJwt() async => await _storage.delete(key: _keyJwt);

  Future<void> saveWalletAddress(String address) async => await _storage.write(key: _keyWalletAddress, value: address);
  Future<String?> getWalletAddress() async => await _storage.read(key: _keyWalletAddress);

  Future<void> saveDeviceId(String id) async => await _storage.write(key: _keyDeviceId, value: id);
  Future<String?> getDeviceId() async => await _storage.read(key: _keyDeviceId);

  Future<void> savePrivateKey(String key) async => await _storage.write(key: _keyPrivateKey, value: key);
  Future<String?> getPrivateKey() async => await _storage.read(key: _keyPrivateKey);

  /// Standard Logout: Only clears the session token.
  /// The Private Key and Wallet Address remain so the user can log back in after triggering logout
  Future<void> logout() async {
    await deleteJwt();
  }

  /// Full Reset: Happens when delete account option is triggered
  /// This WILL delete the private key forever from this device.
  Future<void> wipeAllData() async {
    await _storage.deleteAll();
  }
}