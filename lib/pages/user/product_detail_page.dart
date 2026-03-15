import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    bool outOfStock = product.stockQuantity <= 0;

    return Scaffold(
      appBar: AppBar(title: const Text("Details"), backgroundColor: Colors.transparent, foregroundColor: const Color(0xFF002244), elevation: 0),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                image: product.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover) : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category.toUpperCase(), style: const TextStyle(color: Color(0xFFB8860B), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF002244))),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("₱${product.discountedPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF002244))),
                      if (product.basePrice > product.discountedPrice) ...[
                        const SizedBox(width: 10),
                        Text("₱${product.basePrice.toStringAsFixed(2)}", style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 16)),
                      ]
                    ],
                  ),
                  const Divider(height: 40),
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(product.description.isEmpty ? "No description provided." : product.description, style: const TextStyle(color: Colors.black87, height: 1.5)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        _infoRow("SKU", product.sku),
                        _infoRow("Supplier", product.supplier.isEmpty ? "N/A" : product.supplier),
                        _infoRow("Stock", "${product.stockQuantity} Units"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Spacing for bottom bar
                ],
              ),
            )
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: outOfStock ? null : () {
                cart.addItem(product.id!, product.name, product.discountedPrice, product.stockQuantity);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to cart!"), backgroundColor: Colors.green, duration: Duration(seconds: 1)));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002244)),
              child: Text(outOfStock ? "OUT OF STOCK" : "ADD TO CART", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF002244))),
        ],
      ),
    );
  }
}