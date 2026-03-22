import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  String productId;
  String name;
  int quantity;
  double price;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 1,
      price: (data['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}

class OrderModel {
  String? id;
  String userId;
  String branchId;
  List<OrderItem> items;
  double totalAmount;
  String status;
  String orderType;
  DateTime timestamp;
  String? voucherName;
  double discountAmount;
  String? userName;

  OrderModel({
    this.id,
    required this.userId,
    required this.branchId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderType,
    required this.timestamp,
    this.voucherName,
    this.discountAmount = 0.0,
    this.userName,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String documentId) {
    var itemsList = data['items'] as List? ?? [];
    List<OrderItem> mappedItems = itemsList.map((item) => OrderItem.fromMap(item)).toList();

    return OrderModel(
      id: documentId,
      userId: data['userId'] ?? '',
      branchId: data['branchId'] ?? '',
      items: mappedItems,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Pending',
      orderType: data['orderType'] ?? 'In-Store Pickup',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      voucherName: data['voucherName'],
      discountAmount: (data['discountAmount'] ?? 0.0).toDouble(),
      userName: data['userName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'branchId': branchId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderType': orderType,
      'timestamp': Timestamp.fromDate(timestamp),
      'voucherName': voucherName,
      'discountAmount': discountAmount,
      'userName': userName,
    };
  }
}