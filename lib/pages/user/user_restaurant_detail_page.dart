import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class UserRestaurantDetailPage extends StatefulWidget {
  final String restaurantId;
  final Map<String, dynamic> data;

  const UserRestaurantDetailPage({
    super.key,
    required this.restaurantId,
    required this.data,
  });

  @override
  State<UserRestaurantDetailPage> createState() => _UserRestaurantDetailPageState();
}

class _UserRestaurantDetailPageState extends State<UserRestaurantDetailPage> {
  bool isFavorite = false;
  bool hasShared = false;
  String selectedOrderType = "Dine-in";
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _checkIfShared();
  }

  void _checkIfFavorite() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('favorites').doc(widget.restaurantId).get();
      if (mounted) setState(() => isFavorite = doc.exists);
    }
  }

  void _checkIfShared() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('shared_logs').doc(widget.restaurantId).get();
      if (mounted) setState(() => hasShared = doc.exists);
    }
  }

  void _toggleFavorite() async {
    if (user == null) return;
    final favRef = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('favorites').doc(widget.restaurantId);

    if (isFavorite) {
      await favRef.delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from saved places.")));
    } else {
      await favRef.set(widget.data);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to saved places!"), backgroundColor: Colors.green));
    }
    setState(() => isFavorite = !isFavorite);
  }

  void _showShareDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: Text(hasShared ? "Share with Friends!" : "Earn Points!", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            content: Text(hasShared
                ? "Share this hidden gem to TikTok or Instagram!\n\n(You've already claimed your +10 points for this restaurant.)"
                : "Share this hidden gem to TikTok or Instagram to earn +10 Foodika Points!"),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
              ElevatedButton.icon(
                onPressed: () async {
                  bool pointsAwarded = false;

                  if (!hasShared && user != null) {
                    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
                      'points': FieldValue.increment(10)
                    }, SetOptions(merge: true));

                    await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('shared_logs').doc(widget.restaurantId).set({
                      'sharedAt': FieldValue.serverTimestamp()
                    });

                    pointsAwarded = true;
                    if (mounted) setState(() => hasShared = true);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(pointsAwarded ? "🎉 +10 Points added for sharing!" : "🎉 Shared successfully!"),
                            backgroundColor: Colors.green
                        )
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text("Share Now"),
              )
            ]
        )
    );
  }

  void _showRealCheckout(CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Order Summary", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Divider(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text("Dine-in"),
                      selected: selectedOrderType == "Dine-in",
                      onSelected: (val) { if (val) setModalState(() => selectedOrderType = "Dine-in"); },
                      selectedColor: const Color(0xFFE46A3E),
                      labelStyle: TextStyle(color: selectedOrderType == "Dine-in" ? Colors.white : Colors.black),
                    ),
                    ChoiceChip(
                      label: const Text("Take-out"),
                      selected: selectedOrderType == "Take-out",
                      onSelected: (val) { if (val) setModalState(() => selectedOrderType = "Take-out"); },
                      selectedColor: const Color(0xFFE46A3E),
                      labelStyle: TextStyle(color: selectedOrderType == "Take-out" ? Colors.white : Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    children: cart.items.values.map((item) => ListTile(
                      title: Text(item.name),
                      trailing: Text("₱${(item.price * item.quantity).toStringAsFixed(2)}"),
                      leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: Text("${item.quantity}x", style: const TextStyle(color: Colors.orange))),
                    )).toList(),
                  ),
                ),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Subtotal"), Text("₱${cart.subtotal.toStringAsFixed(2)}")]),
                if (cart.discountPercentage > 0)
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Discount", style: TextStyle(color: Colors.green)), Text("- ₱${(cart.subtotal - cart.total).toStringAsFixed(2)}", style: const TextStyle(color: Colors.green))]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Total", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text("₱${cart.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E)))]),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (user == null) return;

                      // ========================================================
                      // THE MASTER ORDER ID FIX
                      // ========================================================
                      // Generate ONE single ID so the databases are perfectly synced
                      final String masterOrderId = FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('orders').doc().id;

                      final orderData = {
                        'orderId': masterOrderId,
                        'userId': user!.uid,
                        'userName': user!.email?.split('@')[0] ?? 'Guest',
                        'restaurantId': widget.restaurantId,
                        'restaurantName': widget.data['name'],
                        'orderType': selectedOrderType, // Explicitly save Order Type!
                        'items': cart.items.values.map((i) => {'name': i.name, 'quantity': i.quantity, 'price': i.price}).toList(),
                        'totalAmount': cart.total, // Corrected key to match Admin panel
                        'status': 'Pending',
                        'timestamp': FieldValue.serverTimestamp(),
                        'isPaid': false,
                        'appliedVoucherCode': cart.appliedVoucherCode,
                        'appliedVoucherCost': cart.appliedVoucherCost,
                      };

                      // Use .set() with the Master ID instead of .add()
                      await FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('orders').doc(masterOrderId).set(orderData);
                      await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('orders').doc(masterOrderId).set(orderData);

                      // ========================================================
                      // VOUCHER & POINTS ECONOMY LOGIC
                      // ========================================================
                      if (cart.appliedVoucherCode != null) {
                        // 1. Deduct the points from the user
                        if (cart.appliedVoucherCost > 0) {
                          await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                            'points': FieldValue.increment(-cart.appliedVoucherCost)
                          });
                        }

                        // 2. Increase the claim count on the voucher (FOMO reduction)
                        var voucherQuery = await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('vouchers').where('code', isEqualTo: cart.appliedVoucherCode).limit(1).get();
                        if (voucherQuery.docs.isNotEmpty) {
                          voucherQuery.docs.first.reference.update({'currentClaims': FieldValue.increment(1)});
                        }
                      }

                      cart.clear();
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Placed Successfully!"), backgroundColor: Colors.green));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Confirm & Place Order", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                )
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = widget.data['imageUrl'] ?? '';
    final cart = Provider.of<CartProvider>(context);
    bool hasItemsInCart = cart.totalItems > 0 && cart.currentRestaurantId == widget.restaurantId;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: const Color(0xFFE46A3E),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  onPressed: _showShareDialog,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.ios_share, color: Colors.white),
                      if (hasShared)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle, color: Colors.green, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : Colors.white),
                  onPressed: _toggleFavorite,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(widget.data['name'] ?? 'Restaurant', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
                background: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, color: Colors.black45, colorBlendMode: BlendMode.darken)
                    : Container(color: Colors.grey.shade400, child: const Icon(Icons.restaurant, size: 80, color: Colors.white)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.data['description'] ?? "No description available.", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 15),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (widget.data['isSponsored'] == true)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber)),
                              child: const Row(children: [Icon(Icons.star, size: 14, color: Colors.orange), SizedBox(width: 4), Text("Sponsored", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange))]),
                            ),
                          if (widget.data['acceptsGCash'] == true) _buildTag("GCash"),
                          if (widget.data['acceptsCards'] == true) _buildTag("Cards"),
                          if (widget.data['hasParking'] == true) _buildTag("Parking"),
                          if (widget.data['hasWiFi'] == true) _buildTag("Free WiFi"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                const TabBar(
                  labelColor: Color(0xFFE46A3E),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFFE46A3E),
                  tabs: [Tab(text: "Menu"), Tab(text: "Vouchers"), Tab(text: "Info")],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildMenuTab(cart),
              _buildVouchersTab(cart),
              _buildInfoTab(),
            ],
          ),
        ),
        bottomNavigationBar: hasItemsInCart ? _buildCheckoutBar(cart) : null,
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCheckoutBar(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${cart.totalItems} Items", style: const TextStyle(color: Colors.grey)),
                Text("Total: ₱${cart.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
              ],
            ),
            ElevatedButton(
              onPressed: () => _showRealCheckout(cart),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE46A3E), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
              child: const Text("View Cart", style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTab(CartProvider cart) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('menu').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var items = snapshot.data!.docs;
        if (items.isEmpty) return const Center(child: Text("Menu is currently empty."));

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: items.length,
          itemBuilder: (context, index) {
            var item = items[index].data();
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty
                      ? Image.network(item['imageUrl'], width: 60, height: 60, fit: BoxFit.cover)
                      : Container(width: 60, height: 60, color: Colors.grey.shade300, child: const Icon(Icons.fastfood, color: Colors.grey)),
                ),
                title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("₱${item['price']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFE46A3E), size: 35),
                  onPressed: () {
                    cart.addItem(widget.restaurantId, items[index].id, item['name'], (item['price'] as num).toDouble());
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to order!"), duration: Duration(seconds: 1)));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVouchersTab(CartProvider cart) {
    // NEW: Wrap in a StreamBuilder to check the user's live points balance!
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          int userPoints = 0;
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            userPoints = (userSnapshot.data!.data() as Map<String, dynamic>)['points'] ?? 0;
          }

          return StreamBuilder(
            stream: FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('vouchers').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              var vouchers = snapshot.data!.docs;
              if (vouchers.isEmpty) return const Center(child: Text("No active vouchers right now."));

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: vouchers.length,
                itemBuilder: (context, index) {
                  var data = vouchers[index].data();
                  int maxClaims = data['maxClaims'] ?? 10;
                  int currentClaims = data['currentClaims'] ?? 0;
                  int pointCost = data['pointCost'] ?? 300;
                  int remaining = maxClaims - currentClaims;

                  bool isAvailable = remaining > 0;
                  bool canAfford = userPoints >= pointCost;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.stars, color: Colors.orange, size: 35),
                      title: Text("${data['discount']}% OFF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isAvailable ? Colors.black : Colors.grey)),
                      subtitle: Text("Code: ${data['code']} • $remaining left\nCost: $pointCost Points", style: TextStyle(color: canAfford ? Colors.black87 : Colors.red)),
                      trailing: OutlinedButton(
                        style: OutlinedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: (isAvailable && canAfford) ? Colors.black87 : Colors.grey),
                        onPressed: (isAvailable && canAfford) ? () {
                          // Pass the point cost to the cart!
                          cart.applyVoucher(data['code'], (data['discount'] as num).toDouble(), pointCost);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Voucher ${data['code']} applied! $pointCost points will be deducted at checkout."), backgroundColor: Colors.green));
                        } : null,
                        child: Text(!isAvailable ? "Fully Claimed" : (!canAfford ? "Need Points" : "Apply")),
                      ),
                    ),
                  );
                },
              );
            },
          );
        }
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(leading: const Icon(Icons.location_on, color: Color(0xFFE46A3E)), title: Text(widget.data['address'] ?? "Address not provided")),
        ListTile(leading: const Icon(Icons.access_time, color: Color(0xFFE46A3E)), title: Text(widget.data['operatingHours'] ?? "Hours not provided")),
        ListTile(leading: const Icon(Icons.phone, color: Color(0xFFE46A3E)), title: Text(widget.data['contactNumber'] ?? "Contact not provided")),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(context, shrinkOffset, overlapsContent) => Container(color: Colors.white, child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}