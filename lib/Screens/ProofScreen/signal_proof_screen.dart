import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignalProofScreen extends StatefulWidget {
  @override
  _SignalProofScreenState createState() => _SignalProofScreenState();
}

class _SignalProofScreenState extends State<SignalProofScreen> {
  final String adminPassword = 'Ayush859860';
  String? imageUrl;

  Future<void> _promptPasswordAndUpload(String docId) async {
    TextEditingController _passwordController = TextEditingController();
    TextEditingController _imageUrlController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.pink[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('🔒 Enter Admin Password', style: TextStyle(color: Colors.purple)),
          content: Column(
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock, color: Colors.pink),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _imageUrlController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Image Url',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image, color: Colors.pink),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: Text('Submit'),
              onPressed: () {
                if (_passwordController.text == adminPassword) {
                  Navigator.of(context).pop();
                  imageUrl = _imageUrlController.text.trim();
                  _handleUpload(docId);
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.pink,
                      content: Text('Incorrect password'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleUpload(String docId) async {
    try {
      if (imageUrl != null) {
        await FirebaseFirestore.instance
            .collection('CryptoSignals')
            .doc(docId)
            .update({'profitLossImageUrl': imageUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('✅ Image uploaded successfully'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('✅ Image Url Unavailable'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('❌ Upload failed: $e'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.pinkAccent,
        title: Text('💹 Only premium signal proof', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('CryptoSignals').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching signals'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.pink));
          }

          final signals = snapshot.data!.docs;
          return ListView.builder(
            itemCount: signals.length,
            itemBuilder: (context, index) {
              final data = signals[index].data() as Map<String, dynamic>;
              final docId = signals[index].id;

              return data['isPremium'] == true ? AnimatedContainer(
                duration: Duration(milliseconds: 500),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[200]!, Colors.purple[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.pinkAccent.withOpacity(0.3), blurRadius: 10)
                  ],
                ),
                child: GestureDetector(
                  onDoubleTap: () => _promptPasswordAndUpload(docId),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Icon(Icons.trending_up, color: Colors.white, size: 36),
                    title: Text(data['symbol'] ?? 'No Symbol',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          'Posted: ${data['postDate']?.toDate()?.toLocal().toString().split('.')[0] ?? 'N/A'}',
                          style: TextStyle(color: Colors.white70),
                        ),
                        SizedBox(height: 4),

                        if (data['broughtAt'] != null)
                          Text(
                            'Brought at: ${data['broughtAt']}',
                            style: TextStyle(color: Colors.white),
                          ),

                        if (data['targets'] != null && data['targets'] is List)
                          Text(
                            'Targets: ${data['targets'].map((t) => t['target']).join(', ')}',
                            style: TextStyle(color: Colors.white),
                          ),

                        SizedBox(height: 10),
                        if (data['profitLossImageUrl'] != null && data['profitLossImageUrl'].toString().trim().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Image.network(
                                  data['profitLossImageUrl'],
                                  width: constraints.maxWidth,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        '❌ Failed to load image',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        else
                          Text("🖼️ No proof uploaded yet", style: TextStyle(color: Colors.white70)),

                      ],
                    ),
                  ),
                ),
              ) : Container();
            },
          );
        },
      ),
    );
  }
}
