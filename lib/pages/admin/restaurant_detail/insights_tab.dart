import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsightsTab extends StatelessWidget {
  final String restaurantId;
  const InsightsTab({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // We pull from the restaurant's specific orders to see who their customers are
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final orders = snapshot.data!.docs;
        if (orders.isEmpty) {
          return const Center(child: Text("No data yet. Insights appear after your first order!"));
        }

        // Extract unique User IDs from the orders
        Set<String> customerIds = orders.map((doc) => doc['userId'] as String).toSet();

        return FutureBuilder<List<DocumentSnapshot>>(
          // Fetch the demographic data for all unique customers
          future: Future.wait(customerIds.map((uid) =>
              FirebaseFirestore.instance.collection('users').doc(uid).get()
          )),
          builder: (context, userSnapshots) {
            if (!userSnapshots.hasData) return const Center(child: CircularProgressIndicator());

            int students = 0;
            int professionals = 0;
            int others = 0;

            // Age Buckets Setup
            Map<String, int> ageMap = {
              '< 18': 0,
              '18 - 24': 0,
              '25 - 34': 0,
              '35+': 0,
              'Unknown': 0,
            };

            for (var doc in userSnapshots.data!) {
              if (doc.exists) {
                var data = doc.data() as Map<String, dynamic>;

                // 1. Process User Status
                String status = data['userStatus'] ?? 'Other';
                if (status == 'Student') students++;
                else if (status == 'Professional') professionals++;
                else others++;

                // 2. Process Age from Birthday
                Timestamp? bdayTimestamp = data['birthday'] as Timestamp?;
                if (bdayTimestamp != null) {
                  DateTime bday = bdayTimestamp.toDate();
                  DateTime today = DateTime.now();

                  // Calculate exact age
                  int age = today.year - bday.year;
                  if (today.month < bday.month || (today.month == bday.month && today.day < bday.day)) {
                    age--;
                  }

                  // Sort into buckets
                  if (age < 18) ageMap['< 18'] = ageMap['< 18']! + 1;
                  else if (age >= 18 && age <= 24) ageMap['18 - 24'] = ageMap['18 - 24']! + 1;
                  else if (age >= 25 && age <= 34) ageMap['25 - 34'] = ageMap['25 - 34']! + 1;
                  else ageMap['35+'] = ageMap['35+']! + 1;
                } else {
                  ageMap['Unknown'] = ageMap['Unknown']! + 1;
                }
              }
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("Customer Demographics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("Based on ${customerIds.length} unique customers", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 25),

                // SECTION: User Status Breakdown
                _buildInsightCard(
                  title: "User Status",
                  icon: Icons.pie_chart,
                  child: Column(
                    children: [
                      _buildStatBar("Students", students, customerIds.length, Colors.orange),
                      _buildStatBar("Professionals", professionals, customerIds.length, Colors.blue),
                      _buildStatBar("Others", others, customerIds.length, Colors.grey),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION: Age Groups
                _buildInsightCard(
                  title: "Age Groups",
                  icon: Icons.group,
                  child: Column(
                    // Only display buckets that have at least 1 user to keep the UI clean
                    children: ageMap.entries
                        .where((e) => e.value > 0)
                        .map((e) => _buildStatBar(e.key, e.value, customerIds.length, Colors.purple))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 30),
                const Text(
                  "Note: Data is aggregated and anonymized to protect customer privacy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInsightCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 20, color: const Color(0xFFE46A3E)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const Divider(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int count, int total, Color color) {
    double percentage = total > 0 ? count / total : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text("${(percentage * 100).toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}