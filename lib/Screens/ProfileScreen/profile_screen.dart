import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto_signal_flutter_app/Screens/AuthScreen/google_auth_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text('My Profile'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : userData == null
          ? Center(child: Text('No user data found.'))
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final name = userData!['name'] ?? "No Name";
    final email = userData!['email'] ?? "No Email";
    final photoUrl = userData!['profilePhotoUrl'] ?? "https://i.pravatar.cc/150?img=47";
    final createdAt = (userData!['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('MMMM dd, yyyy').format(createdAt);
    final referralCode = userData!['myRefferalCode'] ?? "ABC123";
    final appWebsiteUrl = "https://ayushk2s.github.io/Crypto-Signal-Website/"; // customize

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            SizedBox(height: 30),
            Hero(
              tag: 'profile-photo',
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(photoUrl),
              ),
            ),
            SizedBox(height: 20),
            Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(email, style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 20),

            _buildAnimatedCard(300, _infoTile(Icons.calendar_today, "Joined", formattedDate)),

            // Referral section
            _buildAnimatedCard(
              500,
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.card_giftcard, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "Earn with Referral",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Share the app link when someone download and use your refferal code you will get 30 free points!",
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 10),

                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(referralCode, style: TextStyle(fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: referralCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Referral code copied!")),
                              );
                            },
                            child: Icon(Icons.copy, color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

                    // Website link box
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              appWebsiteUrl,
                              style: TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: appWebsiteUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("App link copied!")),
                              );
                            },
                            child: Icon(Icons.copy, color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _buildAnimatedCard(
              700,
              GestureDetector(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => GoogleAuthScreen()),
                        (route) => false,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(int delayMilliseconds, Widget child) {
    return FutureBuilder(
      future: Future.delayed(Duration(milliseconds: delayMilliseconds)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox.shrink(); // Wait until the delay is over
        }

        return TweenAnimationBuilder<Offset>(
          tween: Tween(begin: Offset(0, 0.2), end: Offset.zero),
          duration: Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, offset, _) {
            return Transform.translate(
              offset: Offset(0, offset.dy * 50),
              child: AnimatedOpacity(
                opacity: offset == Offset.zero ? 1 : 0,
                duration: Duration(milliseconds: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 28),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}
