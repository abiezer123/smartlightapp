import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageMACScreen extends StatefulWidget {
  @override
  _ManageMACScreenState createState() => _ManageMACScreenState();
}

class _ManageMACScreenState extends State<ManageMACScreen> {
  List<String> authorizedMacAddresses = [];
  List<String> unauthorizedMacAddresses = [];

  // Fetch the list of connected MAC addresses
  Future<void> fetchConnectedMACAddresses() async {
    final response = await http.get(Uri.parse('http://192.168.4.1/getConnectedMACList'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      authorizedMacAddresses = List<String>.from(data['authorized']);
      unauthorizedMacAddresses = List<String>.from(data['unauthorized']);
    } else {
      throw Exception('Failed to fetch connected MAC addresses');
    }
  }

  // Add MAC address to authorized list
  Future<void> addMACToAuthorized(String mac) async {
    print('Attempting to add MAC: $mac'); // Debugging line
    final response = await http.post(
      Uri.parse('http://192.168.4.1/toggleMACAuthorization'),
      body: {'mac': mac},
    );

    if (response.statusCode == 200) {
      // Fetch the updated list of MAC addresses
      await fetchConnectedMACAddresses();
    } else {
      print('Failed to add MAC address to authorized list: ${response.body}'); // Log the response body
    }
  }

  // Delete MAC address from authorized list
  Future<void> deleteMACFromAuthorized(String mac) async {
    final response = await http.post(
      Uri.parse('http://192.168.4.1/toggleMACAuthorization'),
      body: {'mac': mac},
    );

    if (response.statusCode == 200) {
      // Fetch the updated list of MAC addresses
      await fetchConnectedMACAddresses();
    } else {
      print('Failed to delete MAC address from authorized list');
    }
  }

  // Show confirmation dialog before adding MAC address
  void showAddConfirmationDialog(String mac) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Add'),
          content: Text('Are you sure you want to add $mac to the authorized list?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await addMACToAuthorized(mac);
                Navigator.of(context).pop(); // Close the dialog after adding
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog before deleting MAC address
  void showDeleteConfirmationDialog(String mac) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete $mac from the authorized list?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await deleteMACFromAuthorized(mac);
                Navigator.of(context).pop(); // Close the dialog after deleting
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage MAC Addresses')),
      body: FutureBuilder<void>(
        future: fetchConnectedMACAddresses(), // Call the fetch method
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // Show loading indicator
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // Show error message
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Unauthorized MAC Addresses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView(
                    children: [
                                           ...unauthorizedMacAddresses.map((mac) {
                        return ListTile(
                          title: Text(mac, style: TextStyle(color: Colors.red)),
                          trailing: IconButton(
                            icon: Icon(Icons.add_circle, color: Colors.green),
                            onPressed: () {
                              showAddConfirmationDialog(mac); // Show confirmation dialog
                            },
                          ),
                        );
                      }).toList(),

                      // Authorized MAC Addresses
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Authorized MAC Addresses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      ...authorizedMacAddresses.map((mac) {
                        return ListTile(
                          title: Text(mac, style: TextStyle(color: Colors.green)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDeleteConfirmationDialog(mac); // Show confirmation dialog
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}