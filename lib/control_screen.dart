import 'package:flutter/material.dart';

class ControlScreen extends StatefulWidget {
  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool _isAutomationEnabled = false;
  Map<int, bool> _ledStatuses = {1: false, 2: false, 3: false, 4: false};

  void _toggleAutomation() {
    setState(() {
      _isAutomationEnabled = !_isAutomationEnabled;
    });
  }

  void _toggleLed(int id) {
    setState(() {
      _ledStatuses[id] = !_ledStatuses[id]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Control")),
      body: Column(
        children: [
          ListTile(
            title: Text("Automation Mode"),
            trailing: Switch(
              value: _isAutomationEnabled,
              onChanged: (value) => _toggleAutomation(),
            ),
          ),
          if (!_isAutomationEnabled)
            ...List.generate(4, (index) {
              final id = index + 1;
              return ListTile(
                title: Text("LED $id"),
                trailing: Switch(
                  value: _ledStatuses[id] ?? false,
                  onChanged: (value) => _toggleLed(id),
                ),
              );
            }),
        ],
      ),
    );
  }
}