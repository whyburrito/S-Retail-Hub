import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_restaurant_detail_page.dart';

class SavedPlacesPage extends StatelessWidget {
  const SavedPlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Saved Places"), backgroundColor: const Color(0xFFE46A3E), foregroundColor: Colors.white),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('favorites').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("You have no saved places yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data();
              String restaurantId = docs[index].id;
              String imageUrl = data['imageUrl'] ?? '';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover)
                        : Container(width: 60, height: 60, color: Colors.grey.shade300, child: const Icon(Icons.restaurant, color: Colors.grey)),
                  ),
                  title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['cuisine'] ?? 'Various'} • ${data['priceRange'] ?? ''}"),
                  trailing: const Icon(Icons.favorite, color: Colors.red),
                  onTap: () async {
                    // Fetch the full original restaurant data before navigating
                    var fullDoc = await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get();
                    if (fullDoc.exists && context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => UserRestaurantDetailPage(restaurantId: restaurantId, data: fullDoc.data()!)));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}