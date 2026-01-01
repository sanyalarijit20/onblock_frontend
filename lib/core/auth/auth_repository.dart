import '/core/network/api_client.dart';
import '../auth/secure_storage.dart';
import '/models/user_models.dart';


class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final SecureStorage _storage = SecureStorage();

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
        'aadhaarNumber': aadhaarNumber, // Backend handles verification
      });

      if (response.statusCode == 201) {
        final data = response.data['data'];
        await _storage.saveJwt(data['accessToken']);
        return UserModel.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Step 2: Enroll Face Geometry (ML Microservice)
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

  /// Step 3: Enroll Biometric (Fingerprint)
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

  /// Step 1 Verify: Custom Face Recognition (App-Level)
  /// Maps to POST /auth/facial/verify
  Future<bool> verifyFacialIdentity(String facialData, String base64Image) async {
    try {
      final response = await _apiClient.post('/auth/facial/verify', data: {
        'facialData': facialData,
        'imageData': base64Image,
      });
      // Backend returns { verified: true, confidence: 0.98 ... }
      return response.data['data']['verified'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Step 2 Verify: Biometric Hardware Sync (Optional check with backend)
  /// Maps to POST /auth/biometric/verify
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

  /// Get current profile to refresh the UserModel
  Future<UserModel?> getProfile() async {
    try {
      final response = await _apiClient.get('/auth/me');
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}