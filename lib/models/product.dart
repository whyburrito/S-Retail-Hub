import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String? id;
  String name;
  String sku;
  String category;
  double basePrice;
  double discountedPrice;
  int stockQuantity;
  String description;
  String supplier;
  DateTime dateAdded;
  String imageUrl;
  bool isFeatured;

  Product({
    this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.basePrice,
    required this.discountedPrice,
    required this.stockQuantity,
    required this.description,
    required this.supplier,
    required this.dateAdded,
    required this.imageUrl,
    this.isFeatured = false,
  });

  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    return Product(
      id: documentId,
      name: data['name'] ?? '',
      sku: data['sku'] ?? '',
      category: data['category'] ?? '',
      basePrice: (data['basePrice'] ?? 0.0).toDouble(),
      discountedPrice: (data['discountedPrice'] ?? 0.0).toDouble(),
      stockQuantity: data['stockQuantity'] ?? 0,
      description: data['description'] ?? '',
      supplier: data['supplier'] ?? '',
      dateAdded: (data['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] ?? '',
      isFeatured: data['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sku': sku,
      'category': category,
      'basePrice': basePrice,
      'discountedPrice': discountedPrice,
      'stockQuantity': stockQuantity,
      'description': description,
      'supplier': supplier,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'imageUrl': imageUrl,
      'isFeatured': isFeatured,
    };
  }
}