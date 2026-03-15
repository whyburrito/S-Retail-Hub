import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'user_restaurant_detail_page.dart';
import 'qr_scanner_page.dart';

class UserMapPage extends StatefulWidget {
  final String searchQuery;
  final String activeFilter;

  const UserMapPage({
    super.key,
    required this.searchQuery,
    required this.activeFilter,
  });

  @override
  State<UserMapPage> createState() => _UserMapPageState();
}

class _UserMapPageState extends State<UserMapPage> {
  List<Marker> markers = [];
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _listenToRestaurants();
    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position initialPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(initialPosition.latitude, initialPosition.longitude);
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _listenToRestaurants() {
    FirebaseFirestore.instance.collection('restaurants').snapshots().listen((snapshot) {
      _updateMarkers(snapshot.docs);
    });
  }

  void _updateMarkers(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final query = widget.searchQuery.toLowerCase().trim();

    final newMarkers = docs.where((doc) {
      final data = doc.data();
      final String name = (data['name'] ?? '').toString().toLowerCase();
      final String category = (data['cuisine'] ?? '').toString().toLowerCase();
      final String desc = (data['description'] ?? '').toString().toLowerCase();

      bool matchesSearch = query.isEmpty ||
          name.contains(query) ||
          desc.contains(query) ||
          category.contains(query);

      bool matchesFilter = true;
      if (widget.activeFilter != "All") {
        if (widget.activeFilter == "Budget") {
          matchesFilter = data['priceRange'] == '₱ (Budget)';
        } else if (widget.activeFilter == "Free WiFi") {
          matchesFilter = data['hasWiFi'] == true;
        } else {
          matchesFilter = category == widget.activeFilter.toLowerCase();
        }
      }

      return matchesSearch && matchesFilter;
    }).map((doc) {
      final data = doc.data();
      bool isSponsored = data['isSponsored'] == true;
      String imageUrl = data['imageUrl'] ?? '';

      return Marker(
        point: LatLng(data["latitude"], data["longitude"]),
        width: 160, // Widened to fit the new image card layout safely
        height: 85,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => _showRestaurantPreview(context, doc.id, data),
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
                    // Left Side: The Restaurant Image / Logo Fallback
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
                      crossAxisAlignment: CrossAxisAlignment.start, // Left align text next to image
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
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2), // Small gap before the pin
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

    if (mounted) {
      setState(() {
        markers = newMarkers;
      });
    }
  }

  void _showRestaurantPreview(BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                        ? Image.network(data['imageUrl'], width: 80, height: 80, fit: BoxFit.cover)
                        : Container(width: 80, height: 80, color: Colors.grey[200], child: Image.asset('assets/images/foodika_logo.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data["name"] ?? "Unknown", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(data["cuisine"] ?? "Various", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text("${data['avgRating'] ?? 0.0} (${data['reviewCount'] ?? 0} reviews)"),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE46A3E), padding: const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserRestaurantDetailPage(restaurantId: docId, data: data)));
                  },
                  child: const Text("View Details", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant UserMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery || oldWidget.activeFilter != widget.activeFilter) {
      FirebaseFirestore.instance.collection('restaurants').get().then((snapshot) {
        _updateMarkers(snapshot.docs);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> allMarkers = List.from(markers);
    if (_currentLocation != null) {
      allMarkers.add(
          Marker(
            point: _currentLocation!,
            width: 50,
            height: 50,
            alignment: Alignment.topCenter, // Keep alignment consistent!
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(10)), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                  child: const Text("You are here", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ),
                const Icon(Icons.person_pin_circle, color: Colors.green, size: 45),
              ],
            ),
          )
      );
    }

    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(14.6291, 121.0419),
          initialZoom: 15.0,
          interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', userAgentPackageName: 'com.foodika.app'),
          MarkerLayer(markers: allMarkers),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: "btn_scan",
              backgroundColor: Colors.amber.shade700,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MockQRScannerPage())),
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text("Scan to Earn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            FloatingActionButton(
              heroTag: "btn_gps",
              backgroundColor: Colors.white,
              onPressed: () {
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 16.0);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fetching GPS... please wait.")));
                }
              },
              child: const Icon(Icons.my_location, color: Color(0xFFE46A3E)),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}