import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'restaurant_detail/restaurant_detail_dashboard.dart';

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});
  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    loadRestaurants();
  }

  void loadRestaurants() {
    FirebaseFirestore.instance.collection("restaurants").snapshots().listen((snapshot) {
      final newMarkers = snapshot.docs.map((doc) {
        final data = doc.data();

        double lat = data["latitude"] ?? 0.0;
        double lng = data["longitude"] ?? 0.0;
        bool isSponsored = data['isSponsored'] == true;
        String imageUrl = data['imageUrl'] ?? '';

        return Marker(
          point: LatLng(lat, lng),
          width: 160, // Widened to safely fit the new card layout
          height: 85,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => RestaurantDetailDashboard(restaurantId: doc.id, restaurantData: data),
            )),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // THE NEW CLEAN CARD UI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSponsored ? Colors.amber.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: isSponsored ? Border.all(color: Colors.amber, width: 1.5) : null,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left Side: The Restaurant Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                          width: 24,
                          height: 24,
                          color: Colors.grey.shade200,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/foodika_logo.png', fit: BoxFit.cover),
                          )
                              : Image.asset('assets/images/foodika_logo.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Right Side: The Text and Rating
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data["name"] ?? "Unknown",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: isSponsored ? Colors.orange.shade900 : Colors.black
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (data['avgRating'] != null && data['avgRating'] > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 10),
                                const SizedBox(width: 2),
                                Text("${data['avgRating']}", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 2),
                                Text("(${data['reviewCount'] ?? '0'})", style: const TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // CLEAN TEARDROP PIN
                Icon(
                  Icons.location_on,
                  color: isSponsored ? Colors.amber : const Color(0xFFE46A3E),
                  size: isSponsored ? 45 : 35,
                  shadows: const [Shadow(color: Colors.black45, blurRadius: 5, offset: Offset(0, 2))],
                ),
              ],
            ),
          ),
        );
      }).toList();

      if (mounted) setState(() => markers = newMarkers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(14.6291, 121.0419),
        initialZoom: 16.0,
        interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', userAgentPackageName: 'com.foodika.app'),
        MarkerLayer(markers: markers),
      ],
    );
  }
}