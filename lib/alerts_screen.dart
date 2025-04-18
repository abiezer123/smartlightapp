import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  // Fetch alerts from the ESP32 server
  Future<void> _fetchAlerts() async {
    // Replace with your ESP32's IP address
    const String esp32Url = 'http://192.168.4.1/faultAlert';

    try {
      final response = await http.get(Uri.parse(esp32Url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Assuming the ESP32 returns a list of alerts
        setState(() {
          _alerts = List<Map<String, dynamic>>.from(data['alerts']);
        });
      }
    } catch (e) {
      print('Error fetching alerts: $e');
    }
  }

  // Dismiss alert by index
  void _dismissAlert(int index) {
    setState(() {
      _alerts.removeAt(index);
    });
  }

  // Call emergency services (you can replace this with actual functionality)
  void _callEmergency() {
    print('Emergency services called!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts & Notifications'),
      ),
      body: _alerts.isEmpty
          ? Center(
              child: Text(
                'No alerts at the moment',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                String alertType = alert['type'] ?? 'Unknown';
                String message = alert['message'] ?? 'Unknown Alert';
                String timestamp = alert['timestamp'] ?? 'Unknown time';
                bool isCritical = alert['isCritical'] ?? false; // Determine if critical

                // Set icon and color based on alert type
                Icon alertIcon;
                Color alertColor;

                switch (alertType) {
                  case 'wifi':
                    alertIcon = Icon(Icons.wifi_off, color: Colors.orange);
                    alertColor = Colors.orange;
                    break;
                  case 'light':
                    alertIcon = Icon(Icons.lightbulb_outline, color: isCritical ? Colors.red : Colors.yellow);
                    alertColor = isCritical ? Colors.red : Colors.yellow;
                    break;
                  case 'sensor':
                    alertIcon = Icon(Icons.sensors, color: Colors.blue);
                    alertColor = Colors.blue;
                    break;
                  default:
                    alertIcon = Icon(Icons.warning, color: Colors.grey);
                    alertColor = Colors.grey;
                    break;
                }

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: alertIcon,
                    title: Text(
                      message,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: alertColor,
                      ),
                    ),
                    subtitle: Text(
                      'Detected at: $timestamp',
                      style: TextStyle(color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.grey),
                          onPressed: () => _dismissAlert(index),
                          tooltip: 'Dismiss Alert',
                        ),
                        if (isCritical) // Show emergency button for critical alerts only
                          IconButton(
                            icon: Icon(Icons.phone, color: Colors.red),
                            onPressed: _callEmergency,
                            tooltip: 'Call Emergency',
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
