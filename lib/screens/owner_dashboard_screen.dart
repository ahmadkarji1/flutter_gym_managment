import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_user_screen.dart';
import 'member_list_screen.dart';

// تعريف الألوان الأساسية للثيم الناري الداكن
const Color _kBackgroundColor = Color(0xFF121212);    // الأسود الداكن (الخلفية)
const Color _kCardColor = Color(0xFF1E1E1E);          // رمادي داكن للبطاقة والعنوان
const Color _kPrimaryColor = Color(0xFFFF8800);       // البرتقالي الناري (اللون الأساسي)
const Color _kTextColor = Colors.white;              // الأبيض (لون النص الرئيسي)
const Color _kSecondaryTextColor = Color(0xFFAAAAAA); // الرمادي الفاتح للنص الثانوي

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  Color? get _kInactiveColor => null;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBackgroundColor, // 1. تطبيق لون الخلفية الداكن
        appBar: AppBar(
          title: const Text(
            'لوحة تحكم المدير',
            style: TextStyle(color: _kTextColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _kCardColor, // 2. لون شريط التطبيق الداكن
          elevation: 0, // إزالة الظل
          iconTheme: const IconThemeData(color: _kPrimaryColor), // لون الأيقونات ناري
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: _kPrimaryColor), // 3. لون أيقونة الخروج ناري
              onPressed: () => authProvider.logout(),
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildWelcomeCard(user?.name ?? 'المدير', user?.email ?? ''),
              const SizedBox(height: 30),

              // بطاقة إضافة عضو جديد
              _buildAdminActionCard(
                  context,
                  title: 'إضافة عضو جديد',
                  subtitle: 'تسجيل مشتركين جدد.',
                  icon: Icons.person_add_alt_1, // تغيير الأيقونة لأجمل
                  color: _kPrimaryColor, // اللون الناري
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterUserScreen()))
              ),
              const SizedBox(height: 15),

              // بطاقة قائمة الأعضاء
              _buildAdminActionCard(
                  context,
                  title: 'قائمة الأعضاء',
                  subtitle: 'عرض وتعديل الأعضاء.',
                  icon: Icons.group,
                  color: _kPrimaryColor, // اللون الناري
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MemberListScreen()))
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. تعديل بطاقة الترحيب (Welcome Card) لتناسب الثيم الداكن
  Widget _buildWelcomeCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      // 💡 تغيير الخلفية إلى لون البطاقة الداكن
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _kPrimaryColor.withOpacity(0.3)), // إضافة حد ناري خفيف
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                'أهلاً بك، $name',
                textAlign: TextAlign.center,
                // 💡 لون النص الرئيسي أبيض
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kTextColor)
            ),
            const SizedBox(height: 5),
            Text(
              email,
              textAlign: TextAlign.center,
              // 💡 لون النص الثانوي رمادي فاتح
              style: const TextStyle(color: _kSecondaryTextColor, fontSize: 14),
            )
          ]
      ),
    );
  }

  // 5. تعديل بطاقة الإجراءات (Action Card) لتناسب الثيم الداكن
  Widget _buildAdminActionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        // 💡 تغيير الخلفية إلى لون البطاقة الداكن
        decoration: BoxDecoration(
          color: _kCardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)], // ظل خفيف
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30), // أيقونة أكبر قليلاً
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      title,
                      // 💡 لون النص الرئيسي أبيض وسميك
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kTextColor)
                  ),
                  const SizedBox(height: 4),
                  Text(
                      subtitle,
                      // 💡 لون النص الثانوي رمادي فاتح
                      style: const TextStyle(color: _kSecondaryTextColor, fontSize: 13)
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: _kInactiveColor, size: 18), // سهم رمادي
          ],
        ),
      ),
    );
  }
}