import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? householdName,
  }) async {
    final body = {'username': username, 'email': email, 'password': password};
    if (householdName != null && householdName.trim().isNotEmpty) {
      body['household_name'] = householdName.trim();
    }
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(_extractError(response.body));
    }
  }

  static Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveTokens(data['access'], data['refresh']);
    } else {
      throw Exception(_extractError(response.body));
    }
  }

  // A private method to extract Json errors and pull out something readable to show the user.
  static String _extractError(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      if (data is Map) {
        return data.values.first is List
            ? data.values.first[0]
            : data.values.first.toString();
      }
      return responseBody;
    } catch (_) {
      return responseBody;
    }
  }
}
