import 'package:crypto_signal_flutter_app/Screens/BuyingToken/transaction_screen.dart';
import 'package:crypto_signal_flutter_app/Services/ApiServices/spot_ticker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int walletTokens = 0;
  int unlockedCount = 0;
  int totalSignals = 0;
  List<Map<String, dynamic>> unlockedSignals = [];
  Map<String, double> currentPrices = {}; // To store current prices of signals

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchTotalSignals();
  }

  Future<void> fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        final List<dynamic> unlockedIds = data['premiumSignalsUnlocked'] ?? [];

        setState(() {
          walletTokens = data['walletTokens'] ?? 0;
          unlockedCount = unlockedIds.length;
        });

        fetchUnlockedSignalDetails(List<String>.from(unlockedIds));
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  Future<void> fetchTotalSignals() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('CryptoSignals').get();
      setState(() {
        totalSignals = snapshot.docs.length;
      });
    } catch (e) {
      debugPrint("Error fetching total signals: $e");
    }
  }

  Future<void> fetchUnlockedSignalDetails(List<String> ids) async {
    if (ids.isEmpty) return;

    try {
      final futures = ids.map((id) => FirebaseFirestore.instance.collection('CryptoSignals').doc(id).get());
      final docs = await Future.wait(futures);

      final signals = docs
          .where((doc) => doc.exists)
          .map((doc) {
        final data = doc.data();
        if (data != null) {
          return {...data, 'id': doc.id};
        }
        return null;
      })
          .whereType<Map<String, dynamic>>()
          .toList();

      setState(() {
        unlockedSignals = signals;
      });

      // Fetch current prices for all unlocked signals
      fetchCurrentPrices();
    } catch (e) {
      debugPrint("Error fetching unlocked signal details: $e");
    }
  }

  Future<void> fetchCurrentPrices() async {
    final spotTicker = SpotTicker();
    final symbols = unlockedSignals.map((signal) => signal['symbol'] as String).toList();
    final allData = await spotTicker.fetchAllTickers();

    if (allData != null) {
      final prices = spotTicker.getSymbolStats(allData, symbols);

      Map<String, double> pricesMap = {};
      for (var item in prices) {
        final symbol = item['symbol'];
        final price = double.tryParse(item['lastPrice'].toString()) ?? 0.0;
        pricesMap[symbol] = price;
      }


      if (!mounted) return;

      setState(() {
        currentPrices = pricesMap;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet & Access')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAnimatedCard(
              title: "💰 Wallet Tokens",
              value: walletTokens,
              color: Colors.teal,
            ),
            const SizedBox(height: 20),
            // _buildAnimatedCard(
            //   title: "🔓 Premium Signals Unlocked",
            //   value: unlockedCount,
            //   subValue: "/ $totalSignals",
            //   color: Colors.deepPurple,
            // ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => CryptoTransactionScreen()));

              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text("Buy Tokens"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.green,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 30),
            if (unlockedSignals.isNotEmpty)
              ...unlockedSignals.map((signal) => _buildSignalCard(signal)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({
    required String title,
    required int value,
    String? subValue,
    required Color color,
  }) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(seconds: 1),
      builder: (context, val, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "$val",
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                if (subValue != null)
                  Text(" $subValue", style: const TextStyle(color: Colors.white60, fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalCard(Map<String, dynamic> data) {
    final symbol = data['symbol'] ?? '';
    final timestamp = data['timestamp']?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat.yMMMd().format(timestamp);
    final boughtAt = (data['broughtAt'] ?? 0).toDouble();
    final side = data['side'] ?? 'Buy';
    final leverage = (data['leverage'] ?? 1);
    final capital = data['capital'] ?? 'N/A';
    final isSL = data['isSL'] ?? false;
    final currentPrice = currentPrices[symbol] ?? boughtAt;
    final gain = (currentPrice - boughtAt) * (side == 'Buy' ? 1 : -1);
    final sl = (data['sl'] ?? 0).toDouble();

    List<double> targets = [];
    if (data['targets'] != null) {
      targets = List.from(data['targets']).map<double>((e) => (e['target'] ?? 0).toDouble()).toList();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$symbol', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Open on $formattedDate', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            if (!isSL) _row('Current Price', currentPrice.toStringAsFixed(5), gain, side),
            const SizedBox(height: 4),
            FittedBox(
              child: Row(
                children: [
                  _chip('$side: $boughtAt', side == 'Buy' ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  _chip('Capital: $capital', Colors.brown),
                  const SizedBox(width: 8),
                  _chip('Leverage: ${leverage}x', Colors.deepPurple),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (isSL)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.red[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('SL HIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            else
              for (int i = 0; i < targets.length; i++)
                _targetRow(i + 1, targets[i], boughtAt, currentPrice, leverage, side),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('STOPLOSS: $sl', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, double gain, String side) {
    return FittedBox(
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: side == 'Buy' ? Colors.green : Colors.red)),
          const SizedBox(width: 10),
          Text("(P&L: ${gain.toStringAsFixed(2)}) Units", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _targetRow(int index, double target, double boughtAt, double currentPrice, int leverage, String side) {
    final pnl = (target - boughtAt) * leverage * (side == 'Buy' ? 1 : -1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("🎯 Target $index: $target", style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Text("(P&L: ${pnl.toStringAsFixed(2)}) Units", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}
