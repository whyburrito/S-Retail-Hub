import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryTab extends StatelessWidget {
  final String restaurantId;
  const HistoryTab({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var log = snapshot.data!.docs[index];
            DateTime date = (log['timestamp'] as Timestamp).toDate();
            return ListTile(
              leading: const Icon(Icons.history_toggle_off),
              title: Text(log['action']),
              subtitle: Text("${log['details']}\n${DateFormat('yMMMd – kk:mm').format(date)}"),
            );
          },
        );
      },
    );
  }
}