import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'inventory_page.dart';
import 'live_orders_page.dart';
import 'admin_vouchers_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int selectedIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> pages = [
    const InventoryPage(),
    const LiveOrdersPage(),
    const AdminVouchersPage(),
  ];

  final List<String> titles = [
    "Inventory Management",
    "Live Orders Feed",
    "Voucher Management",
  ];

  void logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout", style: TextStyle(color: Color(0xFF002244))),
        content: const Text("Are you sure you want to sign out of the Admin portal?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex], style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        // NEW BURGER ICON WITH LIVE BADGE
        leading: Builder(
            builder: (context) {
              return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('Orders').where('status', whereIn: ['Pending', 'Preparing']).snapshots(),
                  builder: (context, snapshot) {
                    int pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                        if (pendingCount > 0)
                          Positioned(
                            right: 8,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    );
                  }
              );
            }
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF002244)),
              accountName: Text("S RETAIL STORE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFFB8860B))),
              accountEmail: Text("Administrator Portal", style: TextStyle(color: Colors.white70)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, color: Color(0xFFB8860B), size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF002244)),
              title: const Text("Inventory", style: TextStyle(fontWeight: FontWeight.bold)),
              selected: selectedIndex == 0,
              selectedTileColor: Colors.grey.shade200,
              onTap: () { setState(() => selectedIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFF002244)),
              title: const Text("Live Orders", style: TextStyle(fontWeight: FontWeight.bold)),
              selected: selectedIndex == 1,
              selectedTileColor: Colors.grey.shade200,
              // NEW DRAWER LIVE BADGE
              trailing: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('Orders').where('status', whereIn: ['Pending', 'Preparing']).snapshots(),
                  builder: (context, snapshot) {
                    int pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    if (pendingCount == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    );
                  }
              ),
              onTap: () { setState(() => selectedIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.local_activity_outlined, color: Color(0xFF002244)),
              title: const Text("Vouchers", style: TextStyle(fontWeight: FontWeight.bold)),
              selected: selectedIndex == 2,
              selectedTileColor: Colors.grey.shade200,
              onTap: () { setState(() => selectedIndex = 2); Navigator.pop(context); },
            ),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                onPressed: logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            ),
          ],
        ),
      ),
      body: pages[selectedIndex],
    );
  }
}