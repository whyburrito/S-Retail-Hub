import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  void _showReviewDialog(BuildContext context, String restaurantId, String restaurantName, String orderId) {
    double selectedRating = 5;
    final commentController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing accidentally while submitting
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Rate $restaurantName"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("How was your experience?"),
              const SizedBox(height: 10),
              // Interactive Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => selectedRating = index + 1.0),
                )),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Leave a comment (optional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                setState(() => isSubmitting = true);
                try {
                  // 1. Fetch User's Display Name
                  String userName = user?.email?.split('@')[0].toUpperCase() ?? "GUEST";
                  var userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
                  if (userDoc.exists && userDoc.data()!.containsKey('name') && userDoc.data()!['name'].toString().isNotEmpty) {
                    userName = userDoc.data()!['name'];
                  }

                  // 2. Save the Review to the Restaurant's Database
                  await FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .collection('reviews')
                      .add({
                    'userId': user?.uid,
                    'userName': userName,
                    'rating': selectedRating,
                    'comment': commentController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // 3. Update the Restaurant's Global Average Rating
                  var restRef = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);
                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    var snapshot = await transaction.get(restRef);
                    if (!snapshot.exists) return;

                    double currentAvg = (snapshot.data()!['avgRating'] ?? 0.0).toDouble();
                    int reviewCount = (snapshot.data()!['reviewCount'] ?? 0).toInt();

                    // Calculate new average
                    double newAvg = ((currentAvg * reviewCount) + selectedRating) / (reviewCount + 1);
                    newAvg = double.parse(newAvg.toStringAsFixed(1)); // Keep it to 1 decimal place (e.g., 4.5)

                    transaction.update(restRef, {
                      'avgRating': newAvg,
                      'reviewCount': reviewCount + 1,
                    });
                  });

                  // 4. Mark this specific order as rated so the button disappears!
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('orders')
                      .doc(orderId)
                      .update({'isRated': true});

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Thank you for your feedback!"),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  setState(() => isSubmitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE46A3E), foregroundColor: Colors.white),
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Please log in.")));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: const Color(0xFFE46A3E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders') // Make sure this matches where your orders are saved
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No past orders found.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var order = doc.data() as Map<String, dynamic>;
              String orderId = doc.id;

              String status = order['status'] ?? 'Pending';
              bool isDone = status == 'Done';
              bool isRated = order['isRated'] ?? false;
              DateTime date = (order['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                elevation: 3,
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
                          Expanded(
                            child: Text(
                              order['restaurantName'] ?? 'Unknown Restaurant',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'Done' ? Colors.green.shade100 : (status == 'Cancelled' ? Colors.red.shade100 : Colors.orange.shade100),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == 'Done' ? Colors.green.shade800 : (status == 'Cancelled' ? Colors.red.shade800 : Colors.orange.shade800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text("Order ID: ${orderId.substring(0, 8)}", style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text("Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(date)}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text("Total: ₱${(order['totalAmount'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32))),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // ONLY SHOW REVIEW BUTTON IF ORDER IS DONE AND NOT RATED
                          if (isDone && !isRated)
                            ElevatedButton.icon(
                              onPressed: () => _showReviewDialog(
                                  context,
                                  order['restaurantId'],
                                  order['restaurantName'],
                                  orderId
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              icon: const Icon(Icons.star, size: 18),
                              label: const Text("Rate Service", style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          else if (isDone && isRated)
                            const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 20),
                                SizedBox(width: 4),
                                Text("Rated", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                        ],
                      )
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