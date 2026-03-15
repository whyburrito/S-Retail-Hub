import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please log in.")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Order History", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF002244),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Querying the Master Orders node where userId matches
        stream: FirebaseFirestore.instance.collection('Orders').where('userId', isEqualTo: user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 15),
                  Text("No past orders found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          // Sort locally to avoid forcing the student to create a Firestore Composite Index
          var sortedDocs = docs.toList()..sort((a, b) {
            var aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            var bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            return (bTime?.toDate() ?? DateTime.now()).compareTo(aTime?.toDate() ?? DateTime.now());
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              OrderModel order = OrderModel.fromMap(sortedDocs[index].data() as Map<String, dynamic>, sortedDocs[index].id);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Order #${order.id!.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF002244))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.status == 'Done' ? Colors.green.shade100 : (order.status == 'Cancelled' ? Colors.red.shade100 : Colors.orange.shade100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(order.status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: order.status == 'Done' ? Colors.green.shade800 : (order.status == 'Cancelled' ? Colors.red.shade800 : Colors.orange.shade800))),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text("Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(order.timestamp)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),

                      // Show item summary
                      Text("${order.items.length} item(s) • ${order.orderType}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Amount:"),
                          Text("₱${order.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFB8860B))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}