import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddRestaurantPage extends StatefulWidget {
  const AddRestaurantPage({super.key});

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  bool isSponsored = false;
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  final contactController = TextEditingController();
  final hoursController = TextEditingController();

  String selectedCuisine = 'Filipino';
  final List<String> cuisines = ['Filipino', 'Fast Food', 'Cafe', 'Dessert', 'Street Food', 'Healthy', 'Other'];

  String selectedPrice = '₱ (Budget)';
  final List<String> prices = ['₱ (Budget)', '₱₱ (Moderate)', '₱₱₱ (Expensive)'];

  bool acceptsGCash = false;
  bool acceptsCards = false;
  bool hasParking = false;
  bool hasWiFi = false;

  LatLng? selectedLocation;
  File? selectedImage;
  String? imageUrlInput; // Fallback for direct URL
  bool isSaving = false;

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

  void saveRestaurant() async {
    if (nameController.text.isEmpty || selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Map Location are required!")));
      return;
    }

    setState(() => isSaving = true);

    try {
      String? finalImageUrl;

      if (selectedImage != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance.ref().child('restaurant_images').child('$fileName.jpg');
        await storageRef.putFile(selectedImage!);
        finalImageUrl = await storageRef.getDownloadURL();
      } else if (imageUrlInput != null && imageUrlInput!.isNotEmpty) {
        finalImageUrl = imageUrlInput;
      }

      await FirebaseFirestore.instance.collection('restaurants').add({
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
        'latitude': selectedLocation!.latitude,
        'longitude': selectedLocation!.longitude,
        'imageUrl': finalImageUrl,
        'avgRating': 0.0,
        'reviewCount': 0,
        'totalRatingSum': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restaurant Added Successfully!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasImageReady = selectedImage != null || (imageUrlInput != null && imageUrlInput!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Restaurant"), backgroundColor: const Color(0xFFE46A3E), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RESTORED: Basic Details Section
            const Text("Basic Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Restaurant Name")),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: "Address")),
            TextField(controller: contactController, decoration: const InputDecoration(labelText: "Contact Number"), keyboardType: TextInputType.phone),

            // RESTORED: The Clock TimePicker
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

            // RESTORED: Clean Description Field (No weird floating icon)
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description"), maxLines: 2),
            const SizedBox(height: 20),

            // RESTORED: Categorization Section
            const Text("Categorization", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedCuisine,
              decoration: const InputDecoration(labelText: "Cuisine / Category"),
              items: cuisines.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => selectedCuisine = val!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedPrice,
              decoration: const InputDecoration(labelText: "Price Range"),
              items: prices.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => setState(() => selectedPrice = val!),
            ),
            const SizedBox(height: 20),

            // RESTORED: Features & Payments
            const Text("Features & Payments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            SwitchListTile(title: const Text("Accepts GCash"), value: acceptsGCash, activeColor: const Color(0xFFE46A3E), onChanged: (val) => setState(() => acceptsGCash = val)),
            SwitchListTile(title: const Text("Accepts Credit/Debit Cards"), value: acceptsCards, activeColor: const Color(0xFFE46A3E), onChanged: (val) => setState(() => acceptsCards = val)),
            SwitchListTile(title: const Text("Has Parking Space"), value: hasParking, activeColor: const Color(0xFFE46A3E), onChanged: (val) => setState(() => hasParking = val)),
            SwitchListTile(title: const Text("Free WiFi"), value: hasWiFi, activeColor: const Color(0xFFE46A3E), onChanged: (val) => setState(() => hasWiFi = val)),
            const SizedBox(height: 20),

            // B2B SPONSORED TOGGLE (Placed cleanly above Location)
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

            // RESTORED: Location Section
            const Text("Location & Image", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE46A3E))),
            const SizedBox(height: 10),
            const Text("Tap the map to set the location *", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(14.6291, 121.0419), // Default QC
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  onTap: (tapPosition, point) => setState(() => selectedLocation = point),
                ),
                children: [
                  TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', userAgentPackageName: 'com.foodika.app'),
                  if (selectedLocation != null)
                    MarkerLayer(markers: [
                      Marker(
                          point: selectedLocation!,
                          width: 50,
                          height: 50,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40)
                      )
                    ]),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // The URL / Image Picker Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.image),
                  label: Text(hasImageReady ? "Image Ready" : "Add Image (Opt.)"),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : saveRestaurant,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                  child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Save Place"),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}