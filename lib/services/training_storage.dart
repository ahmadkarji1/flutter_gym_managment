import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class TrainingDataStorage {
  static Map<String, String> _getHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Future<List<dynamic>> fetchAllTrainings(String token) async {
    final url = Uri.parse('${Constants.BASE_URL}/training-sessions');
    try {
      final response = await http.get(url, headers: _getHeaders(token));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) { print("Fetch Error: $e"); }
    return [];
  }

  // دالة الإضافة (POST) - تستخدم عندما تكون الجلسة غير مسجلة
  static Future<bool> saveNewTraining(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('${Constants.BASE_URL}/training-sessions');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: json.encode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) { return false; }
  }

  // دالة التعديل (PUT) - تستخدم للجلسات الموجودة مسبقاً
  static Future<bool> updateInDatabase(String token, int id, Map<String, dynamic> data) async {
    final url = Uri.parse('${Constants.BASE_URL}/training-sessions/$id');
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(token),
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }
}