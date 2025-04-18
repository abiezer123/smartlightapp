import 'package:flutter/material.dart';
import 'package:smartapp/managemac_screen.dart';
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import 'logs_screen.dart';
import 'alerts_screen.dart';

void main() {
  runApp(MaterialApp(
    home: DashboardScreen(),
    routes: {
      '/schedule': (context) => ScheduleScreen(),
      '/logs': (context) => LogsScreen(),
      '/alerts': (context) => AlertsScreen(),
      '/managemac': (context) => ManageMACScreen(),
    },
  ));
}
