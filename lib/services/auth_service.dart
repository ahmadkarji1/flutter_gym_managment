import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

import '../models/user.dart';
import '../models/member.dart';

class AuthService {
  String? _token;

  // 1. إدارة التوكن (Token Management)
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    _token = token;
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _token = null;
  }

  Map<String, String> _getHeaders() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty || response.body.trim().toLowerCase() == 'null') {
      return {};
    }
    try {
      return json.decode(response.body);
    } catch (e) {
      throw Exception('خطأ في استجابة الخادم (Invalid JSON Format).');
    }
  }

  void _handleNetworkErrors(Object e) {
    if (e is TimeoutException) {
      throw Exception('انتهت مهلة الاتصال بالخادم (15 ثانية).');
    }
    if (e is SocketException) {
      throw Exception('فشل الاتصال بالخادم. تأكد من تشغيل الخادم والشبكة.');
    }
    throw e;
  }

  // ------------------------------------------------------------------
  //  دوال المصادقة
  // ------------------------------------------------------------------

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final url = Uri.parse('${Constants.BASE_URL}/signin');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'device_name': Platform.isAndroid ? 'AndroidDevice' : 'IOSDevice',
        }),
      ).timeout(const Duration(seconds: 15));

      final responseBody = _decodeResponse(response);

      if (response.statusCode == 200) {
        if (responseBody['token'] != null) {
          await saveToken(responseBody['token']);
        }
        if (responseBody['user'] is Map<String, dynamic>) {
          final userJson = responseBody['user'] as Map<String, dynamic>;
          userJson['role'] = responseBody['role'] ?? userJson['role'] ?? 'member';
          final user = User.fromJson(userJson);
          return {'success': true, 'user': user, 'message': responseBody['message'] ?? 'تم تسجيل الدخول بنجاح'};
        } else {
          return {'success': false, 'message': 'بيانات المستخدم مفقودة أو غير صحيحة من الخادم'};
        }
      } else {
        String errorMessage = responseBody['message'] ?? 'بيانات الدخول غير صحيحة';
        return {'success': false, 'message': errorMessage};
      }
    } on Exception catch (e) {
      _handleNetworkErrors(e);
      return {'success': false, 'message': 'فشل الاتصال بالخادم: ${e.toString().replaceFirst('Exception: ', '')}'};
    }
  }

  Future<User?> fetchProfile() async {
    await loadToken();
    if (_token == null) return null;
    final url = Uri.parse('${Constants.BASE_URL}/get_profile');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      final responseBody = _decodeResponse(response);
      if (response.statusCode == 200) {
        if (responseBody['status'] == true && responseBody['user'] is Map<String, dynamic>) {
          final userJson = responseBody['user'] as Map<String, dynamic>;
          if (!userJson.containsKey('role')) {
            userJson['role'] = 'member';
          }
          return User.fromJson(userJson);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> logout() async {
    final url = Uri.parse('${Constants.BASE_URL}/logout');
    try {
      await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
    } catch (_) {}
    await deleteToken();
  }

  // ------------------------------------------------------------------
  //  دوال إدارة الأعضاء (CRUD)
  // ------------------------------------------------------------------

  // ✅ تحديث: إضافة بارامتر searchQuery للبحث عن الأعضاء من السيرفر
  Future<List<Member>> fetchMembers({String searchQuery = ""}) async {
    await loadToken();
    if (_token == null) return [];

    // ربط كلمة البحث بالرابط المرسل لـ Laravel
    final url = Uri.parse('${Constants.BASE_URL}/members?search=$searchQuery');

    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      final responseBody = _decodeResponse(response);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        final List<dynamic> memberListJson = responseBody['data'] ?? [];
        return memberListJson.map((json) => Member.fromJson(json)).toList();
      } else {
        throw Exception(responseBody['message'] ?? 'فشل جلب القائمة');
      }
    } catch (e) {
      _handleNetworkErrors(e);
      return [];
    }
  }

  // ✅ تحديث: دالة تعديل العضو أو التدريب (لضمان الحفظ الدائم في السيرفر)
  Future<Member> updateMember(int id, Map<String, dynamic> data) async {
    await loadToken();
    // تأكد من أن هذا الرابط يطابق ما وضعناه في api.php (مثلاً training-sessions أو members)
    final url = Uri.parse('${Constants.BASE_URL}/members/$id');

    try {
      final response = await http.put(
          url,
          headers: _getHeaders(),
          body: json.encode(data)
      ).timeout(const Duration(seconds: 15));

      final responseBody = _decodeResponse(response);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        if (responseBody['data'] is Map<String, dynamic>) {
          return Member.fromJson(responseBody['data']);
        }
        throw Exception('الخادم لم يُرجع البيانات المحدثة.');
      } else {
        throw Exception(responseBody['message'] ?? 'فشل التحديث في قاعدة البيانات');
      }
    } catch (e) {
      _handleNetworkErrors(e);
      rethrow;
    }
  }

  // دالة لحذف العضو
  Future<void> deleteMember(int id) async {
    await loadToken();
    final url = Uri.parse('${Constants.BASE_URL}/members/$id');
    try {
      final response = await http.delete(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
      final responseBody = _decodeResponse(response);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(responseBody['message'] ?? 'فشل حذف العضو');
      }
    } catch (e) {
      _handleNetworkErrors(e);
      rethrow;
    }
  }
}