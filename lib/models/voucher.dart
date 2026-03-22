class VoucherModel {
  String? id;
  String name;
  double discountPercent;
  double maxCap;
  int costInPoints;

  VoucherModel({
    this.id,
    required this.name,
    required this.discountPercent,
    required this.maxCap,
    required this.costInPoints,
  });

  factory VoucherModel.fromMap(Map<String, dynamic> data, String documentId) {
    return VoucherModel(
      id: documentId,
      name: data['name'] ?? '',
      discountPercent: (data['discountPercent'] ?? 0.0).toDouble(),
      maxCap: (data['maxCap'] ?? 0.0).toDouble(),
      costInPoints: data['costInPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'discountPercent': discountPercent,
      'maxCap': maxCap,
      'costInPoints': costInPoints,
    };
  }
}