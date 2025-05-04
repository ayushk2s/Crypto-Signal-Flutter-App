import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';
class PostCryptoSignalScreen extends StatefulWidget {
  @override
  _PostCryptoSignalScreenState createState() => _PostCryptoSignalScreenState();
}

class _PostCryptoSignalScreenState extends State<PostCryptoSignalScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _slController = TextEditingController();
  final TextEditingController _targetsController = TextEditingController();
  final TextEditingController _capitalController = TextEditingController();
  final TextEditingController _leverageController = TextEditingController();

  String _selectedSide = 'Buy';
  String _selectedAccessType = 'Free';

  void _submitSignal() async {
    if (_formKey.currentState!.validate()) {
      final rawTargets = _targetsController.text
          .split(',')
          .map((e) => double.tryParse(e.trim()))
          .where((e) => e != null)
          .toList();

      final signal = {
        'symbol': _symbolController.text.toUpperCase(),
        'broughtAt': double.parse(_entryController.text),
        'sl': double.parse(_slController.text),
        'targets': rawTargets
            .map((e) => {'target': e, 'isComplete': false})
            .toList(),
        'capital': double.parse(_capitalController.text),
        'leverage': int.parse(_leverageController.text),
        'side': _selectedSide,
        'postDate': Timestamp.now(),
        'isSL' : false,
        'isPremium': _selectedAccessType == 'Premium',
        'premiumAccessedBy': [],
        'profitLossImageUrl': ''
      };

      await FirebaseFirestore.instance.collection('CryptoSignals').add(signal);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signal posted successfully!')),
      );

      _formKey.currentState!.reset();
      _symbolController.clear();
      _entryController.clear();
      _slController.clear();
      _targetsController.clear();
      _capitalController.clear();
      _leverageController.clear();
      setState(() => _selectedSide = 'Buy');
      await _sendSignalNotificationToAllUsers(signal);
    }
  }

  Future<void> _sendSignalNotificationToAllUsers(Map<String, dynamic> signal) async {
    try {
      // Get all user tokens from Firestore
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final List<String> tokens = [];

      for (var doc in snapshot.docs) {
        final token = doc['fcmToken'];
        if (token != null && token.toString().isNotEmpty) {
          tokens.add(token);
        }
      }

      final String? accessToken = await getAccessToken();
    print('getting token $accessToken');
      for (String token in tokens) {
        final body = {
          "message": {
            "token": token,
            "notification": {
              "title": "📈 New Trade Signal!",
              "body": "${signal['symbol']} | ${signal['side']} at ${signal['broughtAt']}"
              // "body" : "hii"
            },
            "android": {
              "notification": {
                "channel_id": "crypto_signal_flutter_app",
                "sound": "default"
              }
            },
            "data": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
              "screen": "signalPage"
            }
          }
        };

        final response = await http.post(
          Uri.parse('https://fcm.googleapis.com/v1/projects/crypto-signal-4e67d/messages:send'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        );

        print("Notification sent to $token: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print('Error sending signal notifications: $e');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final String serviceAccountJson = await rootBundle.loadString('add yours messaging json');
      print('serviceAccountJson $serviceAccountJson');
      final credentials = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJson));

      final client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      final accessToken = client.credentials.accessToken.data;
      print("Access Token: $accessToken");
      client.close();
      return accessToken;
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post Crypto Signal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_symbolController, 'Symbol (e.g. BTCUSDT)', TextInputType.text),
              _buildTextField(_entryController, 'Entry Price', TextInputType.number),
              _buildTextField(_slController, 'Stop Loss', TextInputType.number),
              _buildTextField(_targetsController, 'Targets (comma-separated)', TextInputType.text),
              _buildTextField(_capitalController, 'Capital', TextInputType.number),
              _buildTextField(_leverageController, 'Leverage', TextInputType.number),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSide,
                decoration: InputDecoration(
                  labelText: 'Side',
                  border: OutlineInputBorder(),
                ),
                items: ['Buy', 'Short'].map((String side) {
                  return DropdownMenuItem<String>(
                    value: side,
                    child: Text(side),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSide = value!;
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAccessType,
                decoration: InputDecoration(
                  labelText: 'Access Type',
                  border: OutlineInputBorder(),
                ),
                items: ['Free', 'Premium'].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAccessType = value!;
                  });
                },
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitSignal,
                // onPressed: _sendSignalNotificationToAllUsers,
                // onPressed: getAccessToken,
                child: Text('Post Signal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: label,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required';
          return null;
        },
      ),
    );
  }
}
