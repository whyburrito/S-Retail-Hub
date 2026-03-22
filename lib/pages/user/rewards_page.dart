import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/voucher.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  // NEW: Track which button is currently loading to prevent spam-clicking
  String? redeemingVoucherId;

  void _redeemVoucher(VoucherModel voucher, int currentPoints, String uid) async {
    if (redeemingVoucherId != null) return; // Prevent spam

    if (currentPoints < voucher.costInPoints) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not enough points!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => redeemingVoucherId = voucher.id);
    ScaffoldMessenger.of(context).clearSnackBars(); // Instantly clears old popups to kill the "lag" feel

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference userRef = FirebaseFirestore.instance.collection('Users').doc(uid);
        DocumentSnapshot userSnap = await transaction.get(userRef);

        var userData = userSnap.data() as Map<String, dynamic>? ?? {};
        int dbPoints = userData.containsKey('points') ? userData['points'] : 0;

        if (dbPoints < voucher.costInPoints) throw Exception("Insufficient points.");

        // NEW: Manually update the list and inject a unique Timestamp so Firebase allows duplicates!
        List currentVouchers = userData.containsKey('ownedVouchers') ? List.from(userData['ownedVouchers']) : [];
        var newVoucherData = voucher.toMap();
        newVoucherData['claimId'] = DateTime.now().millisecondsSinceEpoch.toString();
        currentVouchers.add(newVoucherData);

        transaction.update(userRef, {
          'points': dbPoints - voucher.costInPoints,
          'ownedVouchers': currentVouchers
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully claimed ${voucher.name}!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => redeemingVoucherId = null); // Turn off loading spinner
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Rewards Hub"), backgroundColor: const Color(0xFF002244)),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());

          var data = userSnap.data!.data() as Map<String, dynamic>? ?? {};
          int myPoints = data.containsKey('points') ? data['points'] : 0;
          List myVouchers = data.containsKey('ownedVouchers') ? data['ownedVouchers'] : [];

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF002244),
                child: Column(
                  children: [
                    const Text("My S-Retail Points", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text("$myPoints", style: const TextStyle(color: Color(0xFFB8860B), fontSize: 40, fontWeight: FontWeight.bold)),
                    Text("You have ${myVouchers.length} vouchers in your wallet", style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance.collection('Vouchers').snapshots(),
                  builder: (context, voucherSnap) {
                    if (!voucherSnap.hasData) return const Center(child: CircularProgressIndicator());

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: voucherSnap.data!.docs.length,
                      itemBuilder: (context, index) {
                        var v = VoucherModel.fromMap(voucherSnap.data!.docs[index].data(), voucherSnap.data!.docs[index].id);
                        bool canAfford = myPoints >= v.costInPoints;
                        bool isThisRedeeming = redeemingVoucherId == v.id;

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.star, color: Color(0xFFB8860B)),
                            title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Cap: ₱${v.maxCap}"),
                            trailing: ElevatedButton(
                              onPressed: canAfford && !isThisRedeeming ? () => _redeemVoucher(v, myPoints, uid) : null,
                              style: ElevatedButton.styleFrom(backgroundColor: canAfford ? const Color(0xFFB8860B) : Colors.grey),
                              // NEW: Replaces text with a cool loading spinner when clicked!
                              child: isThisRedeeming
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text("${v.costInPoints} PTS"),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}