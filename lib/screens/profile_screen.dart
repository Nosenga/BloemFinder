import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'favorites_screen.dart';
import 'my_reviews_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  String? userEmail;
  String? userName;
  Map<String, int> stats = {
    'favorites': 0,
    'reviews': 0,
    'reports': 0,
  };
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final userEmailValue = user.email;
    if (userEmailValue == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      userEmail = userEmailValue;
      userName = userEmailValue.split('@').first;
    });

    try {
      // Count favorites
      final favoritesResponse = await supabase
          .from('favorites')
          .select('id')
          .eq('user_id', user.id);
      final favoritesCount = favoritesResponse.length;

      // Count reviews
      final reviewsResponse = await supabase
          .from('reviews')
          .select('id')
          .eq('user_email', userEmailValue);
      final reviewsCount = reviewsResponse.length;

      // Count reports
      final reportsResponse = await supabase
          .from('reports')
          .select('id')
          .eq('user_email', userEmailValue);
      final reportsCount = reportsResponse.length;

      setState(() {
        stats = {
          'favorites': favoritesCount,
          'reviews': reviewsCount,
          'reports': reportsCount,
        };
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await supabase.auth.signOut();
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _showMyReports() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('reports')
          .select('*, properties(name)')
          .eq('user_email', user.email!)
          .order('created_at', ascending: false);

      final reports = List<Map<String, dynamic>>.from(response);

      if (reports.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You haven\'t submitted any reports yet')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Text(
                  'My Reports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final propertyData = report['properties'];
                    final propertyName = propertyData != null && propertyData is Map
                        ? propertyData['name']?.toString() ?? 'Unknown Property'
                        : 'Unknown Property';
                    
                    final reason = report['reason']?.toString() ?? 'No reason provided';
                    final status = report['status']?.toString() ?? 'pending';
                    final createdAt = report['created_at'];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              propertyName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reason,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  status == 'pending'
                                      ? Icons.pending
                                      : status == 'resolved'
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                  size: 14,
                                  color: status == 'pending'
                                      ? Colors.orange
                                      : status == 'resolved'
                                          ? Colors.green
                                          : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: status == 'pending'
                                        ? Colors.orange
                                        : status == 'resolved'
                                            ? Colors.green
                                            : Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(createdAt),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error loading reports: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load reports')),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue,
                                width: 3,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.person,
                                size: 45,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            userName ?? 'Student',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail ?? 'No email',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Stats Cards
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildStatCard(
                            icon: Icons.favorite,
                            value: stats['favorites']!,
                            label: 'Favorites',
                            color: Colors.red,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.rate_review,
                            value: stats['reviews']!,
                            label: 'Reviews',
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.flag,
                            value: stats['reports']!,
                            label: 'Reports',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 0),
                    
                    // Menu Items
                    _buildMenuItem(
                      icon: Icons.favorite_border,
                      title: 'Saved Properties',
                      subtitle: '${stats['favorites']} properties saved',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        ).then((_) => _loadUserData());
                      },
                    ),
                    
                    _buildMenuItem(
                      icon: Icons.rate_review_outlined,
                      title: 'My Reviews',
                      subtitle: '${stats['reviews']} reviews written',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
                        ).then((_) => _loadUserData());
                      },
                    ),
                    
                    _buildMenuItem(
                      icon: Icons.flag_outlined,
                      title: 'My Reports',
                      subtitle: '${stats['reports']} reports submitted',
                      onTap: _showMyReports,
                    ),
                    
                    const Divider(),
                    
                    // Logout Button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // App Version
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'BloemFinder v1.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate based on stat tapped
            if (label == 'Favorites') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ).then((_) => _loadUserData());
            } else if (label == 'Reviews') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
              ).then((_) => _loadUserData());
            } else if (label == 'Reports') {
              _showMyReports();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(height: 8),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 24, color: Colors.blue),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}