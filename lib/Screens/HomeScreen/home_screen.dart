import 'dart:async';
import 'package:crypto_signal_flutter_app/Animation/homeListAnimation.dart';
import 'package:crypto_signal_flutter_app/Screens/HomeScreen/crypto_price_model.dart';
import 'package:crypto_signal_flutter_app/Screens/HomeScreen/signal_data_show.dart';
import 'package:crypto_signal_flutter_app/Screens/PostCryptoSignalScreen/post_crypto_signal_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:crypto_signal_flutter_app/Services/ApiServices/spot_ticker.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  List<CryptoData> _cryptos = [];
  User? userId = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchData();
    });
    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('User tapped on notification');
    });

  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final spotTicker = SpotTicker();

    // Desired symbols to track
    List<String> mySymbols = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'XRPUSDT', 'BNBUSDT'];

    // Fetch all data from MEXC
    final allData = await spotTicker.fetchAllTickers();

    if (allData != null) {
      final result = spotTicker.getSymbolStats(allData, mySymbols);

      // Convert to CryptoData list
      List<CryptoData> updatedList = result.map((item) {
        return CryptoData(
          priceChange: double.tryParse(item['priceChange'].toString()) ?? 0.0,
          name: item['symbol'],
          price: double.tryParse(item['lastPrice'].toString()) ?? 0.0,
          volume: double.tryParse(item['newVolume'].toString()) ?? 0.0,
          change: double.tryParse(item['priceChangePercent'].toString()) ?? 0.0,
        );
      }).toList();

      // Update UI
      if (!mounted) return;

      setState(() {
        _cryptos = updatedList;
      });
    } else {
      print("Failed to fetch data.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: InkWell(
          onLongPress: () {
            User? user = FirebaseAuth.instance.currentUser;
            if(user!.email == 'ayushpandey85986@gmail.com' || user.email == 'rajveersingh809024@gmail.com') {
              Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => PostCryptoSignalScreen()));
            }
          },
          child: const Text('Crypto Tracker'),
        ),
        backgroundColor: Colors.white,
      ),
      body: _cryptos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            SlideAnimation(
              delay: 4,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _cryptos.map((crypto) {
                    return Container(
                      width: 160.0,
                      margin: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4.0,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crypto.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: [
                                Text('\$${crypto.price.toStringAsFixed(2)}'),
                                Text(
                                  ' ${crypto.change.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: crypto.change >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                'Future Signals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            CryptoSignalsList(cryptos: _cryptos, userId: userId!.uid,),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
