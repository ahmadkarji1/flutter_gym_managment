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

  Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer ${auth.token ?? ""}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // -----------------------------------------------------------
  // 1. جلب الأعضاء (تم تحسين معالجة البيانات لضمان عدم الاختفاء)
  // -----------------------------------------------------------
  Future<void> fetchAndSetMembers({String query = ""}) async {
    if (auth.token == null) return;
    _setLoading(true);
    try {
      final url = Uri.parse('$_baseUrl/members?search=$query');
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // التأكد من أن السيرفر أرجع الحالة true وأن المفتاح members موجود
        if (responseData['status'] == true && responseData['members'] != null) {
          final List<dynamic> data = responseData['members'];
          _members = data.map((item) => Member.fromJson(item)).toList();
        } else {
          _members = []; // إذا لم يوجد نتائج، نفرغ القائمة بدلاً من تركها معلقة
        }
      } else {
        debugPrint("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      _setLoading(false); // notifyListeners مستدعى داخل setLoading
    }
  }

  // -----------------------------------------------------------
  // 2. إضافة عضو جديد (يستدعي fetch لضمان التحديث والترتيب)
  // -----------------------------------------------------------
  Future<void> addMember(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register_member'),
        headers: _getHeaders(),
        body: json.encode(data),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // تحديث القائمة فوراً من السيرفر لضمان ظهور العضو الجديد
        await fetchAndSetMembers();
      } else {
        throw Exception(responseData['message'] ?? 'فشل إضافة المشترك');
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------------------------------
  // 3. تعديل عضو (تم دمج النسختين في دالة واحدة صحيحة)
  // -----------------------------------------------------------
  Future<void> editMember(int memberId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/members/$memberId'),
        headers: _getHeaders(),
        body: json.encode(data),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // تحديث القائمة ليعاد ترتيب الأعضاء حسب الأيام المعدلة
        await fetchAndSetMembers();
      } else {
        throw Exception(responseData['message'] ?? 'فشل تعديل البيانات');
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // -----------------------------------------------------------
  // 4. حذف عضو
  // -----------------------------------------------------------
  Future<void> deleteMember(int memberId) async {
    _setLoading(true);
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/members/$memberId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        // حذف محلي سريع لتحسين تجربة المستخدم
        _members.removeWhere((m) => m.id == memberId);
        notifyListeners();
      } else {
        throw Exception("فشل الحذف من السيرفر");
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}