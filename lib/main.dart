import 'package:flutter/material.dart';
//import 'login_screen.dart';
import 'dashboard_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the debug banner
      theme: ThemeData.dark(), // Global dark mode theme
      home: DashboardScreen(),  //LoginScreen(), // Entry point: LoginScreen
    );
  }
}