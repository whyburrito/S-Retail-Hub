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

  Map<String, CartItem> get items => _items;
  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.values.fold(0, (sum, item) => sum + (item.price * item.quantity));

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
    notifyListeners();
  }

  void updateQuantity(String id, int newQuantity) {
    if (!_items.containsKey(id)) return;

    if (newQuantity <= 0) {
      _items.remove(id);
    } else if (newQuantity <= _items[id]!.maxStock) {
      _items[id]!.quantity = newQuantity;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}