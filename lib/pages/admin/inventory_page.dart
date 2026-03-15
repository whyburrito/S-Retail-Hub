import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';
import 'product_form_page.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  void _confirmDelete(BuildContext context, String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text("Permanently delete '$productName' from the cloud database?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('Products').doc(productId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product deleted."), backgroundColor: Colors.red));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Products').orderBy('dateAdded', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 15),
                  Text("Inventory is empty.", style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              Product product = Product.fromMap(docs[index].data(), docs[index].id);
              bool isLowStock = product.stockQuantity <= 5;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      image: product.imageUrl.isNotEmpty
                          ? DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: product.imageUrl.isEmpty ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF002244))),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SKU: ${product.sku} • ₱${product.discountedPrice.toStringAsFixed(2)}"),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isLowStock) const Icon(Icons.error, color: Colors.red, size: 14),
                          if (isLowStock) const SizedBox(width: 4),
                          Text(
                            isLowStock ? "Low Stock: ${product.stockQuantity} left" : "In Stock: ${product.stockQuantity}",
                            style: TextStyle(color: isLowStock ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFFB8860B)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormPage(productToEdit: product))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, product.id!, product.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB8860B),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormPage())),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}