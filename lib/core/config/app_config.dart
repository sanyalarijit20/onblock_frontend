import 'dart:io';


class AppConfig {
  /// Toggle this to [true] for the Vercel deployment.
  static const bool isProduction = true;

  
  static const bool useMockAi = false; 
  static const bool bypassBiometrics = false; // Set true for rapid UI testing if sensor is unavailable


  
 
  static const String _localIp = "192.168.29.104";
  
  /// The Vercel deployment URL (Mock)
  static const String _productionBaseUrl = "https://onblock-backend.vercel.app/api/v1";

  /// Logic to determine the active Base URL
  static String get baseUrl {
    if (isProduction) return _productionBaseUrl;
    if (Platform.isAndroid && _localIp == "localhost") {
      return "http://10.0.2.2:3000/api/v1";
    }
    
    return "http://$_localIp:3000/api/v1";
  }

  // --- App Metadata ---
  static const String appName = 'BlockPay';
  static const String appVersion = '1.0.0';

  // --- Dio Timeout Configuration ---
  static const int connectionTimeout = 15000;
  static const int receiveTimeout = 15000;

  // --- Blockchain Defaults ---
  static const int defaultChainId = 80002; // Polygon Amoy Testnet
  static const String defaultNetwork = "polygon";
}