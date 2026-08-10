import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =============== Authentication ===============

  Future<String?> register({
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
      return null;
    }

    final data = jsonDecode(response.body);
    if (data['username'] != null) {
      return 'That username is already taken';
    }
    if (data['email'] != null) {
      return 'Please enter a valid email address';
    }
    if (data['password'] != null) {
      return 'Password must be at least 8 characters long';
    }
    return 'Registration failed. Please try again';
  }

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      return null;
    }
    if (response.statusCode == 401) {
      return 'Incorrect username or password';
    }
    if (response.statusCode >= 500) {
      return 'Something went wrong on our end. Please try again in a moment';
    }
    return 'Login failed. Please try again';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // =============== Pets ===============

  Future<List<Pet>> getPets() async {
    final response = await http.get(
      Uri.parse('$baseUrl/pets/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Pet.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pets');
    }
  }

  Future<String?> createPet({
    required String name,
    required String species,
    String? breed,
    String? birthday,
    String? gotchaDate,
    String? allergies,
    String? existingConditions,
    List<int>? photoBytes,
    String? photoFilename,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/pets/'));
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = name;
    request.fields['species'] = species;
    if (breed != null) request.fields['breed'] = breed;
    if (birthday != null) request.fields['birthday'] = birthday;
    if (gotchaDate != null) request.fields['gotcha_date'] = gotchaDate;
    if (allergies != null) request.fields['allergies'] = allergies;
    if (existingConditions != null)
      request.fields['existing_conditions'] = existingConditions;

    if (photoBytes != null && photoFilename != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          photoBytes,
          filename: photoFilename,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data['name'] != null) {
      return 'Please enter a name for your pet';
    }
    if (data['species'] != null) {
      return 'Please choose a species';
    }
    return 'Failed to save pet. Please try again';
  }
}
