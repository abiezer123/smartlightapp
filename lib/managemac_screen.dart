import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageMACScreen extends StatefulWidget {
  @override
  _ManageMACScreenState createState() => _ManageMACScreenState();
}

class _ManageMACScreenState extends State<ManageMACScreen> {
  List<String> macAddresses = [];

  @override
  void initState() {
    super.initState();
    fetchMACAddresses();
  }

  // Fetch the list of MAC addresses
  Future<void> fetchMACAddresses() async {
    final response = await http.get(Uri.parse('http://<ESP32_IP>/getMACList'));

    if (response.statusCode == 200) {
      List<dynamic> devices = json.decode(response.body);
      setState(() {
        macAddresses = devices.map((device) => device as String).toList();
      });
    } else {
      print('Failed to fetch MAC addresses');
    }
  }

  // Add MAC address
  Future<void> addMAC(String mac) async {
    final response = await http.post(
      Uri.parse('http://<ESP32_IP>/addMAC'),
      body: {'mac': mac},
    );

    if (response.statusCode == 200) {
      fetchMACAddresses(); // Refresh list
    } else {
      print('Failed to add MAC address');
    }
  }

  // Delete MAC address
  Future<void> deleteMAC(String mac) async {
    final response = await http.post(
      Uri.parse('http://<ESP32_IP>/deleteMAC'),
      body: {'mac': mac},
    );

    if (response.statusCode == 200) {
      fetchMACAddresses(); // Refresh list
    } else {
      print('Failed to delete MAC address');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage MAC Addresses')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Add MAC dialog
              showDialog(
                context: context,
                builder: (context) {
                  TextEditingController macController = TextEditingController();
                  return AlertDialog(
                    title: Text('Enter MAC Address'),
                    content: TextField(
                      controller: macController,
                      decoration: InputDecoration(hintText: 'XX:XX:XX:XX:XX:XX'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          addMAC(macController.text);
                          Navigator.pop(context);
                        },
                        child: Text('Add'),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text('Add MAC Address'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: macAddresses.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(macAddresses[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      deleteMAC(macAddresses[index]);
                    },
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
