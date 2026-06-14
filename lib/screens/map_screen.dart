import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/filter_bar.dart';
import 'property_detail_screen.dart';
import 'profile_screen.dart';
import '../services/favorites_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> properties = [];
  List<Map<String, dynamic>> filteredProperties = [];
  bool isLoading = true;

  // Filter values
  int? currentMaxPrice;
  String? currentRoomType;
  bool? currentHasWifi;

  // UFS Main Campus coordinates
  static const LatLng ufsCampus = LatLng(-29.1089, 26.1883);

  @override
  void initState() {
    super.initState();
    _loadAllProperties();
  }

  Future<void> _loadAllProperties() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await supabase
          .from('properties')
          .select('*');
      
      setState(() {
        properties = List<Map<String, dynamic>>.from(response);
        filteredProperties = properties;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading properties: $e');
      setState(() {
        isLoading = false;
      });
      _showError('Failed to load properties');
    }
  }

  Future<void> _applyFilters(int? maxPrice, String? roomType, bool? hasWifi) async {
    setState(() {
      currentMaxPrice = maxPrice;
      currentRoomType = roomType;
      currentHasWifi = hasWifi;
      isLoading = true;
    });

    try {
      // Start with all property IDs that have available rooms
      var query = supabase
          .from('rooms')
          .select('property_id')
          .eq('is_available', true);

      // Apply price filter
      if (maxPrice != null) {
        query = query.lte('price_per_month', maxPrice);
      }

      // Apply room type filter
      if (roomType != null) {
        query = query.eq('room_type', roomType);
      }

      // Apply WiFi filter
      if (hasWifi != null && hasWifi == true) {
        query = query.eq('has_wifi', true);
      }

      final roomsResponse = await query;
      
      // Extract unique property IDs
      final propertyIds = roomsResponse
          .map<String>((room) => room['property_id'].toString())
          .toSet()
          .toList();

      if (propertyIds.isEmpty) {
        setState(() {
          filteredProperties = [];
          isLoading = false;
        });
        return;
      }

      // Fetch properties that match the filtered room IDs
      final propertiesResponse = await supabase
          .from('properties')
          .select('*')
          .inFilter('id', propertyIds);

      setState(() {
        filteredProperties = List<Map<String, dynamic>>.from(propertiesResponse);
        isLoading = false;
      });
    } catch (e) {
      print('Error applying filters: $e');
      setState(() {
        isLoading = false;
      });
      _showError('Failed to apply filters');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ============================================
  // THIS IS THE METHOD THAT WAS MISSING
  // ============================================
  void _showPropertyDetails(Map<String, dynamic> property) async {
    final propertyId = property['id'].toString();
    final favoritesService = FavoritesService();
    bool isFavorited = await favoritesService.isFavorited(propertyId);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        property['name'] ?? 'Unknown Property',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited ? Colors.red : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () async {
                        if (isFavorited) {
                          await favoritesService.removeFavorite(propertyId);
                          setState(() {
                            isFavorited = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Removed from favorites'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        } else {
                          await favoritesService.addFavorite(propertyId);
                          setState(() {
                            isFavorited = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to favorites'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property['address'] ?? 'Address not available',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (property['near_campus'] != null)
                  Chip(
                    label: Text(property['near_campus']),
                    backgroundColor: Colors.blue.shade100,
                  ),
                const SizedBox(height: 16),
                if (property['description'] != null)
                  Text(property['description']),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PropertyDetailScreen(
                            propertyId: propertyId,
                            propertyName: property['name'] ?? 'Property Details',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View Available Rooms'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BloemFinder'),
        backgroundColor: Colors.blue,  // Changed from grey to blue for better look
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          if (filteredProperties.length != properties.length)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${filteredProperties.length} of ${properties.length}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          FilterBar(
            onFilterChanged: _applyFilters,
          ),
          
          // Map
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: ufsCampus,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.bloemfinder.app',
                      ),
                      MarkerLayer(
                        markers: filteredProperties.map((property) {
                          return Marker(
                            width: 50,
                            height: 50,
                            point: LatLng(
                              property['latitude']?.toDouble() ?? ufsCampus.latitude,
                              property['longitude']?.toDouble() ?? ufsCampus.longitude,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                // ============================================
                                // THIS NOW CALLS THE SHOW PROPERTY DETAILS METHOD
                                // ============================================
                                _showPropertyDetails(property);
                              },
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}