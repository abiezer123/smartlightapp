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
        1: _ledLocations[1]!,
        2: _ledLocations[2]!,
        3: _ledLocations[3]!,
        4: _ledLocations[4]!,
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
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          Row(
            children: [
              Text('Auto', style: TextStyle(color: Colors.white)),
              Switch(
                value: _isAutomationEnabled,
                onChanged: (value) => _toggleAutomation(),
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.grey,
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
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
                        Icons.circle,
                        color: isOn ? Colors.green : Colors.red,
                        size: 30.0,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(4, (index) {
                    final id = index; // use index directly as id (0 to 3)
                    final isOn = _ledStatuses[id] ?? false;

                    return ElevatedButton(
                      onPressed: _isAutomationEnabled ? null : () => _toggleLed(id, !isOn),
                      child: Text(
                        isOn ? 'Turn OFF LED ${index + 1}' : 'Turn ON LED ${index + 1}',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAutomationEnabled
                            ? Colors.grey
                            : (isOn ? Colors.green : Colors.red),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    );


                  }).toList(),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                onPressed: () {
                  for (int id = 0; id < 4; id++) {
                    final newState = !_ledStatuses[id]!;
                    _toggleLed(id, newState);
                  }
                },
                child: Text('Toggle All LEDs'),
              ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
