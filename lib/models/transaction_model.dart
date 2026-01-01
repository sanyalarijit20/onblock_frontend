import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Matches backend/src/models/transaction.model.js
class TransactionModel {
  final String? id;
  final String type; // send, receive, swap, deposit, withdrawal
  final String amount; // BigInt/Wei string for precision
  final TokenInfo token;
  final String fromAddress;
  final String toAddress;
  final String? txHash;
  final String? userOpHash;
  final String network;
  final int chainId;
  final String status; // pending, submitted, confirmed, failed, rejected
  final FraudAnalysis? fraudAnalysis;
  final bool biometricVerified;
  final bool facialVerified;
  final TransactionMetadata? metadata;
  final DateTime? initiatedAt;
  final DateTime? confirmedAt;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.token,
    required this.fromAddress,
    required this.toAddress,
    this.txHash,
    this.userOpHash,
    this.network = 'polygon',
    required this.chainId,
    this.status = 'pending',
    this.fraudAnalysis,
    this.biometricVerified = false,
    this.facialVerified = false,
    this.metadata,
    this.initiatedAt,
    this.confirmedAt,
  });

  // --- UI Getters ---

  /// Formats the raw Wei string into a decimal for the UI.
  String get formattedAmount {
    try {
      final double val = double.parse(amount) / BigInt.from(10).pow(token.decimals).toDouble();
      return NumberFormat.decimalPattern().format(val);
    } catch (e) {
      return "0.00";
    }
  }

  /// Displays amount with symbol (e.g., "1.50 POL")
  String get amountWithSymbol => "$formattedAmount ${token.symbol}";

  /// Formats the date for the transaction history list
  String get readableDate {
    if (initiatedAt == null) return "Processing...";
    return DateFormat('MMM d, h:mm a').format(initiatedAt!);
  }

  /// Color coding for the status tags on the Dashboard
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.greenAccent;
      case 'pending':
      case 'submitted': return Colors.orangeAccent;
      case 'failed':
      case 'rejected': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  // --- Serialization ---

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? json['_id'],
      type: json['type'] ?? 'send',
      amount: json['amount']?.toString() ?? '0',
      token: TokenInfo.fromJson(json['token'] ?? {}),
      fromAddress: json['from'] ?? '',
      toAddress: json['to'] ?? '',
      txHash: json['txHash'],
      userOpHash: json['userOpHash'],
      network: json['network'] ?? 'polygon',
      chainId: json['chainId'] is int 
          ? json['chainId'] 
          : int.tryParse(json['chainId']?.toString() ?? '137') ?? 137,
      status: json['status'] ?? 'pending',
      fraudAnalysis: json['fraudAnalysis'] != null 
          ? FraudAnalysis.fromJson(json['fraudAnalysis']) 
          : null,
      biometricVerified: json['biometricVerified'] ?? false,
      facialVerified: json['facialVerified'] ?? false,
      metadata: json['metadata'] != null 
          ? TransactionMetadata.fromJson(json['metadata']) 
          : null,
      initiatedAt: json['initiatedAt'] != null 
          ? DateTime.parse(json['initiatedAt']) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null),
      confirmedAt: json['confirmedAt'] != null 
          ? DateTime.parse(json['confirmedAt']) 
          : null,
    );
  }

  /// Payload for POST /api/v1/transaction/send
  Map<String, dynamic> toSendPayload({
    required String biometricData,
    required String facialData,
  }) {
    return {
      'to': toAddress,
      'amount': amount,
      'token': token.toJson(),
      'network': network,
      'biometricData': biometricData,
      'facialData': facialData,
      'metadata': metadata?.toJson(),
    };
  }
}

class TokenInfo {
  final String symbol;
  final String? address;
  final int decimals;

  TokenInfo({required this.symbol, this.address, this.decimals = 18});

  factory TokenInfo.fromJson(Map<String, dynamic> json) {
    return TokenInfo(
      symbol: json['symbol'] ?? 'POL',
      address: json['address'],
      decimals: json['decimals'] ?? 18,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'address': address,
    'decimals': decimals,
  };
}

class FraudAnalysis {
  final double? riskScore;
  final bool isBlocked;

  FraudAnalysis({this.riskScore, this.isBlocked = false});

  factory FraudAnalysis.fromJson(Map<String, dynamic> json) {
    return FraudAnalysis(
      riskScore: (json['riskScore'] as num?)?.toDouble(),
      isBlocked: json['isBlocked'] ?? false,
    );
  }
}

class TransactionMetadata {
  final String? description;
  final String? category;

  TransactionMetadata({this.description, this.category});

  factory TransactionMetadata.fromJson(Map<String, dynamic> json) {
    return TransactionMetadata(
      description: json['description'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'category': category,
  };
}