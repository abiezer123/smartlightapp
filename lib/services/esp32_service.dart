import 'package:http/http.dart' as http;
import 'dart:convert';

class ESP32Service {
  static const String _baseUrl = 'http://192.168.4.1';

  // Fetch LED statuses
  static Future<Map<int, bool>> fetchLedStatuses() async {
    final url = Uri.parse('$_baseUrl/getStates');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          1: data['led1'] == 1,
          2: data['led2'] == 1,
          3: data['led3'] == 1,
          4: data['led4'] == 1,
        };
      } else {
        throw Exception('Failed to fetch LED statuses');
      }
    } catch (e) {
      throw Exception('Error fetching LED statuses: $e');
    }
  }

  // Toggle an individual LED
  static Future<void> toggleLed(int id, bool state) async {
    final url = Uri.parse('$_baseUrl/setLED');
    try {
      final response = await http.post(
        url,
        body: {
          'id': id.toString(),
          'state': state ? '1' : '0',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to toggle LED $id');
      }
    } catch (e) {
      throw Exception('Error toggling LED $id: $e');
    }
  }

  // Fetch automation status
  static Future<bool> fetchAutomationStatus() async {
    final url = Uri.parse('$_baseUrl/toggleAuto');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return response.body.contains('true');
      } else {
        throw Exception('Failed to fetch automation status');
      }
    } catch (e) {
      throw Exception('Error fetching automation status: $e');
    }
  }

  // Toggle automation mode
  static Future<void> toggleAutomation() async {
    final url = Uri.parse('$_baseUrl/toggleAuto');
    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to toggle automation mode');
      }
    } catch (e) {
      throw Exception('Error toggling automation mode: $e');
    }
  }

  // Fetch alerts
  static Future<List<Map<String, dynamic>>> fetchAlerts() async {
    final url = Uri.parse('$_baseUrl/faultAlert');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['alerts']);
      } else {
        throw Exception('Failed to fetch alerts');
      }
    } catch (e) {
      throw Exception('Error fetching alerts: $e');
    }
  }

  // Fetch logs
  static Future<List<Map<String, dynamic>>> fetchLogs() async {
    final url = Uri.parse('$_baseUrl/getLogs');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['logs']);
      } else {
        throw Exception('Failed to fetch logs');
      }
    } catch (e) {
      throw Exception('Error fetching logs: $e');
    }
  }

  // Fetch schedules
  static Future<List<Map<String, dynamic>>> fetchSchedules() async {
    final url = Uri.parse('$_baseUrl/getSchedules');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['schedules']);
      } else {
        throw Exception('Failed to fetch schedules');
      }
    } catch (e) {
      throw Exception('Error fetching schedules: $e');
    }
  }

  // Add a new schedule
  static Future<void> addSchedule(String led, String time, String duration) async {
    final url = Uri.parse('$_baseUrl/setSchedule');
    try {
      final response = await http.post(
        url,
        body: {
          'led': led,
          'time': time,
          'duration': duration,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to add schedule');
      }
    } catch (e) {
      throw Exception('Error adding schedule: $e');
    }
  }

  // Delete a schedule
  static Future<void> deleteSchedule(int id) async {
    final url = Uri.parse('$_baseUrl/deleteSchedule');
    try {
      final response = await http.post(
        url,
        body: {
          'id': id.toString(),
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete schedule');
      }
    } catch (e) {
      throw Exception('Error deleting schedule: $e');
    }
  }
}