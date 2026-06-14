import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/map_screen.dart';
import 'screens/login_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://wakxyaakzsbfynieuzim.supabase.co',  
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indha3h5YWFrenNiZnluaWV1emltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA5MzI3MzYsImV4cCI6MjA5NjUwODczNn0.O9VwslwrLLIwagf0ZzbOK7F90MWdD19X0bQOcxgI538',   
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloemFinder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // User is logged in, go to map screen
      return const MapScreen();
    } else {
      // User is not logged in, go to login screen
      return const LoginScreen();
    }
  }
}