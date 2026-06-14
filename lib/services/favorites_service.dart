import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  final supabase = Supabase.instance.client;

  // Check if a property is favorited by current user
  Future<bool> isFavorited(String propertyId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await supabase
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('property_id', propertyId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Add property to favorites
  Future<void> addFavorite(String propertyId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await supabase.from('favorites').insert({
      'user_id': user.id,
      'property_id': propertyId,
    });
  }

  // Remove property from favorites
  Future<void> removeFavorite(String propertyId) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await supabase
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('property_id', propertyId);
  }

  // Get all favorited properties for current user
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('favorites')
          .select('property_id, properties(*)')
          .eq('user_id', user.id);

      // Extract the property objects from the response
      return response.map<Map<String, dynamic>>((item) {
        return item['properties'] as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }
}