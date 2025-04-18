import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'login_screen.dart';


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
        if (!_isAutomationEnabled) {
          // When automation is turned off, turn on all LEDs
          for (int id = 0; id < 4; id++) {
            _toggleLed(id, true); // Set all LEDs to ON
          }
        }
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
    backgroundColor: Color(0xFFF5F5F5), // Light grey background for modern feel
    appBar: AppBar(
      title: Text(
        'Dashboard',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.blueAccent, // Softer accent color for app bar
      elevation: 6, // Subtle shadow for app bar
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Map Container
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 7,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
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
                        width: 70.0,
                        height: 70.0,
                        point: location,
                        builder: (ctx) => GestureDetector(
                          onTap: () => _toggleLed(id, !isOn),
                          child: Icon(
                            Icons.lightbulb_outline, // Lightbulb outline for cleaner look
                            color: isOn ? Colors.green : Colors.red,
                            size: 32.0,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Button Control Container
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Automation Mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Automation Mode',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Switch(
                        value: _isAutomationEnabled,
                        onChanged: (value) => _toggleAutomation(),
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        inactiveTrackColor: Colors.grey.shade300,
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Manual LED Controls',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
                  ElevatedButton(
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
                      backgroundColor: _isAutomationEnabled ? Colors.grey : Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Navigation Buttons Container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Logs Button (left side)
                      _buildNavButton(context, 'Logs', '/logs'),
                      // Alerts Button (right side)
                      _buildNavButton(context, 'Alerts', '/alerts'),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      // Schedule Button (left side)
                      _buildNavButton(context, 'Schedule', '/schedule'),
                      // Manage Devices Button (right side)
                      _buildNavButton(context, 'Manage Devices', '/managemac'),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    icon: Icon(Icons.logout),
                    label: Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Helper method to build navigation buttons
Widget _buildNavButton(BuildContext context, String label, String route) {
  return Expanded(
    child: Container(
      height: 130,
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, route);
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        child: Text(label),
      ),
    ),
  );
}

  }