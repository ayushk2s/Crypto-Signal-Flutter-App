import 'package:crypto_signal_flutter_app/Screens/AuthScreen/google_auth_screen.dart';
import 'package:crypto_signal_flutter_app/Screens/BottomNavigation/bottom_navigation.dart';
import 'package:crypto_signal_flutter_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures plugins are ready
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

class MyApp extends StatelessWidget {
   MyApp({super.key});

  // This widget is the root of your application.
  User? currentUser = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: currentUser == null ? GoogleAuthScreen() : BottomNavigation(),
      // home: CryptoSignalsList(),
    );
  }
}

