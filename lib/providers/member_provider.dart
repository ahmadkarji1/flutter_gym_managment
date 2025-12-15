import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/member.dart';
import 'auth_provider.dart';

class MemberProvider with ChangeNotifier {
  final String _baseUrl = 'http://192.168.1.165:8000/api';
  List<Member> _members = [];
  bool _isLoading = false;

  final AuthProvider auth;
  MemberProvider(this.auth);

  List<Member> get members => _members;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // دالة مساعدة لإنشاء الـ Headers المشتركة
  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer ${auth.token!}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // ✅ الإضافة الضرورية لحل مشكلة 302 Redirect في Laravel
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  // جلب الأعضاء
  Future<void> fetchAndSetMembers() async {
    if (auth.token == null) return;
    _setLoading(true);

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/members'),
        headers: _getHeaders(),
      );

      print("Fetch Members Status: ${response.statusCode}");
      print("Fetch Members Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData.containsKey('members')) {
          final List<dynamic> data = responseData['members'];
          _members = data.map((item) => Member.fromJson(item)).toList();
        }
      }
    } catch (e) {
      print("Error fetching: $e");
    } finally {
      _setLoading(false);
    }
  }

  // إضافة الأعضاء
  Future<bool> addMember(Map<String, dynamic> data) async {
    if (auth.token == null) throw Exception('غير مصرح لك');
    _setLoading(true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register_member'),
        headers: _getHeaders(),
        body: json.encode(data),
      );

      print("Add Member Status: ${response.statusCode}");
      print("Add Member Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorBody = json.decode(response.body);
        String errorMessage = errorBody['message'] ?? 'فشل الحفظ (خطأ غير معروف)';
        if (errorBody.containsKey('errors')) {
          errorMessage = errorBody['errors'].values.first[0] ?? errorMessage;
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ تعديل الأعضاء (PATCH) - تم إضافة الـ Headers
  Future<void> editMember(int memberId, Map<String, dynamic> data) async {
    if (auth.token == null) throw Exception('غير مصرح لك');
    _setLoading(true);

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/members/$memberId'),
        headers: _getHeaders(), // استخدام الـ Headers الجديدة
        body: json.encode(data),
      );

      print("Edit Member Status: ${response.statusCode}");
      print("Edit Member Body: ${response.body}");

      if (response.statusCode == 200) {
        await fetchAndSetMembers(); // تحديث القائمة فوراً
      } else {
        final errorBody = json.decode(response.body);
        String errorMessage = errorBody['message'] ?? 'فشل التعديل (خطأ غير معروف)';
        if (errorBody.containsKey('errors')) {
          errorMessage = errorBody['errors'].values.first[0] ?? errorMessage;
        }

        throw Exception(errorMessage);
      }

    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // حذف الأعضاء (DELETE) - تم إضافة الـ Headers
  Future<void> deleteMember(int memberId) async {
    if (auth.token == null) return;
    _setLoading(true);
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/members/$memberId'),
        headers: _getHeaders(), // استخدام الـ Headers الجديدة
      );

      print("Delete Member Status: ${response.statusCode}");
      print("Delete Member Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        _members.removeWhere((m) => m.id == memberId);
        notifyListeners();
      } else {
        throw Exception('فشل الحذف: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}