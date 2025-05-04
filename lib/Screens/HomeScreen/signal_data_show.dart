import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto_signal_flutter_app/Screens/HomeScreen/crypto_price_model.dart';
import 'package:crypto_signal_flutter_app/Screens/HomeScreen/signal_unlocker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CryptoSignalsList extends StatelessWidget {
  List<CryptoData> cryptos = [];
  String userId;
  CryptoSignalsList({super.key, required this.cryptos, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('CryptoSignals')
          .orderBy('postDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final signals = snapshot.data!.docs;

        return Column(
          children: signals.map((signal) {
            return CryptoSignalCard(
              data: signal.data() as Map<String, dynamic>,
              cryptosPrice: cryptos,
              documentId: signal.id,
              userId: userId,
            );
          }).toList(),
        );
      },
    );
  }
}

class CryptoSignalCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<CryptoData> cryptosPrice;
  final String documentId;
  final String userId;
  CryptoSignalCard({
    super.key,
    required this.data,
    required this.cryptosPrice,
    required this.documentId,
    required this.userId
  });

  ///Is Premium Locked or Unlocked
  bool get isLocked {
    return data['isPremium'] == true &&
        !(data['premiumAccessedBy'] as List<dynamic>).contains(userId);
  }

  @override
  Widget build(BuildContext context) {
    double boughtAt = data['broughtAt'] ?? 0.0;
    final sl = data['sl'] ?? 0.0;
    final capital = data['capital']?.toString() ?? '0%';
    final targets = List<Map<String, dynamic>>.from(data['targets']);
    final symbol = (data['symbol'] as String).trim();
    final leverage = data['leverage'] ?? 1;
    final side = data['side'] ?? 'Buy';
    final isSL = data['isSL'] ?? false;
    final stop_loss_percent = (((boughtAt - sl) / boughtAt) * 100) * leverage;
    final formatted_stop_loss_percent = stop_loss_percent.toStringAsFixed(2);


    double currentPrice = 0.0;
    if (symbol == 'BTCUSDT') {
      currentPrice = cryptosPrice[0].price ?? 0.0;
    } else if (symbol == 'ETHUSDT') {
      currentPrice = cryptosPrice[1].price ?? 0.0;
    }

    final postDate = (data['postDate'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd/MM/yyyy').format(postDate);

    double gain = 0.0;
    if (!isSL) {
      if (side == 'Buy') {
        gain = ((currentPrice - boughtAt) / boughtAt) * 100 * leverage;
      } else if (side == 'Short') {
        gain = ((boughtAt - currentPrice) / boughtAt) * 100 * leverage;
      }

      final slPercent = side == 'Buy'
          ? ((boughtAt - sl) / boughtAt) * 100 * leverage
          : ((sl - boughtAt) / boughtAt) * 100 * leverage;

      if ((side == 'Buy' &&
              currentPrice < boughtAt &&
              gain.abs() > slPercent) ||
          (side == 'Short' &&
              currentPrice > boughtAt &&
              gain.abs() > slPercent)) {
        gain = -slPercent;
      }
    }

    return Stack(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$symbol',
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Open on $formattedDate',
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                if (!isSL)
                  _row(
                      'Current Price', currentPrice.toStringAsFixed(5), gain, side),
                const SizedBox(height: 4),
                FittedBox(
                  child: Row(
                    children: [
                      _chip('$side: $boughtAt',
                          side == 'Buy' ? Colors.green : Colors.red),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.red[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'SL HIT',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  for (int i = 0; i < targets.length; i++)
                    _targetRow(i + 1, targets[i], boughtAt, currentPrice, leverage,
                        side, i, isSL, sl),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[400],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('STOPLOSS: $sl',
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        if (isLocked)
          Positioned.fill(
            child: InkWell(
              onTap: () async {
                  await SignalUnlocker.unlockSignal(
                    context: context,
                    signalDocId: documentId,
                  );
              },

              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    alignment: Alignment.center,
                    child: Text(
                      "Unlock Premium",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value, double percent, String side) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          '$value   ${percent.toStringAsFixed(2)}%',
          style: TextStyle(
            fontSize: 16,
            color: percent >= 0
                ? (side == 'Buy' ? Colors.green : Colors.red)
                : (side == 'Buy' ? Colors.green : Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color)),
    );
  }

  Widget _targetRow(
      int targetNum,
      Map<String, dynamic> targetData,
      double entry,
      double currentPrice,
      int leverage,
      String side,
      int index,
      bool isSL,
      double sl) {
    final target = (targetData['target'] as num).toDouble();
    final isCompleteManually = targetData['isComplete'] as bool;

    final percent = side == 'Buy'
        ? ((target - entry) / entry) * 100 * leverage
        : ((entry - target) / entry) * 100 * leverage;

    final isComplete = isCompleteManually ||
        (side == 'Buy' ? currentPrice >= target : currentPrice <= target);

    if (!isSL && !isCompleteManually && isComplete) {
      _updateTargetCompleteInFirestore(index);
    } else if (!isSL) {
      final slHit = (side == 'Buy' && currentPrice <= sl) ||
          (side == 'Short' && currentPrice >= sl);
      if (slHit) {
        _updateIsSLInFirestore();
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Text('Target 0$targetNum: $target',
              style: const TextStyle(fontSize: 16)),
          const Spacer(),
          Text('${percent.toStringAsFixed(0)}%',
              style:
                  TextStyle(color: percent >= 0 ? Colors.green : Colors.red)),
          const SizedBox(width: 8),
          Icon(
            isComplete ? Icons.check_box : Icons.check_box_outline_blank,
            color: isComplete ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Future<void> _updateTargetCompleteInFirestore(int index) async {
    if (data['isSL'] == true) return;

    final docRef =
        FirebaseFirestore.instance.collection('CryptoSignals').doc(documentId);
    final targetsList = List<Map<String, dynamic>>.from(data['targets']);

    if (targetsList[index]['isComplete'] == true) return;

    targetsList[index]['isComplete'] = true;

    try {
      await docRef.update({'targets': targetsList});
    } catch (e) {
      debugPrint('Error updating target $index in Firestore: $e');
    }
  }

  Future<void> _updateIsSLInFirestore() async {
    if (data['targets'][0]['isComplete'] == true) return;

    final docRef = FirebaseFirestore.instance.collection('CryptoSignals').doc(documentId);

    try {
      // First update SL status
      await docRef.update({'isSL': true});

      // Fetch latest document data
      final docSnapshot = await docRef.get();
      final signalData = docSnapshot.data();

      if (signalData != null && signalData['isPremium'] == true) {
        final List<dynamic> accessedBy = signalData['premiumAccessedBy'] ?? [];

        for (var userId in accessedBy) {
          final userRef = FirebaseFirestore.instance.collection('Users').doc(userId);

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final userSnapshot = await transaction.get(userRef);
            final currentWallet = userSnapshot.data()?['wallet'] ?? 0;

            transaction.update(userRef, {
              'walletTokens': currentWallet + 20,
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating SL status or rewarding users: $e');
    }
  }
}
