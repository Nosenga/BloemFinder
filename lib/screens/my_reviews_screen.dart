import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> myReviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyReviews();
  }

  Future<void> _loadMyReviews() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('reviews')
          .select('*, properties(name)')
          .eq('user_email', user.email ?? '')
          .order('created_at', ascending: false);

      setState(() {
        myReviews = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading my reviews: $e');
      setState(() {
        isLoading = false;
      });
      _showError('Failed to load your reviews');
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await supabase.from('reviews').delete().eq('id', reviewId);
      
      // Refresh the list
      _loadMyReviews();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting review: $e');
      _showError('Failed to delete review');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
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
        title: const Text('My Reviews'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : myReviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.rate_review_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No reviews yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Leave a review on a property to see it here',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Browse Properties'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: myReviews.length,
                  itemBuilder: (context, index) {
                    final review = myReviews[index];
                    
                    // Safely extract property data
                    dynamic propertyData = review['properties'];
                    Map<String, dynamic>? property;
                    if (propertyData != null && propertyData is Map) {
                      property = Map<String, dynamic>.from(propertyData);
                    }
                    
                    // Safely get review ID
                    final reviewId = review['id']?.toString() ?? '';
                    
                    // Safely get rating
                    int rating = 0;
                    if (review['rating'] != null) {
                      rating = review['rating'] as int;
                    }
                    
                    // Safely get comment
                    final comment = review['comment']?.toString() ?? '';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Property name and date
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    property?['name']?.toString() ?? 'Unknown Property',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDate(review['created_at']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Star rating
                            Row(
                              children: List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            
                            // Comment
                            if (comment.isNotEmpty)
                              Text(
                                comment,
                                style: const TextStyle(fontSize: 14),
                              ),
                            const SizedBox(height: 12),
                            
                            // Delete button
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: reviewId.isNotEmpty ? () => _deleteReview(reviewId) : null,
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Delete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}