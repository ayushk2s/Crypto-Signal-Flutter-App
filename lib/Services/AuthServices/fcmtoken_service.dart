import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMTokenService{
  Future<void> updateTokenIfNeeded(String userId) async {
    String? newToken = await FirebaseMessaging.instance.getToken();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? oldToken = prefs.getString('fcmToken');

    if (newToken != null && newToken != oldToken) {
      // Update in Firestore or your database
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': newToken,
      });

      // Store the latest token locally
      await prefs.setString('fcmToken', newToken);
    }
  }

}