import '/core/network/api_client.dart';
import '../auth/secure_storage.dart';
import '/models/user_models.dart';
import '../../models/transaction_model.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final SecureStorage _storage = SecureStorage();

  /// Helper to extract and save the unique wallet address (Smart Account)
  Future<void> _cacheWalletAddress(Map<String, dynamic> data) async {
    String? address;
    
    // Support multiple response structures from the Node.js backend
    if (data['walletAddress'] != null) {
      address = data['walletAddress'];
    } else if (data['user'] != null && data['user']['walletAddress'] != null) {
      address = data['user']['walletAddress'];
    } else if (data['user'] != null && data['user']['wallet'] != null) {
      // Handles cases where the wallet object is populated
      address = data['user']['wallet']['address'] ?? data['user']['wallet']['smartAccountAddress'];
    }

    if (address != null && address.isNotEmpty) {
      await _storage.saveWalletAddress(address);
      debugPrint("Identity Cached: $address");
    }
  }

  /// STEP 1: Registration
  /// Sends the identity payload to the Node.js backend to trigger the "Invisible Rail"
  Future<UserModel?> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.saveJwt(data['accessToken']);
        
        // Save the generated Smart Account address to local Secure Storage
        await _cacheWalletAddress(data);

        return UserModel.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      debugPrint("AuthRepo: Registration Failed -> $e");
      rethrow;
    }
  }

  /// STEP 2: Facial Identity Enrollment
  Future<bool> setupFacial(String facialData, String base64Image) async {
    try {
      final response = await _apiClient.post('/auth/facial/setup', data: {
        'facialData': facialData,
        'imageData': base64Image,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// STEP 3: Biometric Hardware Binding
  Future<bool> setupBiometric(String biometricData, String deviceId) async {
    try {
      final response = await _apiClient.post('/auth/biometric/setup', data: {
        'biometricData': biometricData,
        'deviceId': deviceId,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// PAYMENT VERIFICATION: Facial (Used in Scan & Pay flow)
  Future<bool> verifyFacialIdentity(String facialData, String base64Image) async {
    try {
      final response = await _apiClient.post('/auth/facial/verify', data: {
        'facialData': facialData,
        'imageData': base64Image,
      });
      return response.data['data']['verified'] == true;
    } catch (e) {
      return false;
    }
  }

  /// PAYMENT VERIFICATION: Biometric (Used in Scan & Pay flow)
  Future<bool> verifyBiometricHardware(String biometricData) async {
    try {
      final response = await _apiClient.post('/auth/biometric/verify', data: {
        'biometricData': biometricData,
      });
      return response.data['data']['verified'] == true;
    } catch (e) {
      return false;
    }
  }

  /// LOGIN: Validates identity using the device's cached wallet address
  Future<bool> verifyPasskey(String passkey) async {
    try {
      final String? identifier = await _storage.getWalletAddress();
      
      if (identifier == null || identifier.isEmpty) {
        throw Exception("No registered identity found on this device.");
      }
      
      final response = await _apiClient.post('/auth/login', data: {
        'identifier': identifier,
        'password': passkey,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.saveJwt(data['accessToken']);
        await _cacheWalletAddress(data);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("AuthRepo: Login Failed -> $e");
      return false;
    }
  }

  /// PROFILE: Fetch user details and refresh identity cache
  Future<UserModel?> getProfile() async {
    try {
      final response = await _apiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _cacheWalletAddress({'user': data});
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// TRANSACTIONS: Fetch history for the Dashboard
  Future<List<TransactionModel>> getTransactions({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.get('/transactions/history', queryParameters: {
        'page': page,
        'limit': limit,
      });

      if (response.statusCode == 200) {
        final List<dynamic> docs = response.data['data']['docs'] ?? [];
        return docs.map((json) => TransactionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("AuthRepo: Transaction Fetch Failed -> $e");
      return [];
    }
  }
}