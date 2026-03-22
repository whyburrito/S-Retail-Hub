import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/cart_provider.dart';
import '../../models/order.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isCheckingOut = false;

  void _processCheckout(CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || cart.items.isEmpty) return;

    setState(() => isCheckingOut = true);

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      String customerName = "Shopper";
      if (userDoc.exists) {
        customerName = (userDoc.data() as Map<String, dynamic>)['name'] ?? user.email!.split('@')[0];
      }

      final String orderId = FirebaseFirestore.instance.collection('Orders').doc().id;

      List<OrderItem> orderItems = cart.items.values.map((item) => OrderItem(
        productId: item.id,
        name: item.name,
        quantity: item.quantity,
        price: item.price,
      )).toList();

      OrderModel newOrder = OrderModel(
        id: orderId,
        userId: user.uid,
        userName: customerName,
        branchId: "branch_main",
        items: orderItems,
        totalAmount: cart.finalTotal,
        status: "Pending",
        orderType: "Delivery",
        timestamp: DateTime.now(),
        voucherName: cart.appliedVoucherName,
        discountAmount: cart.discountAmount,
      );

      // 💥 THE FIRESTORE TRANSACTION
      await FirebaseFirestore.instance.runTransaction((transaction) async {

        // ==========================================
        // --- PHASE 1: ALL READS FIRST ---
        // ==========================================
        Map<DocumentReference, int> pendingStockUpdates = {};

        // Read 1: Check all product stock
        for (var item in orderItems) {
          DocumentReference productRef = FirebaseFirestore.instance.collection('Products').doc(item.productId);
          DocumentSnapshot productSnapshot = await transaction.get(productRef);

          if (!productSnapshot.exists) throw Exception("Product ${item.name} no longer exists.");

          int currentStock = productSnapshot.get('stockQuantity');
          if (currentStock < item.quantity) throw Exception("Not enough stock for ${item.name}. Only $currentStock left.");

          pendingStockUpdates[productRef] = currentStock - item.quantity;
        }

        // Read 2: Check user's wallet for the voucher BEFORE writing anything
        DocumentSnapshot? latestUserSnap;
        DocumentReference userRef = FirebaseFirestore.instance.collection('Users').doc(user.uid);
        if (cart.appliedVoucherName != null) {
          latestUserSnap = await transaction.get(userRef);
        }


        // ==========================================
        // --- PHASE 2: ALL WRITES ---
        // ==========================================

        // Write 1: Update Stock
        pendingStockUpdates.forEach((ref, newStock) {
          transaction.update(ref, {'stockQuantity': newStock});
        });

        // Write 2: Save the Order
        DocumentReference orderRef = FirebaseFirestore.instance.collection('Orders').doc(orderId);
        transaction.set(orderRef, newOrder.toMap());

        // Write 3: Burn the Voucher
        if (cart.appliedVoucherName != null && latestUserSnap != null) {
          var userData = latestUserSnap.data() as Map<String, dynamic>? ?? {};

          if (userData.containsKey('ownedVouchers')) {
            List vouchers = List.from(userData['ownedVouchers']);
            // Find the specific voucher and remove it
            int vIndex = vouchers.indexWhere((v) => v['name'] == cart.appliedVoucherName);
            if (vIndex != -1) {
              vouchers.removeAt(vIndex);
              transaction.update(userRef, {'ownedVouchers': vouchers});
            }
          }
        }
      });

      // Cleanup & Success
      cart.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checkout successful! Order sent to admin."), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Checkout failed: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isCheckingOut = false);
    }
  }

  // --- NEW: DYNAMIC VOUCHER MENU ---
  void _openVoucherMenu(CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    var data = doc.data() as Map<String, dynamic>? ?? {};
    List owned = data.containsKey('ownedVouchers') ? data['ownedVouchers'] : [];

    if (owned.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You don't have any vouchers! Scan QR codes and visit the Rewards Hub.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent));
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("My Vouchers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                ...owned.map((v) => Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.local_activity, color: Colors.green),
                    title: Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Cap: ₱${v['maxCap']}"),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002244)),
                      onPressed: () {
                        cart.applyVoucher(v['name'], (v['discountPercent'] ?? 0.0).toDouble(), (v['maxCap'] ?? 0.0).toDouble());
                        Navigator.pop(context);
                      },
                      child: const Text("Apply"),
                    ),
                  ),
                )),
              ],
            ),
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Your Cart"), backgroundColor: const Color(0xFF002244)),
      body: cart.items.isEmpty
          ? const Center(child: Text("Your cart is empty.", style: TextStyle(fontSize: 18, color: Colors.grey)))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                var item = cart.items.values.toList()[index];
                return ListTile(
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("₱${item.price.toStringAsFixed(2)} each"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => cart.updateQuantity(item.id, item.quantity - 1)),
                      Text('${item.quantity}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => cart.updateQuantity(item.id, item.quantity + 1)),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // DYNAMIC VOUCHER BUTTON
                  InkWell(
                    onTap: () {
                      if (cart.appliedVoucherName == null) {
                        _openVoucherMenu(cart); // OPENS THE REAL MENU
                      } else {
                        cart.removeVoucher(); // REMOVES IT
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: cart.appliedVoucherName == null ? Colors.grey.shade100 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cart.appliedVoucherName == null ? Colors.grey.shade300 : Colors.green),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_activity, color: cart.appliedVoucherName == null ? Colors.grey : Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cart.appliedVoucherName ?? "Select or enter a voucher",
                              style: TextStyle(fontWeight: FontWeight.bold, color: cart.appliedVoucherName == null ? Colors.black87 : Colors.green),
                            ),
                          ),
                          if (cart.appliedVoucherName != null)
                            const Icon(Icons.cancel, color: Colors.grey)
                          else
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  // SUBTOTAL & DISCOUNT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Subtotal", style: TextStyle(color: Colors.grey)),
                      Text("₱${cart.subtotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (cart.discountAmount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Voucher Discount", style: TextStyle(color: Colors.green)),
                          Text("- ₱${cart.discountAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const Divider(height: 20),

                  // FINAL TOTAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Amount", style: TextStyle(fontSize: 18, color: Colors.grey)),
                      Text("₱${cart.finalTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF002244))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isCheckingOut ? null : () => _processCheckout(cart),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB8860B)),
                      child: isCheckingOut
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SECURE CHECKOUT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}