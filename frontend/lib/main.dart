import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PetCareApp());
}

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Care App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: LoginScreen()),
    );
  }
}
