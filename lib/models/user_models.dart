

/// Matches backend/src/models/user.model.js
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final BiometricData biometric;
  final bool isActive;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? profilePicture;
  final String kycStatus; // pending, verified, rejected, not_submitted
  final UserPreferences preferences;
  final UserAddress? address;
  final BankDetails? bankDetails;
  final DateTime? createdAt;
  final double riskScore;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.biometric,
    this.isActive = true,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.profilePicture,
    this.kycStatus = 'not_submitted',
    required this.preferences,
    this.address,
    this.bankDetails,
    this.createdAt,
    this.riskScore = 0.0,
  });

  // --- UI Getters ---


  String get fullName => "$firstName $lastName";


  String get formattedPhone => "+91 $phoneNumber";

  /// Logic from userSchema.methods.requiresBiometricVerification
  bool get needsBiometricRefresh {
    if (!biometric.isVerified) return true;
    if (biometric.lastVerified == null) return true;
    
    final difference = DateTime.now().difference(biometric.lastVerified!);
    return difference.inDays > 30;
  }

  // --- Serialization ---

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      biometric: BiometricData.fromJson(json['biometricData'] ?? {}),
      isActive: json['isActive'] ?? true,
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      profilePicture: json['profilePicture'],
      kycStatus: json['kycStatus'] ?? 'not_submitted',
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      address: json['address'] != null ? UserAddress.fromJson(json['address']) : null,
      bankDetails: json['bankDetails'] != null ? BankDetails.fromJson(json['bankDetails']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'preferences': preferences.toJson(),
      'address': address?.toJson(),
    };
  }
}

class BiometricData {
  final bool isVerified;
  final DateTime? lastVerified;

  BiometricData({this.isVerified = false, this.lastVerified});

  factory BiometricData.fromJson(Map<String, dynamic> json) {
    return BiometricData(
      isVerified: json['isVerified'] ?? false,
      lastVerified: json['lastVerified'] != null 
          ? DateTime.parse(json['lastVerified']) 
          : null,
    );
  }
}

class UserPreferences {
  final String language;
  final String currency;
  final Map<String, bool> notifications;

  UserPreferences({
    this.language = 'english',
    this.currency = 'INR',
    this.notifications = const {'email': true, 'sms': true},
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      language: json['language'] ?? 'english',
      currency: json['currency'] ?? 'INR',
      notifications: Map<String, bool>.from(json['notifications'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'language': language,
    'currency': currency,
    'notifications': notifications,
  };
}

class UserAddress {
  final String? city;
  final String? state;
  final String? pincode;
  final String country;

  UserAddress({this.city, this.state, this.pincode, this.country = 'India'});

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      country: json['country'] ?? 'India',
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'state': state,
    'pincode': pincode,
    'country': country,
  };
}

class BankDetails {
  final String? bankName;
  final String? upiId;
  final String? ifscCode;

  BankDetails({this.bankName, this.upiId, this.ifscCode});

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bankName'],
      upiId: json['upiId'],
      ifscCode: json['ifscCode'],
    );
  }
}