import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/star_rating.dart';

class ReviewScreen extends StatefulWidget {
  final String propertyId;
  final String propertyName;

  const ReviewScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final supabase = Supabase.instance.client;
  final _commentController = TextEditingController();
  int _rating = 3;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  double _averageRating = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final response = await supabase
          .from('reviews')
          .select('*')
          .eq('property_id', widget.propertyId)
          .order('created_at', ascending: false);

      setState(() {
        _reviews = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
        _calculateAverageRating();
      });
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateAverageRating() {
    if (_reviews.isEmpty) {
      _averageRating = 0;
      return;
    }
    
    int total = 0;
    for (var review in _reviews) {
      total += review['rating'] as int;
    }
    _averageRating = total / _reviews.length;
  }

  Future<void> _submitReview() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to leave a review')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await supabase.from('reviews').insert({
        'property_id': widget.propertyId,
        'user_id': user.id,
        'user_email': user.email,
        'rating': _rating,
        'comment': _commentController.text.trim(),
      });

      _commentController.clear();
      setState(() {
        _rating = 3;
      });
      
      await _loadReviews(); // Refresh the list
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for ${widget.propertyName}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Rating summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                const Text(
                  'Overall Rating',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                StarRating(
                  rating: _averageRating,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_averageRating.toStringAsFixed(1)} out of 5',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on ${_reviews.length} review${_reviews.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Write review section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write a Review',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Your rating: '),
                    StarRating(
                      rating: _rating.toDouble(),
                      size: 28,
                      onRatingChanged: (newRating) {
                        setState(() {
                          _rating = newRating;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit Review'),
                  ),
                ),
              ],
            ),
          ),
          
          // Reviews list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                    ? const Center(
                        child: Text('No reviews yet. Be the first!'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      StarRating(
                                        rating: (review['rating'] as int).toDouble(),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        review['user_email']?.split('@').first ?? 'Student',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatDate(review['created_at']),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(review['comment'] ?? ''),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return '';
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
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}