import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'review_screen.dart';
import '../widgets/report_dialog.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;
  final String propertyName;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? property;
  List<dynamic> rooms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPropertyAndRooms();
  }

  Future<void> _loadPropertyAndRooms() async {
    try {
      final propertyResponse = await supabase
          .from('properties')
          .select('*')
          .eq('id', widget.propertyId)
          .single();

      final roomsResponse = await supabase
          .from('rooms')
          .select('*')
          .eq('property_id', widget.propertyId)
          .eq('is_available', true);

      setState(() {
        property = propertyResponse;
        rooms = roomsResponse;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getLatestReview() async {
    try {
      final response = await supabase
          .from('reviews')
          .select('*')
          .eq('property_id', widget.propertyId)
          .order('created_at', ascending: false)
          .limit(1);
      
      if (response.isNotEmpty) {
        return response[0];
      }
      return null;
    } catch (e) {
      print('Error getting latest review: $e');
      return null;
    }
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime.toString());
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (property == null) {
      return const Scaffold(
        body: Center(child: Text('Property not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propertyName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.report),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ReportDialog(
                  propertyId: widget.propertyId,
                  propertyName: widget.propertyName,
                ),
              );
            },
            tooltip: 'Report this property',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property details card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            property!['address'] ?? 'Address not available',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (property!['near_campus'] != null)
                      Chip(
                        label: Text(property!['near_campus']),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    const SizedBox(height: 12),
                    if (property!['description'] != null)
                      Text(
                        property!['description'],
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rooms section
            Text(
              'Available Rooms (${rooms.length})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (rooms.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No rooms available at this property'),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return _buildRoomCard(room);
                },
              ),

            const SizedBox(height: 20),

            // Reviews section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reviews',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewScreen(
                          propertyId: widget.propertyId,
                          propertyName: widget.propertyName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.rate_review),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            FutureBuilder(
              future: _getLatestReview(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                
                if (snapshot.hasData && snapshot.data != null) {
                  final review = snapshot.data!;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < (review['rating'] as int) ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                review['user_email']?.split('@').first ?? 'Student',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(review['created_at']),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review['comment'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          'No reviews yet. Be the first to review!',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    room['room_number'] != null && room['room_number'].toString().isNotEmpty
                        ? 'Room ${room['room_number']}'
                        : 'Room Available',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'R${room['price_per_month']}/month',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 12,
              children: [
                _buildInfoChip(
                  icon: Icons.bed,
                  label: _getRoomTypeLabel(room['room_type']),
                ),
                _buildInfoChip(
                  icon: Icons.bathroom,
                  label: _getBathroomTypeLabel(room['bathroom_type']),
                ),
                if (room['has_wifi'] == true)
                  _buildInfoChip(
                    icon: Icons.wifi,
                    label: 'WiFi',
                  ),
                if (room['has_parking'] == true)
                  _buildInfoChip(
                    icon: Icons.local_parking,
                    label: 'Parking',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (room['description'] != null && room['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  room['description'],
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showContactDialog();
                },
                icon: const Icon(Icons.phone),
                label: const Text('Contact Landlord'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  String _getRoomTypeLabel(String? type) {
    switch (type) {
      case 'single': return 'Single Room';
      case 'shared': return 'Shared Room';
      case 'studio': return 'Studio';
      case 'flat': return 'Flat/Apartment';
      default: return 'Room';
    }
  }

  String _getBathroomTypeLabel(String? type) {
    switch (type) {
      case 'private': return 'Private Bathroom';
      case 'shared': return 'Shared Bathroom';
      case 'communal': return 'Communal Bathroom';
      default: return 'Bathroom';
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Landlord'),
        content: const Text(
          'Contact information will appear here once landlords register.\n\n'
          'For demo purposes, you can reach the property manager at:\n'
          '📞 +27 82 123 4567\n'
          '📧 manager@sunnyheights.co.za',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}