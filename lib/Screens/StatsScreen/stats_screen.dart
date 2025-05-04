import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final Map<String, Duration> durations = {
    '7 Days': Duration(days: 7),
    '1 Month': Duration(days: 30),
    '3 Months': Duration(days: 90),
    '1 Year': Duration(days: 365),
  };

  Map<String, Map<String, dynamic>> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllStats();
  }

  Future<Map<String, dynamic>> fetchSignalStats(Duration duration) async {
    final from = Timestamp.fromDate(DateTime.now().subtract(duration));
    final querySnapshot = await FirebaseFirestore.instance
        .collection('CryptoSignals')
        .where('postDate', isGreaterThanOrEqualTo: from)
        .get();

    final docs = querySnapshot.docs;
    int totalSignals = docs.length;
    int totalWins = 0;
    int totalLoss = 0;
    double totalReturn = 0;

    for (var doc in docs) {
      final data = doc.data();
      final isSL = data['isSL'] ?? false;
      final targets = List<Map>.from(data['targets']);
      final leverage = data['leverage'];
      final entry = data['broughtAt'];

      bool hitFirstTarget = targets.isNotEmpty && targets[0]['isComplete'] == true;

      if (hitFirstTarget) {
        totalWins++;
        double firstTarget = entry;
        for (int i = targets.length - 1; i >= 0; i--) {
          if (targets[i]['isComplete'] == true) {
            firstTarget = double.tryParse(targets[i]['target'].toString()) ?? entry;
            break;
          }
        }
        double percentGain = ((firstTarget - entry) / entry) * 100 * leverage;
        totalReturn += percentGain;
      } else if (isSL) {
        totalLoss++;
        double sl = data['sl'];
        double percentLoss = ((sl - entry) / entry) * 100 * leverage;
        totalReturn += percentLoss;
      }
    }

    double winPercentage = totalSignals > 0 ? (totalWins / totalSignals) * 100 : 0;

    return {
      'totalSignals': totalSignals,
      'totalWins': totalWins,
      'totalLoss': totalLoss,
      'winPercentage': winPercentage,
      'totalReturn': totalReturn,
    };
  }

  Future<void> fetchAllStats() async {
    Map<String, Map<String, dynamic>> results = {};
    for (var entry in durations.entries) {
      final data = await fetchSignalStats(entry.value);
      results[entry.key] = data;
    }
    setState(() {
      stats = results;
      isLoading = false;
    });
  }

  Widget buildStatCard(String title, Map<String, dynamic> data) {
    return Animate(
      effects: [FadeEffect(), SlideEffect()],
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        margin: EdgeInsets.symmetric(vertical: 12),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
            SizedBox(height: 12),
            Text("📊 Total Signals: ${data['totalSignals']}", style: GoogleFonts.poppins(fontSize: 16)),
            Text("✅ Total Wins: ${data['totalWins']}", style: GoogleFonts.poppins(fontSize: 16)),
            Text("❌ Total Losses: ${data['totalLoss']}", style: GoogleFonts.poppins(fontSize: 16)),
            Text("🏆 Win %: ${data['winPercentage'].toStringAsFixed(2)}%", style: GoogleFonts.poppins(fontSize: 16)),
            Text("💰 Total Return: ${data['totalReturn'].toStringAsFixed(2)}%", style: GoogleFonts.poppins(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget shimmerPlaceholder() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: durations.length,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('📈 Crypto Signal Stats', style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: isLoading
          ? shimmerPlaceholder()
          : ListView(
        padding: EdgeInsets.all(16),
        children: durations.keys.map((key) {
          final data = stats[key]!;
          return buildStatCard(key, data);
        }).toList(),
      ),
    );
  }
}
