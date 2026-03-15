import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class MockQRScannerPage extends StatefulWidget {
  const MockQRScannerPage({super.key});

  @override
  State<MockQRScannerPage> createState() => _MockQRScannerPageState();
}

class _MockQRScannerPageState extends State<MockQRScannerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Faster, smoother animation for the laser
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    // Simulates finding a QR code after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), _simulateScanSuccess);
  }

  void _simulateScanSuccess() async {
    _animationController.stop();

    // Add 50 points to the user's account in Firebase!
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'points': FieldValue.increment(50)
      }, SetOptions(merge: true));
    }

    if (mounted) {
      Navigator.pop(context); // Close the scanner
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 Success! You earned 50 Foodika Points!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Makes the scanner box responsive to whatever phone you use
    final scanWindowSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark camera-like background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text("Scan QR Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Fake Camera Feed Background
          Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A2A2A), Color(0xFF121212)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
            ),
          ),

          // 2. The Dark Overlay with the Transparent Center Cutout
          Center(
            child: Container(
              width: scanWindowSize,
              height: scanWindowSize,
              decoration: BoxDecoration(
                color: Colors.transparent,
                // This massive shadow creates the dark dimming effect OUTSIDE the box
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.7), spreadRadius: 2000),
                ],
              ),
            ),
          ),

          // 3. The Scanner UI (Brackets and Laser)
          Center(
            child: SizedBox(
              width: scanWindowSize,
              height: scanWindowSize,
              child: Stack(
                children: [
                  // Corner Brackets
                  Positioned(top: 0, left: 0, child: _buildCorner(isTop: true, isLeft: true)),
                  Positioned(top: 0, right: 0, child: _buildCorner(isTop: true, isLeft: false)),
                  Positioned(bottom: 0, left: 0, child: _buildCorner(isTop: false, isLeft: true)),
                  Positioned(bottom: 0, right: 0, child: _buildCorner(isTop: false, isLeft: false)),

                  // Animated Laser strictly inside the box
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * (scanWindowSize - 4), // Subtract laser thickness
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE46A3E), // Foodika Orange
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFE46A3E).withOpacity(0.8), blurRadius: 10, spreadRadius: 2)
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Instructions
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.22,
            left: 0,
            right: 0,
            child: const Column(
              children: [
                Icon(Icons.qr_code_2, color: Colors.white70, size: 40),
                SizedBox(height: 10),
                Text(
                  "Align the QR code within the frame",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // 5. Mock Action Buttons (Flashlight & Gallery)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMockActionButton(Icons.image, "Gallery"),
                _buildMockActionButton(Icons.flashlight_on, "Flashlight"),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Helper function to draw the GCash-style corners
  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Color(0xFFE46A3E), width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Color(0xFFE46A3E), width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Color(0xFFE46A3E), width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Color(0xFFE46A3E), width: 4) : BorderSide.none,
        ),
      ),
    );
  }

  // Helper function for the bottom buttons
  Widget _buildMockActionButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}