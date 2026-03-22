import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final int maxStock;
  int quantity;

  CartItem({required this.id, required this.name, required this.price, required this.maxStock, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  double _discountAmount = 0.0;
  String? _appliedVoucherName;

  Map<String, CartItem> get items => _items;
  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get discountAmount => _discountAmount;
  double get finalTotal => subtotal - _discountAmount;
  String? get appliedVoucherName => _appliedVoucherName;

  void applyVoucher(String name, double percentOff, double maxCap) {
    double calculatedDiscount = subtotal * percentOff;
    _discountAmount = calculatedDiscount > maxCap ? maxCap : calculatedDiscount;
    _appliedVoucherName = name;
    notifyListeners();
  }

  void removeVoucher() {
    _discountAmount = 0.0;
    _appliedVoucherName = null;
    notifyListeners();
  }

  void addItem(String id, String name, double price, int maxStock) {
    if (_items.containsKey(id)) {
      if (_items[id]!.quantity < maxStock) {
        _items[id]!.quantity++;
      }
    } else {
      if (maxStock > 0) {
        _items[id] = CartItem(id: id, name: name, price: price, maxStock: maxStock);
      }
    }
    _recalculateVoucher();
    notifyListeners();
  }

  void updateQuantity(String id, int newQuantity) {
    if (!_items.containsKey(id)) return;
    if (newQuantity <= 0) {
      _items.remove(id);
    } else if (newQuantity <= _items[id]!.maxStock) {
      _items[id]!.quantity = newQuantity;
    }
    _recalculateVoucher();
    notifyListeners();
  }

  void _recalculateVoucher() {
    if (_appliedVoucherName != null && subtotal == 0) removeVoucher();
  }

  void clear() {
    _items.clear();
    removeVoucher();
    notifyListeners();
  }
}