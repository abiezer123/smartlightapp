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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
    });

    const String esp32Url = 'http://192.168.4.1/faultAlert';

    try {
      final response = await http.get(Uri.parse(esp32Url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _alerts = List<Map<String, dynamic>>.from(data['alerts']);
        });
      }
    } catch (e) {
      print('Error fetching alerts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _callEmergency() {
    // Simulate calling emergency services
    print('📞 Emergency services called!');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Emergency services have been notified!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? Center(
                  child: Text(
                    'No alerts available',
                    style: TextStyle(fontSize: 16.0),
                  ),
                )
              : ListView.builder(
                  itemCount: _alerts.length,
                  itemBuilder: (context, index) {
                    final alert = _alerts[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: Icon(
                          alert['isCritical'] ? Icons.warning : Icons.info,
                          color: alert['isCritical'] ? Colors.red : Colors.blue,
                        ),
                        title: Text(
                          alert['message'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: alert['isCritical'] ? Colors.red : Colors.black,
                          ),
                        ),
                        subtitle: Text('Timestamp: ${alert['timestamp']}'),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _callEmergency,
          child: Text('Call Emergency'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Red button for emergency
            padding: EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
        ),
      ),
    );
  }
}