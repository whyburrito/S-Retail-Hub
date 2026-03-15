import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_map_page.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

import 'personal_details_page.dart';
import 'order_history_page.dart';
import 'saved_places_page.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final AuthService _authService = AuthService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String searchQuery = "";
  String activeFilter = "All";

  final List<String> quickFilters = ["All", "Filipino", "Fast Food", "Cafe", "Budget", "Free WiFi"];

  void logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false
      );
    }
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap ?? () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title coming soon!")));
      },
    );
  }

  Widget _buildDrawer(String email) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                String displayName = email.split('@')[0].toUpperCase();
                int points = 0;

                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null) {
                    if (data.containsKey('name') && data['name'].toString().trim().isNotEmpty) {
                      displayName = data['name'].toString().toUpperCase();
                    }
                    if (data.containsKey('points')) {
                      points = data['points'];
                    }
                  }
                }

                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFFE46A3E)),
                  accountName: Row(
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: Text("⭐ $points Pts", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                  accountEmail: Text(email, style: const TextStyle(color: Colors.white70)),
                  // Inside _buildDrawer in user_dashboard_page.dart
                  currentAccountPicture: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                    builder: (context, snapshot) {
                      String? profileUrl;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        profileUrl = (snapshot.data!.data() as Map<String, dynamic>?)?['profileImageUrl'];
                      }

                      return CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: (profileUrl != null && profileUrl.isNotEmpty)
                            ? NetworkImage(profileUrl)
                            : null,
                        child: (profileUrl == null || profileUrl.isEmpty)
                            ? const Icon(Icons.person, color: Color(0xFFE46A3E), size: 40)
                            : null,
                      );
                    },
                  ),
                );
              }
          ),
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.white, size: 30),
              title: const Text("Foodika PRO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: const Text("Unlock exclusive perks", style: TextStyle(color: Colors.white70, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showProModal(context);
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerTile(Icons.person_outline, "Personal Details", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalDetailsPage()));
                }),
                _drawerTile(Icons.history, "Order History", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryPage()));
                }),
                _drawerTile(Icons.favorite_border, "Saved Places", () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesPage()));
                }),
                const Divider(),
                _drawerTile(Icons.settings_outlined, "Settings", null),
                _drawerTile(Icons.help_outline, "Help & Support", null),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Log Out"),
            ),
          ),
        ],
      ),
    );
  }

  void _showProModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium, color: Colors.orange, size: 40),
            ),
            const SizedBox(height: 15),
            const Text("Upgrade to Foodika PRO", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Just ₱89/month for the ultimate foodie experience.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 25),

            _buildProPerk(Icons.block, "Zero Advertisements"),
            _buildProPerk(Icons.confirmation_num, "Access to Exclusive Gold Vouchers"),
            _buildProPerk(Icons.stars, "Earn Double Loyalty Points"),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("🎉 Welcome to Foodika PRO! Payment successful."), backgroundColor: Colors.green)
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE46A3E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Subscribe Now - ₱89/mo", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildProPerk(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 24),
          const SizedBox(width: 15),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? "User";

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(userEmail),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          UserMapPage(searchQuery: searchQuery, activeFilter: activeFilter),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search for food...",
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      suffixIcon: const Icon(Icons.search, color: Color(0xFFE46A3E)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: quickFilters.length,
                    itemBuilder: (context, index) {
                      String filter = quickFilters[index];
                      bool isSelected = activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) => setState(() => activeFilter = filter),
                          selectedColor: const Color(0xFFE46A3E),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 30,
            left: 15,
            right: 15,
            child: ActiveOrderTracker(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET: Floating Active Order Tracker
// ============================================================================
class ActiveOrderTracker extends StatelessWidget {
  const ActiveOrderTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .where('status', whereIn: ['Pending', 'Preparing'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        var activeOrderDoc = snapshot.data!.docs.first;
        var activeOrder = activeOrderDoc.data() as Map<String, dynamic>;
        String status = activeOrder['status'] ?? 'Pending';
        String restaurantName = activeOrder['restaurantName'] ?? 'Restaurant';

        double progress = status == 'Preparing' ? 0.7 : 0.3;
        Color statusColor = status == 'Preparing' ? Colors.orange : Colors.blue;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveOrderDetailScreen(
                  orderData: activeOrder,
                  orderId: activeOrderDoc.id, // This is now identical to the Admin's ID!
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Order from $restaurantName",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                              "Status: $status (Tap for details)",
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE46A3E).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delivery_dining, color: Color(0xFFE46A3E), size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    color: statusColor,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// SCREEN: Active Order Details (UPGRADED CANCEL & REFUND LOGIC)
// ============================================================================
class ActiveOrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;

  const ActiveOrderDetailScreen({super.key, required this.orderData, required this.orderId});

  Future<void> _cancelOrder(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order", style: TextStyle(color: Colors.red)),
        content: const Text("Are you sure you want to cancel this order? Your points will be refunded."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Keep Order", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        String restaurantId = orderData['restaurantId'];
        int pointCost = orderData['appliedVoucherCost'] ?? 0;
        String? voucherCode = orderData['appliedVoucherCode'];

        // 1. Update Both Databases (Perfectly Synced)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('orders').doc(orderId).update({'status': 'Cancelled'});
        await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('orders').doc(orderId).update({'status': 'Cancelled'});

        // 2. ECONOMY FIX: Refund the points if they used a voucher
        if (pointCost > 0) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'points': FieldValue.increment(pointCost)
          });
        }

        // 3. ECONOMY FIX: Return the voucher quantity to the public pool
        if (voucherCode != null) {
          var voucherQuery = await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('vouchers').where('code', isEqualTo: voucherCode).limit(1).get();
          if (voucherQuery.docs.isNotEmpty) {
            voucherQuery.docs.first.reference.update({'currentClaims': FieldValue.increment(-1)});
          }
        }

        if (context.mounted) {
          Navigator.pop(context); // Close the detail screen
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(pointCost > 0 ? "Order cancelled. $pointCost points refunded!" : "Order cancelled successfully."), backgroundColor: Colors.red)
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error cancelling order: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String status = orderData['status'] ?? 'Pending';
    Color statusColor = status == 'Preparing' ? Colors.orange : Colors.blue;
    double progress = status == 'Preparing' ? 0.7 : 0.3;

    bool canCancel = status == 'Pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: const Color(0xFFE46A3E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.fastfood, size: 80, color: statusColor),
                  const SizedBox(height: 10),
                  Text(status.toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: progress, color: statusColor, minHeight: 10, backgroundColor: Colors.grey.shade300),
            const SizedBox(height: 30),
            const Text("Order Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text("Restaurant"),
              subtitle: Text(orderData['restaurantName'] ?? 'Unknown'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text("Order ID"),
              subtitle: Text(orderId.substring(0, 8).toUpperCase()),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text("Order Type"),
              subtitle: Text(orderData['orderType'] ?? 'Dine-in'),
            ),
            ListTile(
              leading: const Icon(Icons.payments),
              title: const Text("Total Amount"),
              subtitle: Text("₱${(orderData['totalAmount'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
            const Spacer(),

            if (canCancel)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelOrder(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text("Cancel Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("Back to Map", style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}