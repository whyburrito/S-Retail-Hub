import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'product_detail_page.dart';
import 'cart_page.dart';
import 'order_history_page.dart';
import 'qr_scanner_page.dart';
import 'rewards_page.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final AuthService _authService = AuthService();
  String searchQuery = "";
  String activeCategory = "Featured";
  final List<String> categories = ["Featured", "All", "Electronics", "Apparel", "Home & Living", "Beauty", "Groceries", "Toys"];

  void logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    final user = FirebaseAuth.instance.currentUser;
    String displayName = "Shopper";
    if (user != null && user.email != null) {
      String emailName = user.email!.split('@')[0];
      displayName = emailName[0].toUpperCase() + emailName.substring(1);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("S RETAIL STORE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
              ),
              if (cart.totalItems > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFB8860B), shape: BoxShape.circle),
                    child: Text('${cart.totalItems}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: const Color(0xFF002244),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.storefront, color: Color(0xFFB8860B), size: 50),
                      const SizedBox(height: 10),
                      Text("Welcome, $displayName!", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            ListTile(
                leading: const Icon(Icons.stars, color: Color(0xFFB8860B)),
                title: const Text("Rewards Hub"),
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsPage())); }
            ),
            ListTile(leading: const Icon(Icons.history), title: const Text("My Orders"), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryPage())); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout", style: TextStyle(color: Colors.red)), onTap: logout),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            color: const Color(0xFF002244),
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF002244)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 35,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      bool isSelected = activeCategory == categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                              categories[index],
                              style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFF002244),
                                  fontWeight: FontWeight.bold
                              )
                          ),
                          selected: isSelected,
                          onSelected: (val) => setState(() => activeCategory = categories[index]),
                          selectedColor: const Color(0xFFB8860B), // Gold when selected
                          backgroundColor: Colors.white, // Always visible background
                          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300), // Clean grey border
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('Products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data();
                  bool matchesSearch = data['name'].toString().toLowerCase().contains(searchQuery);
                  bool matchesCategory = true;

                  if (activeCategory == "Featured") {
                    matchesCategory = data['isFeatured'] == true;
                  } else if (activeCategory != "All") {
                    matchesCategory = data['category'] == activeCategory;
                  }

                  return matchesSearch && matchesCategory;
                }).toList();

                if (docs.isEmpty) return const Center(child: Text("No products found."));

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    Product product = Product.fromMap(docs[index].data(), docs[index].id);
                    bool outOfStock = product.stockQuantity <= 0;

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(product: product))),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  color: Colors.grey.shade200,
                                  image: product.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(product.imageUrl), fit: BoxFit.cover) : null,
                                ),
                                child: outOfStock ? Container(
                                  color: Colors.black54,
                                  alignment: Alignment.center,
                                  child: const Text("SOLD OUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                ) : null,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text("₱${product.discountedPrice.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFB8860B), fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MockQRScannerPage())),
        backgroundColor: const Color(0xFF002244),
        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFFB8860B)),
        label: const Text("In-Store Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}