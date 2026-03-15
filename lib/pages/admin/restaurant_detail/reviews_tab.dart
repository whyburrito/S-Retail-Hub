import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReviewsTab extends StatelessWidget {
  final String restaurantId;
  const ReviewsTab({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // =========================================================
          // 1. SUMMARY HEADER (Reads from the main restaurant doc)
          // =========================================================
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('restaurants')
                .doc(restaurantId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const SizedBox.shrink();
              }

              var data = snapshot.data!.data() as Map<String, dynamic>;
              double avgRating = (data['avgRating'] ?? 0.0).toDouble();
              int reviewCount = (data['reviewCount'] ?? 0).toInt();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text("Overall Rating", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E)),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                          child: Text("/ 5", style: TextStyle(fontSize: 20, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        if (index < avgRating.floor()) {
                          return const Icon(Icons.star, color: Colors.amber, size: 28);
                        } else if (index < avgRating && avgRating % 1 != 0) {
                          return const Icon(Icons.star_half, color: Colors.amber, size: 28);
                        } else {
                          return const Icon(Icons.star_border, color: Colors.amber, size: 28);
                        }
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text("Based on $reviewCount reviews", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            },
          ),

          // =========================================================
          // 2. LIST OF INDIVIDUAL REVIEWS
          // =========================================================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('restaurants')
                  .doc(restaurantId)
                  .collection('reviews')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reviews = snapshot.data!.docs;

                if (reviews.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No reviews yet from customers.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    var review = reviews[index].data() as Map<String, dynamic>;
                    double rating = (review['rating'] ?? 5.0).toDouble();
                    DateTime date = (review['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

                    return Card(
                      elevation: 2,
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
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 18,
                                    );
                                  }),
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(date),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              review['comment']?.toString().isNotEmpty == true
                                  ? review['comment']
                                  : 'No written comment provided.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                fontStyle: review['comment']?.toString().isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
                                color: review['comment']?.toString().isNotEmpty == true ? Colors.black87 : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "— ${review['userName'] ?? 'Anonymous'}",
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE46A3E),
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}