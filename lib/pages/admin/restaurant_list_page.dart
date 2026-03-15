import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'add_restaurant_page.dart';
import 'restaurant_detail/restaurant_detail_dashboard.dart';

class RestaurantListPage extends StatelessWidget {
  const RestaurantListPage({super.key});

  // THE NEW DEEP DELETE FUNCTION
  Future<void> _deleteRestaurantFully(BuildContext context, DocumentSnapshot doc) async {
    // Show a loading indicator while we clean the database
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final docRef = doc.reference;
      final data = doc.data() as Map<String, dynamic>;

      // 1. Delete all Menu Items and their Images
      final menuSnapshot = await docRef.collection('menu').get();
      for (var item in menuSnapshot.docs) {
        final itemData = item.data();
        if (itemData['imageUrl'] != null && itemData['imageUrl'].toString().isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(itemData['imageUrl']).delete();
          } catch (_) {} // Ignore if image is already gone
        }
        await item.reference.delete();
      }

      // 2. Delete all Vouchers
      final voucherSnapshot = await docRef.collection('vouchers').get();
      for (var v in voucherSnapshot.docs) await v.reference.delete();

      // 3. Delete all History Logs
      final historySnapshot = await docRef.collection('history').get();
      for (var h in historySnapshot.docs) await h.reference.delete();

      // NEW: Delete Live Orders
      final orderSnapshot = await docRef.collection('orders').get();
      for (var o in orderSnapshot.docs) await o.reference.delete();

      // NEW: Delete Reviews
      final reviewSnapshot = await docRef.collection('reviews').get();
      for (var r in reviewSnapshot.docs) await r.reference.delete();

      // 4. Delete the Main Restaurant Image
      if (data.containsKey('imageUrl') && data['imageUrl'].toString().isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(data['imageUrl']).delete();
        } catch (_) {}
      }

      // 5. Finally, delete the restaurant document itself
      await docRef.delete();

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restaurant completely deleted.")));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting: $e")));
      }
    }
  }

  void _confirmDelete(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Restaurant"),
        content: Text("Are you sure you want to remove '${data['name']}'? This will delete all its menu items, vouchers, and images permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close confirm dialog
              _deleteRestaurantFully(context, doc); // Trigger deep delete
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No restaurants added yet."));

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;

            return Card(
              elevation: 2,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE0B2),
                  child: Icon(Icons.restaurant, color: Colors.orange),
                ),
                title: Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['address'] ?? 'No Address'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RestaurantDetailDashboard(
                        restaurantId: doc.id,
                        restaurantData: data,
                      ),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, doc),
                ),
              ),
            );
          },
        );
      },
    );
  }
}