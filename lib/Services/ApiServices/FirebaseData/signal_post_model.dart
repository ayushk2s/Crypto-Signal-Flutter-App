import 'package:cloud_firestore/cloud_firestore.dart';

class CryptoSignalModel {
  final String symbol;
  final double broughtAt;
  final double sl;
  final List<Map<String, dynamic>> targets;
  final DateTime postDate;
  final double capital;
  final int leverage;
  final String side; // New field

  CryptoSignalModel({
    required this.symbol,
    required this.broughtAt,
    required this.sl,
    required this.targets,
    required this.postDate,
    required this.capital,
    required this.leverage,
    required this.side, // Constructor updated
  });

  // Convert Firestore Document to CryptoSignalModel
  factory CryptoSignalModel.fromMap(Map<String, dynamic> map) {
    return CryptoSignalModel(
      symbol: map['symbol'],
      broughtAt: (map['broughtAt'] as num).toDouble(),
      sl: (map['sl'] as num).toDouble(),
      targets: List<Map<String, dynamic>>.from(map['targets']),
      postDate: (map['postDate'] as Timestamp).toDate(),
      capital: (map['capital'] as num).toDouble(),
      leverage: map['leverage'],
      side: map['side'] ?? 'Buy', // Default to 'Buy' if missing
    );
  }

  // Convert CryptoSignalModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'broughtAt': broughtAt,
      'sl': sl,
      'targets': targets,
      'postDate': Timestamp.fromDate(postDate),
      'capital': capital,
      'leverage': leverage,
      'side': side,
    };
  }
}
