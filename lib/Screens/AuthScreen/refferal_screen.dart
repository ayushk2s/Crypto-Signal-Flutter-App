import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto_signal_flutter_app/Screens/BottomNavigation/bottom_navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';

class ReferralCodeScreen extends StatefulWidget {

  const ReferralCodeScreen({super.key});

  @override
  State<ReferralCodeScreen> createState() => _ReferralCodeScreenState();
}

class _ReferralCodeScreenState extends State<ReferralCodeScreen> {
  final TextEditingController _referralController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C5364), Color(0xFF203A43), Color(0xFF0F2027)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Centered Glassmorphism Card
          Center(
            child: GlassmorphicContainer(
              width: size.width * 0.85,
              height: 300,
              borderRadius: 20,
              blur: 15,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white38.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderGradient: LinearGradient(
                colors: [
                  Colors.white24,
                  Colors.white10,
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Got a Referral Code?",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Enter it below and earn bonus tokens!",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _referralController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter 5-digit code",
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      maxLength: 5,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent, Colors.cyanAccent],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: InkWell(
                        onTap: _isSubmitting ? null : _submitReferral,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: _isSubmitting
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            "Apply Code",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade800, Colors.grey.shade600],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: InkWell(
                        onTap: (){
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => BottomNavigation()),
                                (route) => false,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Text(
                            "Skip",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitReferral() async {
    final code = _referralController.text.trim().toUpperCase();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (code.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid 5-character code")),
      );
      return;
    }

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    final currentUserDoc = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    // Fetch the referred user based on referral code
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final querySnapshot = await usersCollection
        .where('myRefferalCode', isEqualTo: code)
        .get();

    if (querySnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Referral code not found.")),
      );
      return;
    }

    final referredUserDoc = querySnapshot.docs.first;
    final referredUserId = referredUserDoc.id;

    // Prevent self-referral
    if (referredUserId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You cannot use your own referral code.")),
      );
      return;
    }

    // Run transaction to update wallet tokens
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final currentUserSnapshot = await transaction.get(currentUserDoc);
      final referredUserSnapshot = await transaction.get(usersCollection.doc(referredUserId));

      final currentTokens = currentUserSnapshot.data()?['walletTokens'] ?? 0;
      final referredTokens = referredUserSnapshot.data()?['walletTokens'] ?? 0;

      transaction.update(currentUserDoc, {
        'walletTokens': currentTokens + 10,
      });

      transaction.update(usersCollection.doc(referredUserId), {
        'walletTokens': referredTokens + 30,
      });
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => BottomNavigation()),
            (route) => false,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Referral applied successfully!")),
    );
  }

}
