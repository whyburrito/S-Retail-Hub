import 'package:flutter/material.dart';
import 'admin_map_page.dart';
import 'restaurant_list_page.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'add_restaurant_page.dart'; // Add this import

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int selectedIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> pages = [
    const AdminMapPage(),
    const RestaurantListPage(),
  ];

  final List<String> titles = [
    "Admin Map View",
    "Restaurant Management",
  ];

  void logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Logout", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        backgroundColor: const Color(0xFFE46A3E),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFE46A3E)),
              accountName: Text("Admin Panel", style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text("admin@foodika.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, color: Color(0xFFE46A3E), size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text("Map View"),
              selected: selectedIndex == 0,
              onTap: () {
                setState(() => selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text("Restaurant Management"),
              selected: selectedIndex == 1,
              onTap: () {
                setState(() => selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                onPressed: logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Log Out", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      body: pages[selectedIndex],
      // The button is now controlled by the dashboard
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE46A3E),
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRestaurantPage())
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}