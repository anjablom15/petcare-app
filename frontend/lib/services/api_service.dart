import 'dart:convert';
import 'package:frontend/models/food_product.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/weight_log.dart';
import '../models/food_product.dart';
import '../models/food_bag.dart';
import '../models/feeding_slot.dart';
import '../models/missed_meal.dart';

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

  Future<String?> updatePet({
    required int id,
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
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/pets/$id/'),
    );
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

    if (response.statusCode == 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data['name'] != null) {
      return 'Please enter a name for your pet';
    }
    if (data['species'] != null) {
      return 'Please choose a species';
    }
    return 'Failed to update pet. Please try again';
  }

  Future<bool> deletePet(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/pets/$id/'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
  }

  // =============== Weight ===============

  Future<List<WeightLog>> getWeightLogs(int petId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/weight-logs/?pet=$petId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => WeightLog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to laod weight logs');
    }
  }

  Future<String?> createWeightLog({
    required int petId,
    required double weightKg,
    required String date,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/weight-logs/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'pet': petId,
        'weight_kg': weightKg,
        'date': date,
        'notes': notes ?? '',
      }),
    );

    if (response.statusCode == 201) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data['pet'] != null) {
      return 'You don\'t have access to this pet';
    }
    if (data['weight_kg'] != null) {
      return 'Please enter a valid weight';
    }
    return 'Failed to save weight log. Please try again';
  }

  Future<bool> deleteWeightLog(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/weight-logs/$id/'),
      headers: await _getHeaders(),
    );

    return response.statusCode == 204;
  }

  // =============== Food ===============

  Future<List<FoodProduct>> getFoodProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/food-products/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FoodProduct.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load food products");
    }
  }

  Future<FoodProduct> getFoodProduct(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/food-products/$id/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return FoodProduct.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load food product');
    }
  }

  Future<String?> createFoodProduct({
    required String name,
    String? brand,
    required String unitType,
    required double typicalPackageSize,
    double? typicalPrice,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/food-products/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'brand': brand ?? '',
        'unit_type': unitType,
        'typical_package_size': typicalPackageSize,
        'typical_price': typicalPrice,
      }),
    );

    if (response.statusCode == 201) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data['name'] != null) {
      return "Please enter a name for this food product.";
    }
    if (data['typical_package_size'] != null) {
      return "Please enter a valid package size";
    }
    return "Failed to save food product. Please try again";
  }

  Future<bool> deleteFoodProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/food-products/$id/'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
  }

  Future<List<FoodBag>> getFoodBags({int? productId}) async {
    var url = '$baseUrl/food-bags/';
    if (productId != null) {
      url += '?product=$productId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FoodBag.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load food bags");
    }
  }

  Future<String?> createFoodBag({
    required int productId,
    required String purchaseDate,
    required double quantityTotal,
    double? pricePaid,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/food-bags/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'product': productId,
        'purchase_date': purchaseDate,
        'quantity_total': quantityTotal,
        'price_paid': pricePaid,
      }),
    );

    if (response.statusCode == 201) {
      return null;
    }
    final data = jsonDecode(response.body);
    if (data['product'] != null) {
      return "You don\'t have access to this food product";
    }
    if (data['quantity_total'] != null) {
      return "Please enter a valid quantity";
    }
    return "Failed to save food bag. Please try again";
  }

  Future<String?> markBagFinished({
    required int bagId,
    required String finishedDate,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/food-bags/$bagId/'),
      headers: await _getHeaders(),
      body: jsonEncode({'finished_early_date': finishedDate}),
    );

    if (response.statusCode == 200) {
      return null;
    }
    return "Failed to mark bag as finished. Please try again";
  }

  Future<List<FeedingSlot>> getFeedingSlots({
    int? petId,
    int? productId,
  }) async {
    var url = '$baseUrl/feeding-slots/';
    final params = <String>[];
    if (petId != null) params.add('pet=$petId');
    if (productId != null) params.add('product=$productId');
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FeedingSlot.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load feeding slots");
    }
  }

  Future<String?> createFeedingSlot({
    required int petId,
    required int productId,
    String? label,
    required double portionAmount,
    required List<String> daysOfWeek,
    required String startDate,
    String? endDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/feeding-slots/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'pet': petId,
        'product': productId,
        'label': label ?? '',
        'portion_amount': portionAmount,
        'days_of_week': daysOfWeek,
        'start_date': startDate,
        'end_date': endDate,
      }),
    );

    if (response.statusCode == 201) {
      return null;
    }

    final data = jsonDecode(response.body);

    if (data['pet'] != null) {
      return "You don\'t have access to this pet";
    }
    if (data['product'] != null) {
      return "You don\'t have access to this product";
    }
    if (data['portion_amount'] != null) {
      return "Please enter a valid amount";
    }
    if (data['days_of_week'] != null) {
      return "Please select at least one feeding day.";
    }
    return "Failed to create feeding schedule. Please try again";
  }

  Future<bool> deleteFeedingSlot(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/feeding-slots/$id/'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 204;
  }

  Future<String?> updateFeedingSlot({
    required int id,
    required int petId,
    required int productId,
    String? label,
    required double portionAmount,
    required List<String> daysOfWeek,
    required String startDate,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/feeding-slots/$id/'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'pet': petId,
        'product': productId,
        'label': label ?? '',
        'portion_amount': portionAmount,
        'days_of_week': daysOfWeek,
        'start_date': startDate,
      }),
    );

    if (response.statusCode == 200) return null;
    final data = jsonDecode(response.body);
    if (data['pet'] != null) {
      return 'You don\'t have access to this pet';
    }
    if (data['product'] != null) {
      return 'You don\'t have access to this food product';
    }
    if (data['portion_amount'] != null) {
      return 'Please enter a valid portion amount';
    }
    if (data['days_of_week'] != null) {
      return 'Please select at least one feeding day';
    }
    return 'Failed to update feeding schedule. Please try again';
  }

  Future<List<MissedMeal>> getMissedMeals({int? feedingSlotId}) async {
    var url = '$baseUrl/missed-meals/';
    if (feedingSlotId != null) {
      url += '?feeding_slot=$feedingSlotId';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MissedMeal.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load missed meals");
    }
  }

  Future<String?> createMissedMeal({
    required int feedingSlotId,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/missed-meals/'),
      headers: await _getHeaders(),
      body: jsonEncode({'feeding_slot': feedingSlotId, 'date': date}),
    );

    if (response.statusCode == 201) {
      return null;
    }

    final data = jsonDecode(response.body);

    if (data['feeding_slot'] != null) {
      return "You don\'t have access to this feeding schedule";
    }

    if (data['non_field_errors'] != null) {
      return "This meal has already been marked as missed";
    }
    return "Failed to log missed meal. Please try again";
  }
}
