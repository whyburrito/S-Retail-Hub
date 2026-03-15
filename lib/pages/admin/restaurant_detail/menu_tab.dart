import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MenuTab extends StatelessWidget {
  final String restaurantId;
  const MenuTab({super.key, required this.restaurantId});

  // Accepts an optional item for editing
  void _showMenuItemDialog(BuildContext context, {DocumentSnapshot? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _MenuItemForm(restaurantId: restaurantId, item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMenuItemDialog(context), // Add Mode
        backgroundColor: const Color(0xFFE46A3E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .collection('menu')
            .orderBy('category')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(child: Text("No menu items added yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              var data = item.data() as Map<String, dynamic>;

              String? imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] : null;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : null,
                    child: (imageUrl == null || imageUrl.isEmpty)
                        ? const Icon(Icons.fastfood, color: Colors.grey)
                        : null,
                  ),
                  title: Text(data['name'] ?? 'Unnamed Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['category']} • ₱${data['price']}\n${data['description'] ?? ''}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showMenuItemDialog(context, item: item), // Edit Mode
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Item"),
                              content: const Text("Remove this from the menu?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text("Delete", style: TextStyle(color: Colors.red))
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            // Safely try to delete from storage if it's a firebase file
                            if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.contains('firebase')) {
                              try {
                                await FirebaseStorage.instance.refFromURL(imageUrl).delete();
                              } catch (_) {}
                            }
                            item.reference.delete();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MenuItemForm extends StatefulWidget {
  final String restaurantId;
  final DocumentSnapshot? item;

  const _MenuItemForm({required this.restaurantId, this.item});

  @override
  State<_MenuItemForm> createState() => _MenuItemFormState();
}

class _MenuItemFormState extends State<_MenuItemForm> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;

  String selectedCategory = 'Mains';
  final List<String> categories = ['Appetizers', 'Mains', 'Desserts', 'Drinks', 'Sides'];

  File? selectedImage;
  String? imageUrlInput; // NEW: Holds the pasted URL
  String? existingImageUrl;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.item?.data() as Map<String, dynamic>?;

    nameController = TextEditingController(text: data?['name'] ?? '');
    priceController = TextEditingController(text: data?['price']?.toString() ?? '');
    descriptionController = TextEditingController(text: data?['description'] ?? '');

    if (data != null) {
      if (categories.contains(data['category'])) selectedCategory = data['category'];
      existingImageUrl = data['imageUrl'];
    }
  }

  // ========================================================
  // NEW: FILE OR URL SELECTOR DIALOG
  // ========================================================
  void _showImageSourceDialog() {
    TextEditingController urlController = TextEditingController(text: imageUrlInput ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFE46A3E)),
              title: const Text("Upload from Device"),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    selectedImage = File(pickedFile.path);
                    imageUrlInput = null; // Clear URL if file is selected
                  });
                }
              },
            ),
            const Divider(),
            const Text("OR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: "Paste Image URL", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                imageUrlInput = urlController.text.trim();
                selectedImage = null; // Clear file if URL is pasted
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE46A3E), foregroundColor: Colors.white),
            child: const Text("Use URL"),
          ),
        ],
      ),
    );
  }

  void saveItem() async {
    if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Price are required.")));
      return;
    }

    setState(() => isSaving = true);
    String finalImageUrl = existingImageUrl ?? "";

    try {
      // Prioritize the File upload, fallback to the URL paste, keep existing if neither changed
      if (selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref("restaurants/${widget.restaurantId}/menu/${DateTime.now().millisecondsSinceEpoch}.jpg");
        await ref.putFile(selectedImage!);
        finalImageUrl = await ref.getDownloadURL();
      } else if (imageUrlInput != null && imageUrlInput!.isNotEmpty) {
        finalImageUrl = imageUrlInput!;
      }

      final itemData = {
        'name': nameController.text.trim(),
        'price': double.tryParse(priceController.text) ?? 0.0,
        'description': descriptionController.text.trim(),
        'category': selectedCategory,
        'imageUrl': finalImageUrl,
        'isAvailable': true,
      };

      if (widget.item == null) {
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.restaurantId)
            .collection('menu')
            .add(itemData);

        await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('history').add({
          'action': 'Menu Item Added',
          'details': 'Added ${itemData['name']} to $selectedCategory',
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await widget.item!.reference.update(itemData);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasImageReady = selectedImage != null || (imageUrlInput != null && imageUrlInput!.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item == null ? "Add Menu Item" : "Edit Menu Item", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name *")),
          TextField(
            controller: priceController,
            decoration: const InputDecoration(labelText: "Price (₱) *"),
            keyboardType: TextInputType.number,
          ),
          TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description / Ingredients")),
          const SizedBox(height: 15),

          DropdownButtonFormField<String>(
            value: selectedCategory,
            isExpanded: true,
            items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            onChanged: (val) => setState(() => selectedCategory = val!),
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.image),
                label: Text(hasImageReady
                    ? "New Image Ready"
                    : (existingImageUrl != null && existingImageUrl!.isNotEmpty)
                    ? "Change Image"
                    : "Add Image (Opt.)"
                ),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : saveItem,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : Text(widget.item == null ? "Save Item" : "Update Item"),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}