import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/utils/validators.dart';

/// Standard: EIP-681 (Ethereum Provider Request URI)
/// Format: ethereum:0xAddress@chainId/transfer?address=0xRecipient&uint256=value
class Eip681Parser {
  static TransactionModel? parse(String uri) {
    try {
      if (!uri.startsWith('ethereum:')) return null;

      // Remove prefix
      final cleanUri = uri.replaceFirst('ethereum:', '');
      
      // Split path and parameters
      final parts = cleanUri.split('?');
      
      // Extract target address and chainId from path (e.g., 0xAddress@137)
      final pathSegments = parts[0].split('@');
      final targetPathAddress = pathSegments[0];
      
      // Default to Polygon (137) as per BlockPay architecture
      int chainId = 137;
      if (pathSegments.length > 1) {
        chainId = int.tryParse(pathSegments[1]) ?? 137;
      }

      String recipient = targetPathAddress;
      String rawAmountWei = "0"; 
      String tokenSymbol = 'POL'; // Default for BlockPay on Polygon

      // Parse Query Parameters
      if (parts.length > 1) {
        final params = Uri.splitQueryString(parts[1]);
        
        // ERC20/Token transfer standard: the 'address' param is the true recipient
        if (params.containsKey('address')) {
          recipient = params['address']!;
        }
        
        // 'uint256' is the amount in Wei (standard BigInt)
        if (params.containsKey('uint256')) {
          rawAmountWei = params['uint256']!;
        }

        if (params.containsKey('symbol')) {
          tokenSymbol = params['symbol']!;
        }
      }

      // Security Check: Validate the extracted recipient address
      if (Validators.validateWalletAddress(recipient) != null) {
        return null; 
      }

      // Returns a model fully compatible with TransactionModel and Backend Schema
      return TransactionModel(
        type: 'send', 
        amount: rawAmountWei, 
        fromAddress: '', // To be populated from UserModel.walletAddress in UI
        toAddress: recipient,
        chainId: chainId,
        network: _mapChainIdToNetwork(chainId),
        status: 'pending',
        token: TokenInfo(
          symbol: tokenSymbol,
          decimals: 18, 
        ),
        initiatedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Maps chainId to the specific string Network expected by the Backend Validator
  static String _mapChainIdToNetwork(int chainId) {
    switch (chainId) {
      case 137:
      case 80001:
      case 80002:
        return 'polygon';
      case 1:
        return 'ethereum';
      case 8453:
        return 'base';
      case 10:
        return 'optimism';
      case 42161:
        return 'arbitrum';
      default:
        return 'polygon';
    }
  }
}