import '/core/network/api_client.dart';

class TransactionService {
  // Using ApiClient ensures JWT is attached automatically via interceptors
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> sendTransaction({
    required String to,
    required double amount,
    required String token, // e.g., 'ETH' or 'USDC'
    Map<String, dynamic>? biometricData,
    Map<String, dynamic>? facialData,
    String network = 'polygon', // Default network as per controller logic
  }) async {
    
    // MAPPING DATA TO BACKEND EXPECTATIONS
    // The controller expects: { to, amount, token, network, biometricData, facialData, metadata }
    final body = {
      'to': to,
      'amount': amount,
      'token': {
        'symbol': token,
        // In a real app, we would look up the address based on the symbol
        'address': (token == 'ETH' || token == 'POL') ? null : '0x...', 
        'decimals': 18
      },
      'network': network,
      'biometricData': biometricData ?? {}, // Pass empty object if null, allows the app to fail gracefully 
      'facialData': facialData ?? {},       // Pass empty object if null, same as above
      'metadata': {
        'source': 'mobile_app',
        'timestamp': DateTime.now().toIso8601String(),
      }
    };

    try {
      // Calls /transactions/send with proper headers managed by ApiClient
      final response = await _apiClient.post('/transactions/send', data: body);

      // ApiClient throws exceptions for 4xx/5xx errors automatically (via Dio).
      // If we reach here, it's a success (200/201).
      return response.data;
      
    } catch (e) {
      // Rethrow to be handled by the UI (EnterAmountScreen)
      rethrow;
    }
  }
}