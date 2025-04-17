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

  void _dismissAlert(int index) {
    setState(() {
      _alerts.removeAt(index);
    });
  }

  void _callEmergency() {
    // Replace with actual emergency call handling (e.g., open a call intent)
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
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(
                      alert['message'] ?? 'Unknown Alert',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    subtitle: Text(
                      'Detected at: ${alert['timestamp'] ?? 'Unknown time'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.cancel, color: Colors.grey),
                          onPressed: () => _dismissAlert(index),
                          tooltip: 'Dismiss Alert',
                        ),
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