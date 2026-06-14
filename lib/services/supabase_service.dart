import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://wakxyaakzsbfynieuzim.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indha3h5YWFrenNiZnluaWV1emltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MzI3MzYsImV4cCI6MjA5NjUwODczNn0.O9VwslwrLLIwagf0ZzbOK7F90MWdD19X0bQOcxgI538',
    );
  }
}