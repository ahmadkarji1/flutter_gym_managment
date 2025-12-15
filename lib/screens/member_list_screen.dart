import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../providers/auth_provider.dart';
import '../models/member.dart';
import 'register_user_screen.dart';

// تعريف الألوان الأساسية للثيم الناري الداكن
const Color _kBackgroundColor = Color(0xFF121212);    // الأسود الداكن (الخلفية)
const Color _kCardColor = Color(0xFF1E1E1E);          // رمادي داكن للبطاقة والعنوان (عناصر القائمة)
const Color _kPrimaryColor = Color(0xFFFF8800);       // البرتقالي الناري (اللون الأساسي)
const Color _kTextColor = Colors.white;              // الأبيض (لون النص الرئيسي)
const Color _kSecondaryTextColor = Color(0xFFAAAAAA); // الرمادي الفاتح للنص الثانوي
const Color _kErrorColor = Color(0xFFCF6679);         // الأحمر الداكن (للحذف)

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});
  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {

  // يتم جلب البيانات عند البداية فقط
  @override
  void initState() {
    super.initState();
    // تأخير تنفيذ fetchAndSetMembers حتى يتم بناء الشجرة لمرة واحدة
    Future.microtask(() {
      final provider = Provider.of<MemberProvider>(context, listen: false);
      // التأكد من جلب البيانات فقط إذا كانت القائمة فارغة لتجنب الجلب المتكرر
      if (provider.members.isEmpty) {
        provider.fetchAndSetMembers();
      }
    });
  }

  // ✅ الإصلاح النهائي: استخدام WidgetsBinding.instance.addPostFrameCallback لحل مشكلة Looking up a deactivated widget's ancestor is unsafe.
  // دالة لجلب البيانات عند العودة من شاشة التعديل (بعد pop)
  Future<void> _navigateToEditScreen(BuildContext context, Member member) async {
    // نستخدم await لانتظار إغلاق شاشة التعديل
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RegisterUserScreen(member: member)
        )
    );

    // عند العودة، قم بتحديث القائمة
    // هذا يضمن أن الاستدعاء يحدث بعد اكتمال إطار الرسم التالي، مما يجعل الـ BuildContext آمناً وموصولاً.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MemberProvider>(context, listen: false).fetchAndSetMembers();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    // الاستماع إلى التغييرات في MemberProvider
    final memberProvider = Provider.of<MemberProvider>(context);
    // لا نحتاج للاستماع هنا
    final isOwner = Provider.of<AuthProvider>(context, listen: false).isOwner;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBackgroundColor, // تطبيق لون الخلفية الداكن
        appBar: AppBar(
          title: const Text('قائمة المشتركين', style: TextStyle(color: _kTextColor)),
          backgroundColor: _kCardColor, // لون شريط التطبيق الداكن
          elevation: 0,
          iconTheme: const IconThemeData(color: _kPrimaryColor), // أيقونة العودة نارية
          actions: [
            // زر تحديث (اختياري)
            IconButton(
              icon: const Icon(Icons.refresh, color: _kPrimaryColor),
              onPressed: memberProvider.isLoading ? null : () => memberProvider.fetchAndSetMembers(),
            )
          ],
        ),
        body: memberProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimaryColor)) // مؤشر تحميل ناري
            : memberProvider.members.isEmpty
            ? const Center(child: Text('لا يوجد أعضاء مسجلين.', style: TextStyle(color: _kSecondaryTextColor)))
            : ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 80), // ترك مسافة في الأسفل
          itemCount: memberProvider.members.length,
          itemBuilder: (context, index) {
            final member = memberProvider.members[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              child: Card( // استخدام Card لجعل العنصر بارزاً
                color: _kCardColor, // لون البطاقة الداكن
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // حواف مدورة
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: const Icon(Icons.person, color: _kPrimaryColor, size: 30), // أيقونة نارية

                  title: Text(
                      member.name,
                      style: const TextStyle(color: _kTextColor, fontWeight: FontWeight.bold, fontSize: 16) // نص أبيض وسميك
                  ),

                  subtitle: Text(
                      '${member.email} - أيام متبقية: ${member.remainingDays}',
                      style: const TextStyle(color: _kSecondaryTextColor, fontSize: 13) // نص رمادي فاتح
                  ),

                  trailing: isOwner
                      ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // زر التعديل
                        IconButton(
                            icon: const Icon(Icons.edit, color: _kPrimaryColor), // لون ناري للتعديل
                            onPressed: () => _navigateToEditScreen(context, member) // استخدام الدالة الجديدة
                        ),
                        // زر الحذف
                        IconButton(
                          icon: const Icon(Icons.delete, color: _kErrorColor), // لون أحمر للحذف
                          onPressed: () => _showDeleteConfirmation(context, memberProvider, member), // دالة تأكيد الحذف
                        ),
                      ]
                  )
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // دالة لإظهار مربع حوار تأكيد الحذف
  void _showDeleteConfirmation(BuildContext context, MemberProvider memberProvider, Member member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardColor, // خلفية داكنة لمربع الحوار
        title: const Text('تأكيد الحذف', style: TextStyle(color: _kTextColor)),
        content: Text('هل أنت متأكد أنك تريد حذف المشترك "${member.name}"؟', style: TextStyle(color: _kSecondaryTextColor)),
        actions: <Widget>[
          TextButton(
            child: const Text('إلغاء', style: TextStyle(color: _kSecondaryTextColor)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kErrorColor), // زر الحذف أحمر
            child: const Text('حذف', style: TextStyle(color: _kTextColor)),
            onPressed: () {
              memberProvider.deleteMember(member.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}