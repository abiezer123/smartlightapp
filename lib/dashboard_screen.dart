import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isAutomationEnabled = false;
  Map<int, bool> _ledStatuses = {
    0: false,
    1: false,
    2: false,
    3: false,
    4: false, // Include ID 4 for automation mode
  };
  Timer? _ledRefreshTimer;

  // Fixed LED locations
  final Map<int, LatLng> _ledLocations = {
    0: LatLng(14.700356, 121.031860),
    1: LatLng(14.700336, 121.032098),
    2: LatLng(14.700491, 121.032212),
    3: LatLng(14.700402, 121.032451),
    4: LatLng(14.700396, 121.032356), // New marker for LED 4 (used in auto mode)
  };

  @override
  void initState() {
    super.initState();
    _getLedStates();

    _ledRefreshTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (_isAutomationEnabled) {
        _getLedStates();
      }
    });
  }

  @override
  void dispose() {
    _ledRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _getLedStates() async {
    const String esp32Url = 'http://192.168.4.1/getStates';

    try {
      final response = await http.get(Uri.parse(esp32Url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

          setState(() {
            _ledStatuses[0] = data['led0'] == 1;
            _ledStatuses[1] = data['led1'] == 1;
            _ledStatuses[2] = data['led2'] == 1;
            _ledStatuses[3] = data['led4'] == 1; // Corrected: LED 3 state comes from led4
            _ledStatuses[4] = data['led3'] == 1; // Corrected: LED 4 state comes from led3
          });

      }
    } catch (e) {
      print("Error fetching LED states: $e");
    }
  }

  Future<void> _toggleAutomation() async {
    const String esp32Url = 'http://192.168.4.1/toggleAuto';

    try {
      final response = await http.get(Uri.parse(esp32Url));
      if (response.statusCode == 200) {
        setState(() {
          _isAutomationEnabled = response.body.contains('true');
        });
      }
    } catch (e) {
      print('Error toggling automation: $e');
    }
  }

  Future<void> _toggleLed(int id, bool state) async {
    const String esp32Url = 'http://192.168.4.1/setLED';

    try {
      final response = await http.post(
        Uri.parse(esp32Url),
        body: {
          'id': id.toString(),
          'state': state ? '1' : '0',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _ledStatuses[id] = state;
        });
      }
    } catch (e) {
      print('Error toggling LED $id: $e');
    }
  }

  Map<int, LatLng> _getDynamicLedLocations() {
  if (_isAutomationEnabled) {
    return {
      1: LatLng(14.700356, 121.031860),
      2: LatLng(14.700336, 121.032098),
      3: LatLng(14.700402, 121.032451),
      4: LatLng(14.700491, 121.032212),
    };
  }
  return {
    0: _ledLocations[0]!,
    1: _ledLocations[1]!,
    2: _ledLocations[2]!,
    3: _ledLocations[3]!,
  };
}

  List<int> _getActiveLedIds() {
    return _isAutomationEnabled ? [1, 2, 3, 4] : [0, 1, 2, 3];
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color(0xFFF1F1F1), // Slightly darker than white (beige tone)
    appBar: AppBar(
      title: Text(
        'Dashboard',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.black,
    ),
    body: SingleChildScrollView( // Make the whole page scrollable
      child: Column(
        children: [
          // Map container
          Container(
            margin: EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width * 0.95, // Adjust width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            height: MediaQuery.of(context).size.height * 0.4,
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(14.700356, 121.031860),
                zoom: 17.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: _getDynamicLedLocations().entries.map((entry) {
                    final id = entry.key;
                    final location = entry.value;
                    final isOn = _ledStatuses[id] ?? false;

                    return Marker(
                      width: 80.0,
                      height: 80.0,
                      point: location,
                      builder: (ctx) => GestureDetector(
                        onTap: () => _toggleLed(id, !isOn),
                        child: Icon(
                        Icons.lightbulb, // or use Icons.light_outlined
                        color: isOn ? Colors.green : Colors.red,
                        size: 30.0,
                      ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
            // Button container for control and navigation
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              width: MediaQuery.of(context).size.width * 0.95, // Adjust width
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Automation and LED controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Automation Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      Switch(
                        value: _isAutomationEnabled,
                        onChanged: (value) => _toggleAutomation(),
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.grey,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Manual LED Controls',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  ...List.generate(4, (index) {
                    final id = index;
                    final isOn = _isAutomationEnabled ? false : (_ledStatuses[id] ?? false);

                    return SwitchListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      title: Text(
                        'LED ${index + 1}',
                        style: TextStyle(color: Colors.black),
                      ),
                      subtitle: Text(
                        isOn ? 'ON' : 'OFF',
                        style: TextStyle(color: Colors.black87),
                      ),
                      value: isOn,
                      onChanged: _isAutomationEnabled ? null : (value) => _toggleLed(id, value),
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.grey[400],
                    );
                  }),
                  SizedBox(height: 15),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isAutomationEnabled
                          ? null
                          : () {
                              for (int id = 0; id < 4; id++) {
                                final newState = !_ledStatuses[id]!;
                                _toggleLed(id, newState);
                              }
                            },
                      child: Text('Toggle All LEDs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAutomationEnabled ? Colors.grey : Colors.blueGrey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                                  SizedBox(height: 20),
                ],
              ),
            ),

          SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Logs Button (left side)
                      Expanded(
                        child: Container(
                          height: 130,
                          margin: EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/logs');
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                            ),
                            child: Text('Logs'),
                          ),
                        ),
                      ),
                      // Alerts Button (right side)
                      Expanded(
                        child: Container(
                          height: 130,
                          margin: EdgeInsets.only(left: 5),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/alerts');
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                            ),
                            child: Text('Alerts'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      // Schedule Button (left side)
                      Expanded(
                        child: Container(
                          height: 130,
                          margin: EdgeInsets.only(right: 5),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/schedule');
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                            ),
                            child: Center(child: Text('Schedule')),
                          ),
                        ),
                      ),
                      // Manage MACs Button (right side)
                      Expanded(
                        child: Container(
                          height: 130,
                          margin: EdgeInsets.only(left: 5),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/managemac');
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                            ),
                            child: Text('Manage Devices'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ]
        ),
      ),
    );
  }
  }