import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  bool _isLoading = false;

  // الخصائص المطلوبة من قبل الشاشات
  String? get token => _token;
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuth => _token != null;

  // ✅ Getter لتحديد ما إذا كان المستخدم هو المالك
  bool get isOwner => _user?.role == 'owner' || _user?.role == 'admin';

  // 💡 تأكد من أن هذا الـ IP يطابق عنوان الخادم (Laravel)
  final String _baseUrl = 'http://192.168.1.165:8000/api';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ✅ الميثود المطلوبة في شاشة تسجيل الدخول
  Future<String?> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final response = await http.post(
        // 1. ✅ تم تصحيح المسار إلى /signin
        Uri.parse('$_baseUrl/signin'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          // 3. ✅ إضافة device_name لتلبية متطلبات الخادم (خطأ 422)
          'device_name': 'flutter_mobile_app',
        }),
      );

      // 💡 طباعة الاستجابة للتشخيص في حال وجود خطأ آخر
      print("API Response Status: ${response.statusCode}");
      print("API Response Body: ${response.body}");

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // 2. ✅ تصحيح اسم المفتاح المتوقع من الخادم (يجب أن يكون 'token')
        _token = responseData['token'];

        // التحقق من أن الخادم أرسل بيانات المستخدم
        if (responseData.containsKey('user')) {
          _user = User.fromJson(responseData['user']);
        }

        notifyListeners();
        return null; // لا يوجد خطأ
      } else {
        // إذا كان هناك خطأ (مثل 401 Unauthorised)
        return responseData['message'] ?? 'فشل تسجيل الدخول';
      }
    } catch (e) {
      // إذا فشل الاتصال أو فشل تحليل الـ JSON
      print("Caught Error during SignIn: $e");
      return 'خطأ في الاتصال بالسيرفر';
    } finally {
      _setLoading(false);
    }
  }

  // ✅ الميثود المطلوبة في main.dart لتسجيل الدخول التلقائي
  Future<bool> tryAutoLogin() async {
    // يمكن هنا إضافة منطق SharedPreferences لاحقاً
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    notifyListeners();
  }
}