import 'package:flutter/material.dart';
import 'package:smartapp/managemac_screen.dart';
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import 'logs_screen.dart';
import 'alerts_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Optional: removes debug banner
      home: LoginScreen(), // Home screen to start the app
     routes: {
        '/dashboard': (context) => DashboardScreen(),
        '/schedule': (context) => ScheduleScreen(),
        '/logs': (context) => LogsScreen(),
        '/alerts': (context) => AlertsScreen(),
        '/managemac': (context) => ManageMACScreen(),
        '/login': (context) => LoginScreen(), // Ensure this route is correct
      },
    );
  }
}
