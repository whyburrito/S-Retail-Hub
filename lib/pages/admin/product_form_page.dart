import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';

class ProductFormPage extends StatefulWidget {
  final Product? productToEdit;

  const ProductFormPage({super.key, this.productToEdit});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController skuCtrl;
  late TextEditingController basePriceCtrl;
  late TextEditingController discountPriceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController descCtrl;
  late TextEditingController supplierCtrl;
  late TextEditingController imageCtrl;

  String selectedCategory = 'Electronics';
  final List<String> categories = ['Electronics', 'Apparel', 'Home & Living', 'Beauty', 'Groceries', 'Toys'];

  bool isSaving = false;
  bool isFeatured = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;

    nameCtrl = TextEditingController(text: p?.name ?? '');
    skuCtrl = TextEditingController(text: p?.sku ?? '');
    basePriceCtrl = TextEditingController(text: p?.basePrice.toString() ?? '');
    discountPriceCtrl = TextEditingController(text: p?.discountedPrice.toString() ?? '');
    stockCtrl = TextEditingController(text: p?.stockQuantity.toString() ?? '');
    descCtrl = TextEditingController(text: p?.description ?? '');
    supplierCtrl = TextEditingController(text: p?.supplier ?? '');
    imageCtrl = TextEditingController(text: p?.imageUrl ?? '');
    isFeatured = p?.isFeatured ?? false;

    if (p != null && categories.contains(p.category)) {
      selectedCategory = p.category;
    }
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      Product newProduct = Product(
        name: nameCtrl.text.trim(),
        sku: skuCtrl.text.trim().toUpperCase(),
        category: selectedCategory,
        basePrice: double.parse(basePriceCtrl.text),
        discountedPrice: double.parse(discountPriceCtrl.text),
        stockQuantity: int.parse(stockCtrl.text),
        description: descCtrl.text.trim(),
        supplier: supplierCtrl.text.trim(),
        imageUrl: imageCtrl.text.trim(),
        dateAdded: widget.productToEdit?.dateAdded ?? DateTime.now(),
        isFeatured: isFeatured,
      );

      Map<String, dynamic> productData = newProduct.toMap();

      if (widget.productToEdit == null) {
        await FirebaseFirestore.instance.collection('Products').add(productData);
      } else {
        await FirebaseFirestore.instance.collection('Products').doc(widget.productToEdit!.id).update(productData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product saved successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.productToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Product" : "Add New Product"),
        backgroundColor: const Color(0xFF002244),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text("Core Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB8860B))),
            const SizedBox(height: 10),
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Product Name (1) *", border: OutlineInputBorder()),
              validator: (val) => val!.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: skuCtrl,
                    decoration: const InputDecoration(labelText: "SKU (2) *", border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: "Category (3)", border: OutlineInputBorder()),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => selectedCategory = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("Feature this product", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Show on the front page of the app"),
              value: isFeatured,
              activeColor: const Color(0xFFB8860B),
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => isFeatured = val),
            ),

            const SizedBox(height: 25),
            const Text("Pricing & Inventory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB8860B))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: basePriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Base Price ₱ (4) *", border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: discountPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Discount Price ₱ (5) *", border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Stock Quantity (6) *", border: OutlineInputBorder()),
              validator: (val) => val!.isEmpty ? "Required" : null,
            ),

            const SizedBox(height: 25),
            const Text("Logistics & Media", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB8860B))),
            const SizedBox(height: 10),
            TextFormField(
              controller: supplierCtrl,
              decoration: const InputDecoration(labelText: "Supplier Name (7)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Description (8)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: imageCtrl,
              decoration: const InputDecoration(labelText: "Direct Image URL (9)", hintText: "https://...", border: OutlineInputBorder()),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text("Note: Date Added (10) is logged automatically.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
            ),

            const SizedBox(height: 30),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB8860B)),
                icon: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.cloud_upload),
                label: Text(isEditing ? "Update Product" : "Save to Cloud Database", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}