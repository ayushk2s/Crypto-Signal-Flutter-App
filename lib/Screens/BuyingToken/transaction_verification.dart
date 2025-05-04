import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class TransactionVerificationScreen extends StatefulWidget {
  @override
  _TransactionVerificationScreenState createState() =>
      _TransactionVerificationScreenState();
}

class _TransactionVerificationScreenState
    extends State<TransactionVerificationScreen> {
  final String walletAddress = '0x10017879402aAdEe9171eA928e6210318e92283a';
  final String bscApiKey = '4WT4G8F72J5GQIC27J7VJZ2IEA6XPFQXFR';
  User? userId = FirebaseAuth.instance.currentUser;
  Timer? _timer;
  int _secondsLeft = 120;
  bool _isVerified = false;
  final TextEditingController _txIdController = TextEditingController();
  bool tapped = false;

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
      }
      setState(() {
        _secondsLeft--;
      });
    });
  }

  Future<void> _verifyTransaction(String txId) async {
    final url =
        'https://api.bscscan.com/api?module=transaction&action=gettxinfo&txhash=$txId&apikey=$bscApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final tx = data['result'];
      print('Transaction tx');
      // Check if transaction exists
      if (tx != null) {
        final tokenSymbol = tx['tokenSymbol'];
        final to = tx['to'].toString().toLowerCase();
        final value = tx['value'];
        final decimals = int.parse(tx['tokenDecimal']);
        final amount = BigInt.parse(value) /
            BigInt.from(10).pow(decimals); // Human-readable token amount

        // Check if transaction is for USDT and to the correct wallet address
        if (tokenSymbol.contains('USDT') &&
            to == walletAddress.toLowerCase() &&
            amount >= 1) {

          // Check if the transaction was made in the last 5 minutes
          final timestamp = int.parse(tx['timeStamp']);
          final transactionTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          final currentTime = DateTime.now();
          final difference = currentTime.difference(transactionTime);

          if (difference.inMinutes <= 5) {
            // Update user's wallet with the amount
            await _updateUserWallet(tokenSymbol, amount.toDouble());
            setState(() => _isVerified = true);
            return;
          } else {
            _showError("Transaction is older than 5 minutes.");
          }
        } else {
          _showError("Transaction does not match the criteria.");
        }
      } else {
        _showError("Transaction not found.");
      }
    } else {
      _showError("Error verifying transaction.");
    }
  }

  void _startVerificationTimer(String txId) {
    Timer.periodic(Duration(seconds: 15), (timer) async {
      if (_secondsLeft <= 0 || _isVerified) {
        timer.cancel();
        tapped = false;
      } else {
        await _verifyTransaction(txId);
      }
    });
  }

  Future<void> _updateUserWallet(String tokenName, double amount) async {
    final docRef =
    FirebaseFirestore.instance.collection('users').doc(userId!.uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data();

      Map<String, dynamic> walletToken = {};
      if (data != null && data.containsKey('walletToken')) {
        walletToken = Map<String, dynamic>.from(data['walletToken']);
      }

      double existingAmount = (walletToken[tokenName] ?? 0).toDouble();
      double updatedAmount = existingAmount + amount;

      walletToken[tokenName] = updatedAmount;

      transaction.update(docRef, {'walletToken': walletToken});
    });
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error", style: TextStyle(color: Colors.black)),
        content: Text(message, style: TextStyle(color: Colors.black)),
        actions: <Widget>[
          TextButton(
            child: Text("OK", style: TextStyle(color: Colors.green)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerified) {
      return Scaffold(
        appBar: AppBar(title: Text("Success"), backgroundColor: Colors.black),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('assets/gift.json', width: 200, repeat: false),
              SizedBox(height: 20),
              Text("Transaction Verified!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Verifying..."),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              tapped ? Lottie.asset('assets/rocket.json', width: 200) : Container(),
              SizedBox(height: 20),
              TweenAnimationBuilder(
                tween: Tween(begin: 120.0, end: _secondsLeft.toDouble()),
                duration: Duration(seconds: 1),
                builder: (context, value, child) {
                  return Text("Time left: ${value.toStringAsFixed(0)} seconds", style: TextStyle(fontSize: 18, color: Colors.black));
                },
              ),
              SizedBox(height: 20),
              Text("Enter Transaction Hash (TXID):", style: TextStyle(fontSize: 16, color: Colors.black)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 5)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _txIdController,
                          decoration: InputDecoration(
                            hintText: "Enter TXID",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.paste, color: Colors.green),
                        onPressed: () async {
                          final clipboardContent = await Clipboard.getData('text/plain');
                          if (clipboardContent?.text != null && clipboardContent!.text!.isNotEmpty) {
                            _txIdController.text = clipboardContent.text!;
                          } else {
                            _showError("No TXID found in clipboard.");
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Where to find TXID: \n\nYou can find the Transaction Hash (TXID) by visiting your transaction on the blockchain explorer (e.g., BscScan for BNB/USDT). Alternatively, you can also find the TXID on the exchange (e.g., Binance, KuCoin) where you made the transfer. It's typically found under the 'Transaction Hash' section of your transaction details.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.verified),
                label: const Text('Verify Transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tapped ? Colors.grey : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if(!tapped){
                    final txId = _txIdController.text.trim();
                    if (txId.isNotEmpty) {
                      setState(() {
                        tapped = true;
                      });
                      _startTimer();  // Start the countdown timer
                      _startVerificationTimer(txId);  // Start the periodic transaction check
                    } else {
                      _showError("Please enter a valid TXID.");
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
