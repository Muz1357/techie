import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://techieweb-v2-production.up.railway.app/api";
  static String? token;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// LOGIN + TOKEN
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/token"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": email,
        "password": password,
        "device_name": "flutter_app",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['token'];
      return true;
    }
    return false;
  }

  /// REGISTER

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
        "password_confirmation": passwordConfirmation,
        "device_name": "flutter_app",
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      token = data['token'];
      return true;
    }

    print("Registration failed: ${response.statusCode} - ${response.body}");
    return false;
  }

  /// Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse("$baseUrl/profile"),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    }
    throw Exception("Failed to fetch profile");
  }

  /// Update user profile
  static Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/profile"),
      headers: _headers,
      body: jsonEncode({'name': name, 'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to update profile");
    }
  }

  /// Update password
  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/password"),
      headers: _headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to update password");
    }
  }

  /// Delete account
  static Future<void> deleteAccount() async {
    final response = await http.delete(
      Uri.parse("$baseUrl/profile"),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to delete account");
    }
  }

  /// PRODUCTS
  static Future<List<dynamic>> getProducts({String? query}) async {
    final url =
        query == null ? "$baseUrl/products" : "$baseUrl/products?q=$query";
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']; // since you used paginate(10)
    }
    throw Exception("Failed to load products");
  }

  static Future<Map<String, dynamic>> getProduct(int id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/products/$id"),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load product");
  }

  /// CART
  static Future<Map<String, dynamic>> getCart() async {
    final response = await http.get(
      Uri.parse("$baseUrl/cart"),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to fetch cart");
  }

  static Future<Map<String, dynamic>> addToCart(
    int productId, {
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/cart/$productId"),
      headers: _headers,
      body: jsonEncode({"quantity": quantity}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to add to cart");
  }

  static Future<Map<String, dynamic>> updateCartItem(
    int itemId,
    int quantity,
  ) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/cart/$itemId"),
      headers: _headers,
      body: jsonEncode({"quantity": quantity}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to update cart item: ${response.statusCode}");
  }

  static Future<bool> removeCartItem(int itemId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/cart/$itemId"),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception("Failed to remove cart item: ${response.statusCode}");
    }
  }

  /// CHECKOUT
  static Future<Map<String, dynamic>> checkout(String address) async {
    http.Response? response;

    try {
      debugPrint("🚀 CHECKOUT API CALL STARTED");
      debugPrint("📝 URL: $baseUrl/checkout");
      debugPrint("📦 Request Headers: $_headers");
      debugPrint("📦 Request Body: ${jsonEncode({"address": address})}");

      final startTime = DateTime.now();

      response = await http
          .post(
            Uri.parse("$baseUrl/checkout"),
            headers: _headers,
            body: jsonEncode({"address": address}),
          )
          .timeout(const Duration(seconds: 30));

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      debugPrint("⏱️ Request duration: ${duration.inMilliseconds}ms");
      debugPrint("📡 Response Status Code: ${response.statusCode}");
      debugPrint("📡 Response Headers: ${response.headers}");
      debugPrint("📡 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          debugPrint("CHECKOUT SUCCESSFUL: $responseData");
          return responseData;
        } catch (e) {
          debugPrint("JSON PARSE ERROR: $e");
          throw Exception("Invalid response format from server");
        }
      } else {
        debugPrint("SERVER ERROR: ${response.statusCode}");

        String errorMessage =
            "Checkout failed with status: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }

        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      debugPrint("❌ SOCKET EXCEPTION: $e");
      debugPrint(
        "❌ This usually indicates no internet connection or DNS failure",
      );
      throw Exception("No internet connection: Please check your network");
    } finally {
      if (response != null) {
        debugPrint("🏁 Request completed with status: ${response.statusCode}");
      } else {
        debugPrint("🏁 Request failed - no response received");
      }
    }
  }

  /// ORDERS
  static Future<List<dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse("$baseUrl/orders"),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'];
    }
    throw Exception("Failed to fetch orders");
  }

  static Future<Map<String, dynamic>> getOrder(int id) async {
    final response = await http.get(
      Uri.parse("$baseUrl/orders/$id"),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to fetch order details");
  }
}
