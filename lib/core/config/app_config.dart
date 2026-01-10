

class AppConfig {
  /// Toggle this to [true] for the Vercel deployment.
  static const bool isProduction = false;

  
  static const bool useMockAi = false; 
  static const bool bypassBiometrics = false; // Set true for rapid UI testing if sensor is unavailable


  
  /// The Vercel deployment URL (Mock)
  static const String _productionBaseUrl = "https://onblock-backend.vercel.app/api/v1";

  /// The local development URL
  static const String _localBaseUrl = "http://10.253.244.112:5000/api/v1";

  /// Logic to determine the active Base URL
  static String get baseUrl {
    if (isProduction) return _productionBaseUrl;
    return _localBaseUrl;
  }

  // --- App Metadata ---
  static const String appName = 'BlockPay';
  static const String appVersion = '1.0.0';

  // --- Dio Timeout Configuration ---
  static const int connectionTimeout = 15000;
  static const int receiveTimeout = 15000;

  // --- Blockchain Defaults ---
  static const int defaultChainId = 11155111; // Sepolia Testnet
  static const String defaultNetwork = "sepolia";
}