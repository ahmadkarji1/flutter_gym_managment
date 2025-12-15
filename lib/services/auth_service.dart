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

  // 🎯 الدالة المساعدة لفك ترميز استجابة الخادم بأمان (الحل الجذري لخطأ Null)
  // تم تحسينها لضمان إرجاع Map<String, dynamic> أو رمي استثناء JSON واضح.
  Map<String, dynamic> _decodeResponse(http.Response response) {
    // إذا كان الجسم فارغًا أو يحتوي على كلمة 'null'، أعد خريطة فارغة بدلاً من Null.
    if (response.body.isEmpty || response.body.trim().toLowerCase() == 'null') {
      return {};
    }
    try {
      return json.decode(response.body);
    } catch (e) {
      // إذا فشل فك الترميز، نرمي استثناء واضحاً، وليس الخطأ الداخلي.
      throw Exception('خطأ في استجابة الخادم (Invalid JSON Format).');
    }
  }

  // دالة لمعالجة أخطاء الشبكة والاتصال
  void _handleNetworkErrors(Object e) {
    if (e is TimeoutException) {
      throw Exception('انتهت مهلة الاتصال بالخادم (15 ثانية).');
    }
    if (e is SocketException) {
      throw Exception('فشل الاتصال بالخادم. تأكد من تشغيل الخادم والشبكة.');
    }
    // رمي أي خطأ آخر مثل (Validation أو 401)
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
        // تحصين بيانات المستخدم
        if (responseBody['user'] is Map<String, dynamic>) {
          final userJson = responseBody['user'] as Map<String, dynamic>;
          userJson['role'] = responseBody['role'] ?? userJson['role'] ?? 'member';
          final user = User.fromJson(userJson);
          return {'success': true, 'user': user, 'message': responseBody['message'] ?? 'تم تسجيل الدخول بنجاح'};
        } else {
          return {'success': false, 'message': 'بيانات المستخدم مفقودة أو غير صحيحة من الخادم'};
        }
      } else {
        // إذا كان رمز الحالة غير 200، نستخرج رسالة الخطأ
        String errorMessage = responseBody['message'] ?? 'بيانات الدخول غير صحيحة';
        return {'success': false, 'message': errorMessage};
      }
    } on Exception catch (e) {
      // معالجة أخطاء الشبكة والـ JSON
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
    } catch (_) {
      // تجاهل أخطاء جلب الملف الشخصي (Profile) إذا لم يكن ضرورياً لمنطق التطبيق
    }
    return null;
  }

  Future<void> logout() async {
    final url = Uri.parse('${Constants.BASE_URL}/logout');
    try {
      await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
    } catch (_) {
      // تجاهل أخطاء الخروج
    }
    await deleteToken();
  }

  // ------------------------------------------------------------------
  //  دوال إدارة الأعضاء (CRUD)
  // ------------------------------------------------------------------

  Future<List<Member>> fetchMembers() async {
    await loadToken();
    if (_token == null) return [];
    final url = Uri.parse('${Constants.BASE_URL}/members');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));

      final responseBody = _decodeResponse(response);

      if (response.statusCode == 200 && responseBody['status'] == true) {
        final List<dynamic> memberListJson = responseBody['members'] ?? [];
        return memberListJson.map((json) => Member.fromJson(json)).toList();
      } else {
        // إذا كان رمز الحالة غير 200، نستخرج رسالة الخطأ
        throw Exception(responseBody['message'] ?? 'فشل جلب القائمة: رمز الحالة ${response.statusCode}');
      }
    } catch (e) {
      // معالجة أخطاء الشبكة والـ JSON
      _handleNetworkErrors(e);
      return [];
    }
  }

  Future<Member> addMember(Map<String, dynamic> data) async {
    await loadToken();
    final url = Uri.parse('${Constants.BASE_URL}/register_member');
    try {
      final response = await http.post(url, headers: _getHeaders(), body: json.encode(data)).timeout(const Duration(seconds: 15));

      final responseBody = _decodeResponse(response); // هنا يتم فك الترميز

      if (response.statusCode == 201 && responseBody['status'] == true) {
        // ✅ نجاح: تأكد من أن 'member' موجودة كـ Map قبل تمريرها
        if (responseBody['member'] is Map<String, dynamic>) {
          return Member.fromJson(responseBody['member']);
        }
        throw Exception('الخادم لم يُرجع بيانات العضو الجديد.');

      } else if (response.statusCode == 422) {
        // ❌ فشل التحقق (Validation): التعامل مع الأخطاء
        final errors = responseBody['errors'] as Map<String, dynamic>?;
        String firstError = 'فشل التحقق.';
        if (errors != null && errors.isNotEmpty && errors.values.first is List && errors.values.first.isNotEmpty) {
          firstError = errors.values.first.first; // استخراج أول رسالة خطأ
        }
        throw Exception(firstError);

      } else {
        // ❌ فشل آخر: خطأ الخادم 500 أو 401
        String serverMessage = responseBody['message'] ?? 'فشل العملية: رمز الحالة ${response.statusCode}';
        throw Exception(serverMessage);
      }
    } catch (e) {
      _handleNetworkErrors(e);
      rethrow; // إعادة رمي الخطأ ليتم التقاطه في الـ Provider/Screen
    }
  }

  Future<Member> updateMember(int id, Map<String, dynamic> data) async {
    await loadToken();
    final url = Uri.parse('${Constants.BASE_URL}/members/$id');
    try {
      final response = await http.put(
          url,
          headers: _getHeaders(),
          body: json.encode(data)
      ).timeout(const Duration(seconds: 15));

      final responseBody = _decodeResponse(response);

      if (response.statusCode == 200 && responseBody['status'] == true) {
        // ✅ نجاح: تأكد من أن 'member' موجودة كـ Map قبل تمريرها
        if (responseBody['member'] is Map<String, dynamic>) {
          return Member.fromJson(responseBody['member']);
        }
        throw Exception('الخادم لم يُرجع بيانات العضو المُعدّلة.');

      } else {
        // ❌ فشل: التعامل مع الأخطاء
        throw Exception(responseBody['message'] ?? 'فشل تعديل العضو: رمز الحالة ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkErrors(e);
      rethrow;
    }
  }

  Future<void> deleteMember(int id) async {
    await loadToken();
    final url = Uri.parse('${Constants.BASE_URL}/members/$id');
    try {
      final response = await http.delete(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));

      final responseBody = _decodeResponse(response);

      // رمز الحالة 200 أو 204 يعني نجاح الحذف
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(responseBody['message'] ?? 'فشل حذف العضو: رمز الحالة ${response.statusCode}');
      }
    } catch (e) {
      _handleNetworkErrors(e);
      rethrow;
    }
  }
}