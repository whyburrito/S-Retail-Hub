import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrdersTab extends StatelessWidget {
  final String restaurantId;
  const OrdersTab({super.key, required this.restaurantId});

  // Sticks to your original naming and refund logic
  Future<void> _updateOrderStatus(BuildContext context, String docId, Map<String, dynamic> order, String newStatus) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Order Status"),
        content: Text("Are you sure you want to change the status to '$newStatus'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE46A3E), foregroundColor: Colors.white),
            child: const Text("Yes, Update"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updating status..."), duration: Duration(seconds: 1)));

      // 1. Update Admin Side
      await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('orders').doc(docId).update({'status': newStatus});

      String? userId = order['userId'];
      if (userId != null && userId.isNotEmpty) {
        // 2. Update User Side (Synced)
        await FirebaseFirestore.instance.collection('users').doc(userId).collection('orders').doc(docId).update({'status': newStatus});

        // ECONOMY REFUND LOGIC
        if (newStatus == 'Cancelled') {
          int pointCost = order['appliedVoucherCost'] ?? 0;
          String? voucherCode = order['appliedVoucherCode'];

          if (pointCost > 0) {
            await FirebaseFirestore.instance.collection('users').doc(userId).update({'points': FieldValue.increment(pointCost)});
          }
          if (voucherCode != null) {
            var voucherQuery = await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('vouchers').where('code', isEqualTo: voucherCode).limit(1).get();
            if (voucherQuery.docs.isNotEmpty) {
              voucherQuery.docs.first.reference.update({'currentClaims': FieldValue.increment(-1)});
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Status updated for both Admin and User!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!.docs;

        if (orders.isEmpty) return const Center(child: Text("No current orders."));

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            var order = orders[index].data() as Map<String, dynamic>;
            var docId = orders[index].id;
            DateTime date = (order['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            String status = order['status'] ?? 'Pending';
            String orderType = order['orderType'] ?? 'Dine-in';

            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("ORDER #${docId.substring(0, 5).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(DateFormat('MMM dd, hh:mm a').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 20),
                    Text("Customer: ${order['userName'] ?? 'Guest'}", style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 8),
                    Text("Total: ₱${(order['totalAmount'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        if (status == 'Pending')
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              onPressed: () => _updateOrderStatus(context, docId, order, 'Preparing'),
                              child: const Text("Accept Order", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        if (status == 'Preparing')
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _updateOrderStatus(context, docId, order, 'Done'),
                              child: const Text("Mark as Ready", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        if (status != 'Done' && status != 'Cancelled') ...[
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                            onPressed: () => _updateOrderStatus(context, docId, order, 'Cancelled'),
                            child: const Icon(Icons.close, size: 20),
                          ),
                        ],
                        if (status == 'Done') const Expanded(child: Center(child: Text("✅ Order Completed", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                        if (status == 'Cancelled') const Expanded(child: Center(child: Text("❌ Order Cancelled", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}