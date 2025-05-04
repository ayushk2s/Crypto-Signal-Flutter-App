import 'dart:math';

import 'package:crypto_signal_flutter_app/Services/AuthServices/fcmtoken_service.dart';
import 'package:crypto_signal_flutter_app/Services/AuthServices/user_model.dart';
import 'package:crypto_signal_flutter_app/Screens/BottomNavigation/bottom_navigation.dart';
import 'package:crypto_signal_flutter_app/Screens/AuthScreen/refferal_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthScreen extends StatefulWidget {
  const GoogleAuthScreen({super.key});
  @override
  State<GoogleAuthScreen> createState() => _GoogleAuthScreenState();
}

class _GoogleAuthScreenState extends State<GoogleAuthScreen> {
  bool isLoading = false;

  Future<String> generateUniqueReferralCode() async {
    String generateCode() {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final rand = Random();
      return List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
    }

    String code = generateCode();
    bool exists = true;

    while (exists) {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('myReferralCode', isEqualTo: code)
          .get();

      if (query.docs.isEmpty) {
        exists = false;
      } else {
        code = generateCode(); // Try a new code
      }
    }

    return code;
  }


  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        String? token = await FirebaseMessaging.instance.getToken();
        FCMTokenService fcmTokenService = FCMTokenService();
        fcmTokenService.updateTokenIfNeeded(user.uid);

        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          final referralCode = await generateUniqueReferralCode(); // <--- Add this line

          final userModel = UserModel(
            uid: user.uid,
            name: user.displayName ?? '',
            email: user.email ?? '',
            createdAt: DateTime.now(),
            phone: user.phoneNumber ?? '',
            fcmToken: token,
            profilePhotoUrl: user.photoURL ?? '',
            premiumSignalsUnlocked: [],
            walletTokens: 50,
            myRefferalCode: referralCode,
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => ReferralCodeScreen()),
                (route) => false,
          );
      } else {
          // Update only info that might change (name, photo, etc), not tokens
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'profilePhotoUrl': user.photoURL ?? '',
            'fcmToken': token,
          });
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => BottomNavigation()),
                (route) => false,
          );
        }

        // if (!mounted) return;

      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      print('Error while google sign-in: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: user != null
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(user.photoURL ?? ''),
                radius: 50,
              ),
              const SizedBox(height: 16),
              Text(
                "Welcome,",
                style: TextStyle(fontSize: 20, color: Colors.grey[700]),
              ),
              Text(
                user.displayName ?? '',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Sign Out"),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  await GoogleSignIn().signOut();
                  setState(() {});
                },
              ),
            ],
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/login.json',
                width: 250,
                repeat: true,
              ),
              const SizedBox(height: 20),
              const Text(
                "Welcome to Crypto Signals",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Sign in to explore premium signals and analytics",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                icon: Image.asset(
                  'assets/google.png',
                  height: 24,
                ),
                label: const Text("Sign in with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shadowColor: Colors.grey,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onPressed: signInWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
