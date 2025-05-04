import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:clipboard/clipboard.dart';

import 'transaction_verification.dart';

class CryptoTransactionScreen extends StatelessWidget {
  final String usdtBep20Address = '0x10017879402aAdEe9171eA928e6210318e92283a';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Send USDT (BEP20)",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '⚠️ Send only USDT using the **BEP20 (Binance Smart Chain)** network.\n'
                          '**Sending via other networks (like ERC20, TRC20) will result in permanent loss of funds.**',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Send exactly to this address:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            QrImageView(
              data: usdtBep20Address,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      usdtBep20Address,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blueAccent),
                    onPressed: () {
                      FlutterClipboard.copy(usdtBep20Address).then((value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Address copied")),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'After sending, tap below to verify:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.verified),
              label: const Text('Verify Transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TransactionVerificationScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


//BCS api key:- 4WT4G8F72J5GQIC27J7VJZ2IEA6XPFQXFR