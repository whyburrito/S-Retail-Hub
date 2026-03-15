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
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    Timer(const Duration(milliseconds: 2500), _simulateScanSuccess);
  }

  void _simulateScanSuccess() async {
    _animationController.stop();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'points': FieldValue.increment(50)
      }, SetOptions(merge: true));
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 In-Store Check-in Success! +50 Points!"),
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
    final scanWindowSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Text("Store Check-in", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF121212)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
          Center(
            child: Container(
              width: scanWindowSize, height: scanWindowSize,
              decoration: BoxDecoration(color: Colors.transparent, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.7), spreadRadius: 2000)]),
            ),
          ),
          Center(
            child: SizedBox(
              width: scanWindowSize, height: scanWindowSize,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _buildCorner(isTop: true, isLeft: true)),
                  Positioned(top: 0, right: 0, child: _buildCorner(isTop: true, isLeft: false)),
                  Positioned(bottom: 0, left: 0, child: _buildCorner(isTop: false, isLeft: true)),
                  Positioned(bottom: 0, right: 0, child: _buildCorner(isTop: false, isLeft: false)),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * (scanWindowSize - 4),
                        left: 0, right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB8860B), // S-Retail Gold
                            boxShadow: [BoxShadow(color: const Color(0xFFB8860B).withOpacity(0.8), blurRadius: 10, spreadRadius: 2)],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.22,
            left: 0, right: 0,
            child: const Column(
              children: [
                Icon(Icons.storefront, color: Colors.white70, size: 40),
                SizedBox(height: 10),
                Text("Scan branch QR code to earn loyalty points", style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Color(0xFFB8860B), width: 4) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Color(0xFFB8860B), width: 4) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Color(0xFFB8860B), width: 4) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Color(0xFFB8860B), width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}