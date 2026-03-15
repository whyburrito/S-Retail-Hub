import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditRestaurantTab extends StatefulWidget {
  final String restaurantId;
  final Map<String, dynamic> data;
  const EditRestaurantTab({super.key, required this.restaurantId, required this.data});

  @override
  State<EditRestaurantTab> createState() => _EditRestaurantTabState();
}

class _EditRestaurantTabState extends State<EditRestaurantTab> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController descriptionController;
  late TextEditingController contactController;
  late TextEditingController hoursController;

  String selectedCuisine = 'Filipino';
  final List<String> cuisines = ['Filipino', 'Fast Food', 'Cafe', 'Dessert', 'Street Food', 'Healthy', 'Other'];

  String selectedPrice = '₱ (Budget)';
  final List<String> prices = ['₱ (Budget)', '₱₱ (Moderate)', '₱₱₱ (Expensive)'];

  bool acceptsGCash = false;
  bool acceptsCards = false;
  bool hasParking = false;
  bool hasWiFi = false;
  bool isSponsored = false; // B2B Toggle

  LatLng? originalLocation;
  LatLng? selectedLocation;
  File? selectedImage;
  String? imageUrlInput; // Fallback for direct URL
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.data['name']);
    addressController = TextEditingController(text: widget.data['address']);
    descriptionController = TextEditingController(text: widget.data['description']);
    contactController = TextEditingController(text: widget.data['contactNumber']);
    hoursController = TextEditingController(text: widget.data['operatingHours']);

    if (cuisines.contains(widget.data['cuisine'])) selectedCuisine = widget.data['cuisine'];
    if (prices.contains(widget.data['priceRange'])) selectedPrice = widget.data['priceRange'];

    acceptsGCash = widget.data['acceptsGCash'] ?? false;
    acceptsCards = widget.data['acceptsCards'] ?? false;
    hasParking = widget.data['hasParking'] ?? false;
    hasWiFi = widget.data['hasWiFi'] ?? false;
    isSponsored = widget.data['isSponsored'] ?? false;

    if (widget.data['latitude'] != null && widget.data['longitude'] != null) {
      originalLocation = LatLng(widget.data['latitude'], widget.data['longitude']);
    }
  }

  // Image Source Dialog (File vs URL)
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
                    imageUrlInput = null;
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
                selectedImage = null;
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

  void applyChanges() async {
    setState(() => isSaving = true);

    try {
      String? finalImageUrl = widget.data['imageUrl'];

      if (selectedImage != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child('restaurant_images').child('$fileName.jpg');
        await storageRef.putFile(selectedImage!);
        finalImageUrl = await storageRef.getDownloadURL();
      } else if (imageUrlInput != null && imageUrlInput!.isNotEmpty) {
        finalImageUrl = imageUrlInput;
      }

      await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).update({
        'name': nameController.text.trim(),
        'address': addressController.text.trim(),
        'description': descriptionController.text.trim(),
        'contactNumber': contactController.text.trim(),
        'operatingHours': hoursController.text.trim(),
        'cuisine': selectedCuisine,
        'priceRange': selectedPrice,
        'acceptsGCash': acceptsGCash,
        'acceptsCards': acceptsCards,
        'hasParking': hasParking,
        'hasWiFi': hasWiFi,
        'isSponsored': isSponsored,
        'latitude': selectedLocation?.latitude ?? originalLocation?.latitude,
        'longitude': selectedLocation?.longitude ?? originalLocation?.longitude,
        'imageUrl': finalImageUrl,
      });

      await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).collection('history').add({
        'action': "Profile Updated",
        'details': "Admin updated restaurant details",
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes Saved!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasMoved = selectedLocation != null && selectedLocation != originalLocation;
    bool hasImageReady = selectedImage != null || (imageUrlInput != null && imageUrlInput!.isNotEmpty);
    String existingImage = widget.data['imageUrl'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Image Preview Header
          if (hasImageReady || existingImage.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey.shade200,
                  image: DecorationImage(
                    image: selectedImage != null
                        ? FileImage(selectedImage!) as ImageProvider
                        : NetworkImage(imageUrlInput?.isNotEmpty == true ? imageUrlInput! : existingImage),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
                    onPressed: _showImageSourceDialog,
                  ),
                ),
              ),
            ),

          if (!hasImageReady && existingImage.isEmpty)
            Center(
              child: ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Add Main Image"),
              ),
            ),
          const SizedBox(height: 10),

          // 2. RESTORED: Basic Details Section
          const Text("Basic Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: "Restaurant Name")),
          TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
          TextField(controller: contactController, decoration: const InputDecoration(labelText: "Contact Number"), keyboardType: TextInputType.phone),

          // RESTORED: Clock Picker!
          TextField(
            controller: hoursController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: "Operating Hours",
              suffixIcon: Icon(Icons.access_time, color: Color(0xFFE46A3E)),
            ),
            onTap: () async {
              TimeOfDay? openTime = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 8, minute: 0),
                helpText: "SELECT OPENING TIME",
              );
              if (openTime == null) return;

              if (context.mounted) {
                TimeOfDay? closeTime = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 22, minute: 0),
                  helpText: "SELECT CLOSING TIME",
                );
                if (closeTime == null) return;

                if (context.mounted) {
                  setState(() {
                    hoursController.text = "${openTime.format(context)} - ${closeTime.format(context)}";
                  });
                }
              }
            },
          ),

          TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
          const SizedBox(height: 20),

          // 3. RESTORED: Categorization Section
          const Text("Categorization", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
              value: selectedCuisine,
              decoration: const InputDecoration(labelText: "Cuisine / Category"),
              items: cuisines.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => setState(() => selectedCuisine = val!)
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
              value: selectedPrice,
              decoration: const InputDecoration(labelText: "Price Range"),
              items: prices.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => setState(() => selectedPrice = val!)
          ),
          const SizedBox(height: 20),

          // 4. RESTORED: Features & Payments
          const Text("Features & Payments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
          SwitchListTile(title: const Text("Accepts GCash"), value: acceptsGCash, activeColor: const Color(0xFFE46A3E), onChanged: (val) => setState(() => acceptsGCash = val)),
          SwitchListTile(title: const Text("Accepts Credit/Debit Cards"), value: acceptsCards, activeColor: const Color(0xFFE46A3E), onChanged: (val) => setState(() => acceptsCards = val)),
          SwitchListTile(title: const Text("Has Parking Space"), value: hasParking, activeColor: const Color(0xFFE46A3E), onChanged: (val) => setState(() => hasParking = val)),
          SwitchListTile(title: const Text("Free WiFi"), value: hasWiFi, activeColor: const Color(0xFFE46A3E), onChanged: (val) => setState(() => hasWiFi = val)),
          const SizedBox(height: 20),

          // B2B SPONSORED TOGGLE
          Container(
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber)),
            child: SwitchListTile(
              title: const Text("Sponsored Ad Placement (B2B)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              subtitle: const Text("Highlights restaurant on the map with a gold star"),
              value: isSponsored,
              activeColor: Colors.orange,
              onChanged: (val) => setState(() => isSponsored = val),
            ),
          ),
          const SizedBox(height: 20),

          // 5. RESTORED: Update Location
          const Text("Update Location", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
          const SizedBox(height: 10),
          const Text("Tap anywhere to update pin. Red is original, Blue is new.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            height: 250,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: originalLocation ?? const LatLng(14.6291, 121.0419),
                initialZoom: 16.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                onTap: (tapPosition, point) => setState(() => selectedLocation = point),
              ),
              children: [
                TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', userAgentPackageName: 'com.foodika.app'),
                MarkerLayer(
                  markers: [
                    if (originalLocation != null)
                      Marker(
                          point: originalLocation!,
                          width: 50,
                          height: 50,
                          alignment: Alignment.topCenter, // NEW
                          child: Icon(Icons.location_on, color: hasMoved ? Colors.red.withOpacity(0.4) : Colors.red, size: 40)
                      ),
                    if (hasMoved)
                      Marker(
                          point: selectedLocation!,
                          width: 50,
                          height: 50,
                          alignment: Alignment.topCenter, // NEW
                          child: const Icon(Icons.location_on, color: Colors.blue, size: 40)
                      )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Buttons
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Discard"))),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : applyChanges,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Apply Changes", style: TextStyle(color: Colors.white)),
                  )
              ),
            ],
          )
        ],
      ),
    );
  }
}