import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignalUnlocker {
  static Future<void> unlockSignal({
    required BuildContext context,
    required String signalDocId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    final shouldUnlock = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Unlock Premium Signal"),
        content: const Text("Do you want to unlock this premium signal for 20 tokens?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Unlock")),
        ],
      ),
    );

    if (shouldUnlock != true) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final signalRef = FirebaseFirestore.instance.collection('CryptoSignals').doc(signalDocId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final signalSnapshot = await transaction.get(signalRef);

        final userData = userSnapshot.data();
        final signalData = signalSnapshot.data();

        if (userData == null || signalData == null) {
          throw Exception("User or Signal data not found");
        }

        int walletTokens = userData['walletTokens'] ?? 0;
        List<dynamic> unlockedSignals = List.from(userData['premiumSignalsUnlocked'] ?? []);
        List<dynamic> premiumAccessedBy = List.from(signalData['premiumAccessedBy'] ?? []);

        if (walletTokens < 20) {
          throw Exception("Not enough tokens");
        }

        if (unlockedSignals.contains(signalDocId)) {
          throw Exception("Signal already unlocked");
        }

        walletTokens -= 20;
        unlockedSignals.add(signalDocId);
        premiumAccessedBy.add(uid);

        transaction.update(userRef, {
          'walletTokens': walletTokens,
          'premiumSignalsUnlocked': unlockedSignals,
        });

        transaction.update(signalRef, {
          'premiumAccessedBy': premiumAccessedBy,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signal unlocked successfully ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to unlock signal: ${e.toString()}")),
      );
    }
  }
}
