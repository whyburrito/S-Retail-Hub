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
      // Create a master order ID
      final String orderId = FirebaseFirestore.instance.collection('Orders').doc().id;

      // Convert CartItems to OrderItems
      List<OrderItem> orderItems = cart.items.values.map((item) => OrderItem(
        productId: item.id,
        name: item.name,
        quantity: item.quantity,
        price: item.price,
      )).toList();

      // Create the Order Model Blueprint
      OrderModel newOrder = OrderModel(
        id: orderId,
        userId: user.uid,
        branchId: "branch_main",
        items: orderItems,
        totalAmount: cart.finalTotal,
        status: "Pending",
        orderType: "Delivery",
        timestamp: DateTime.now(),
        voucherName: cart.appliedVoucherName,
        discountAmount: cart.discountAmount,
      );

      // 💥 THE FIRESTORE TRANSACTION (Crucial for Rubric)
      // This ensures stock is deducted safely and the order is created at the exact same time.
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Read all products to ensure enough stock exists
        for (var item in orderItems) {
          DocumentReference productRef = FirebaseFirestore.instance.collection('Products').doc(item.productId);
          DocumentSnapshot productSnapshot = await transaction.get(productRef);

          if (!productSnapshot.exists) throw Exception("Product ${item.name} no longer exists.");

          int currentStock = productSnapshot.get('stockQuantity');
          if (currentStock < item.quantity) throw Exception("Not enough stock for ${item.name}. Only $currentStock left.");

          // Deduct stock
          transaction.update(productRef, {'stockQuantity': currentStock - item.quantity});
        }

        // 2. Write the new Order to the master node
        DocumentReference orderRef = FirebaseFirestore.instance.collection('Orders').doc(orderId);
        transaction.set(orderRef, newOrder.toMap());
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
                  InkWell(
                    onTap: () {
                      if (cart.appliedVoucherName == null) {
                        cart.applyVoucher("50% OFF (Cap ₱500)", 0.50, 500.0);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Voucher Applied!"), backgroundColor: Colors.green));
                      } else {
                        cart.removeVoucher();
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
                            const Icon(Icons.check_circle, color: Colors.green)
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