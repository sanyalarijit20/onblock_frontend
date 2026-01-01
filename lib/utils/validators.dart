class Validators {
  /// Ensures the address is a valid 42-character Ethereum address
  static String? validateWalletAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    final ethAddressRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    if (!ethAddressRegex.hasMatch(value)) {
      return 'Invalid wallet address format';
    }
    
    return null;
  }

  /// Ensures payment amount is positive and numeric
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Enter a valid positive amount';
    }
    
    return null;
  }
}