import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String? profilePhotoUrl;
  final String? fcmToken;
  final DateTime createdAt;
  final String myRefferalCode;
  final List<String> premiumSignalsUnlocked;
  final int walletTokens;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.fcmToken,
    this.phone,
    this.profilePhotoUrl,
    required this.createdAt,
    required this.premiumSignalsUnlocked,
    required this.walletTokens,
    required this.myRefferalCode
  });

  // Convert Firestore Document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      fcmToken: map['fcmToken'],
      profilePhotoUrl: map['profilePhotoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      premiumSignalsUnlocked: List<String>.from(map['premiumSignalsUnlocked'] ?? []),
      walletTokens: map['walletTokens'] ?? 0,
      myRefferalCode: map['myRefferalCode']
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'fcmToken': fcmToken,
      'profilePhotoUrl': profilePhotoUrl,
      'createdAt': createdAt,
      'premiumSignalsUnlocked': premiumSignalsUnlocked,
      'walletTokens': walletTokens,
      'myRefferalCode' : myRefferalCode
    };
  }
}
