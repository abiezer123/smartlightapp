import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
    });

    // Replace with your ESP32's IP address
    const String esp32Url = 'http://192.168.4.1/getLogs';

    try {
      final response = await http.get(Uri.parse(esp32Url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> logs = List<Map<String, dynamic>>.from(data['logs']);

        // Filter out unauthorized access logs
        logs = logs.where((log) => log['event'] != 'Unauthorized device connected!').toList();

        setState(() {
          _logs = logs;
        });
      }
    } catch (e) {
      print('Error fetching logs: $e');
      setState(() {
        _logs = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Text(
                    'No logs available',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          log['event'] ?? 'Unknown Event',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Time: ${log['timestamp'] ?? 'Unknown time'}',
                        ),
                        trailing: Icon(Icons.history, color: Colors.blue),
                      ),
                    );
                  },
                ),
    );
  }
}
