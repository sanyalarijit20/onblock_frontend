class Validators {
  /// Ensures the name is not empty and has a reasonable length
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name is too short';
    }
    return null;
  }

  /// Standard Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Ensures 10-digit Indian Mobile Number
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  /// Ensures 12-digit Aadhaar Number
  static String? validateAadhaar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aadhaar number is required';
    }
    final aadhaarRegex = RegExp(r'^[0-9]{12}$');
    if (!aadhaarRegex.hasMatch(value)) {
      return 'Enter a valid 12-digit Aadhaar number';
    }
    return null;
  }

  /// Ensures Passkey is at least 6 characters
  static String? validatePasskey(String? value) {
    if (value == null || value.isEmpty) {
      return 'Passkey is required';
    }
    if (value.length < 6) {
      return 'Passkey must be at least 6 characters';
    }
    return null;
  }

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