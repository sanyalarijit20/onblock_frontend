import '/core/network/api_client.dart';
import '../auth/secure_storage.dart';
import '/models/user_models.dart';
import '../../models/transaction_model.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final SecureStorage _storage = SecureStorage();

  /// Helper to extract and save wallet address if present
  Future<void> _cacheWalletAddress(Map<String, dynamic> data) async {
    // Check various common paths where backend might return the address
    String? address;
    
    if (data['walletAddress'] != null) {
      address = data['walletAddress'];
    } else if (data['user'] != null && data['user']['walletAddress'] != null) {
      address = data['user']['walletAddress'];
    } else if (data['user'] != null && data['user']['wallet'] != null) {
      // If backend returns populated wallet object
      address = data['user']['wallet']['smartAccountAddress'];
    }

    if (address != null && address.isNotEmpty) {
      await _storage.saveWalletAddress(address);
    }
  }

  /// Step 1: Register basic info + Aadhaar
  Future<UserModel?> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String aadhaarNumber,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'aadhaarNumber': aadhaarNumber,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.saveJwt(data['accessToken']);
        
        // SAVE WALLET ADDRESS
        await _cacheWalletAddress(data);

        return UserModel.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
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

  /// Login via Passkey/Password
  Future<bool> verifyPasskey(String passkey) async {
    try {
      final String? identifier = await _storage.getWalletAddress(); // Or email
      
      // Fallback: If no wallet address in storage (e.g. fresh install), we will try getting email via social recovery. 
      // For now, proceeding with identifier. In real app, user will type email.
      
      final response = await _apiClient.post('/auth/login', data: {
        'identifier': identifier ?? "user@example.com", 
        'password': passkey,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storage.saveJwt(data['accessToken']);
        
        // SAVE WALLET ADDRESS on Login
        await _cacheWalletAddress(data);
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get Current User Profile
  Future<UserModel?> getProfile() async {
    try {
      final response = await _apiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        // Ensure wallet address is cached whenever we fetch profile
        await _cacheWalletAddress({'user': data});
        
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch Transaction History
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
      return [];
    }
  }
}