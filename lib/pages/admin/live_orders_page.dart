import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';

class LiveOrdersPage extends StatelessWidget {
  const LiveOrdersPage({super.key});

  Future<void> _updateOrderStatus(BuildContext context, String orderId, String newStatus, OrderModel order) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Order"),
        content: Text("Change order status to '$newStatus'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002244)),
            child: const Text("Update"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. Update the Master Order Node
        await FirebaseFirestore.instance.collection('Orders').doc(orderId).update({'status': newStatus});

        // 2. Admin Cancel Refund Logic (Protects the consumer if the Admin rejects the order)
        if (newStatus == 'Cancelled') {
          // Restore stock for cancelled items
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            for (var item in order.items) {
              DocumentReference productRef = FirebaseFirestore.instance.collection('Products').doc(item.productId);
              DocumentSnapshot pSnap = await transaction.get(productRef);
              if (pSnap.exists) {
                int currentStock = pSnap.get('stockQuantity');
                transaction.update(productRef, {'stockQuantity': currentStock + item.quantity});
              }
            }
          });
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order marked as $newStatus"), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Orders').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text("No live orders at the moment.", style: TextStyle(color: Colors.grey, fontSize: 16)));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              OrderModel order = OrderModel.fromMap(docs[index].data(), docs[index].id);

              bool isPending = order.status == 'Pending';
              bool isPreparing = order.status == 'Preparing';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Order #${order.id!.substring(0, 6).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF002244))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.status == 'Done' ? Colors.green.shade100 : (order.status == 'Cancelled' ? Colors.red.shade100 : Colors.orange.shade100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(order.status, style: TextStyle(fontWeight: FontWeight.bold, color: order.status == 'Done' ? Colors.green.shade800 : (order.status == 'Cancelled' ? Colors.red.shade800 : Colors.orange.shade800))),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text("Customer: ${docs[index].data()['userName'] ?? 'Guest'}", style: const TextStyle(fontSize: 14)),
                      Text("Date: ${DateFormat('MMM dd, hh:mm a').format(order.timestamp)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 10),

                      // List the items bought
                      if (order.discountAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Voucher: ${order.voucherName}", style: const TextStyle(color: Colors.green, fontSize: 13, fontStyle: FontStyle.italic)),
                              Text("- ₱${order.discountAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order.orderType, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text("Total: ₱${order.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB8860B), fontSize: 16)),
                        ],
                      ),

                      // Action Buttons
                      if (isPending || isPreparing) ...[
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            if (isPending)
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002244)),
                                  onPressed: () => _updateOrderStatus(context, order.id!, 'Preparing', order),
                                  child: const Text("Accept Order"),
                                ),
                              ),
                            if (isPreparing)
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () => _updateOrderStatus(context, order.id!, 'Done', order),
                                  child: const Text("Mark as Done"),
                                ),
                              ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                              onPressed: () => _updateOrderStatus(context, order.id!, 'Cancelled', order),
                              child: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ]
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