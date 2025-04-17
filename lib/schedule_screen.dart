import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = false;
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  String _selectedLed = 'All';

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() {
      _isLoading = true;
    });

    // Replace with your ESP32's IP address
    const String esp32Url = 'http://192.168.4.1/getSchedules';

    try {
      final response = await http.get(Uri.parse(esp32Url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _schedules = List<Map<String, dynamic>>.from(data['schedules']);
        });
      }
    } catch (e) {
      print('Error fetching schedules: $e');
      setState(() {
        _schedules = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSchedule() async {
    if (_timeController.text.isEmpty || _durationController.text.isEmpty) {
      // Show error if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Replace with your ESP32's IP address
    const String esp32Url = 'http://192.168.4.1/setSchedule';

    try {
      final response = await http.post(
        Uri.parse(esp32Url),
        body: {
          'led': _selectedLed,
          'time': _timeController.text,
          'duration': _durationController.text,
        },
      );

      if (response.statusCode == 200) {
        // Refresh schedules
        _fetchSchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add schedule')),
        );
      }
    } catch (e) {
      print('Error adding schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding schedule')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSchedule(int index) async {
    setState(() {
      _isLoading = true;
    });

    // Replace with your ESP32's IP address
    const String esp32Url = 'http://192.168.4.1/deleteSchedule';

    try {
      final response = await http.post(
        Uri.parse(esp32Url),
        body: {
          'id': _schedules[index]['id'].toString(), // Assuming schedules have an ID
        },
      );

      if (response.statusCode == 200) {
        // Refresh schedules
        _fetchSchedules();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete schedule')),
        );
      }
    } catch (e) {
      print('Error deleting schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting schedule')),
      );
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
        title: Text('Schedule Management'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedLed,
                        items: ['All', 'LED 1', 'LED 2', 'LED 3', 'LED 4']
                            .map((led) => DropdownMenuItem(
                                  value: led,
                                  child: Text(led),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLed = value ?? 'All';
                          });
                        },
                        decoration: InputDecoration(labelText: 'Select LED'),
                      ),
                      TextFormField(
                        controller: _timeController,
                        decoration: InputDecoration(labelText: 'Start Time (HH:MM)'),
                      ),
                      TextFormField(
                        controller: _durationController,
                        decoration: InputDecoration(labelText: 'Duration (Minutes)'),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addSchedule,
                        child: Text('Add Schedule'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = _schedules[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(
                            'LED: ${schedule['led'] ?? 'All'}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Time: ${schedule['time'] ?? 'Unknown'}\n'
                            'Duration: ${schedule['duration'] ?? 'Unknown'} mins',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSchedule(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}