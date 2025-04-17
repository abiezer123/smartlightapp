import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart'; // Import the dashboard screen

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _responseMessage = "";

  // ESP32 server URL
  final String esp32Url = "http://192.168.4.1/login";

  void _login() async {
    try {
      // Send POST request to the ESP32
      final response = await http.post(
        Uri.parse(esp32Url),
        body: {
          'username': _usernameController.text,
          'password': _passwordController.text,
        },
      );

      // Handle response
      if (response.statusCode == 200) {
        setState(() {
          _responseMessage = "Login successful";
        });

        // Navigate to DashboardScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else if (response.statusCode == 401) {
        setState(() {
          _responseMessage = "Invalid credentials: ${response.body}";
        });
      } else if (response.statusCode == 400) {
        setState(() {
          _responseMessage = "Bad request: ${response.body}";
        });
      } else {
        setState(() {
          _responseMessage = "Unexpected error: ${response.statusCode} - ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ESP32 Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text("Login"),
            ),
            SizedBox(height: 20),
            Text(
              _responseMessage,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}