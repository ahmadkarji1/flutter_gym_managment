// في ملف lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  // ✅ لا يوجد حقول مطلوبة هنا (No required fields)
  // إذا كان لديك حقول قديمة مثل 'this.remainSession' يجب حذفها.
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user; // جلب بيانات المستخدم من البروفايدر

    // إذا لم يكن هناك مستخدم، نخرج (رغم أن main_app_layout يتحقق من ذلك)
    if (user == null) {
      return const Center(child: Text("لا يوجد بيانات مستخدم.", style: TextStyle(color: Colors.white)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        actions: [
          // زر تسجيل الخروج
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFFF8800)),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFFF8800),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),

            // الاسم
            _buildInfoCard(
              icon: Icons.person_outline,
              label: 'الاسم',
              value: user.name,
            ),
            const SizedBox(height: 15),

            // البريد الإلكتروني
            _buildInfoCard(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني',
              value: user.email,
            ),
            const SizedBox(height: 15),

            // الدور
            _buildInfoCard(
              icon: Icons.shield_outlined,
              label: 'الدور',
              value: user.role ?? 'عضو',
            ),
            const SizedBox(height: 40),

            // ملاحظة للأعضاء (هذه الشاشة مخصصة للمالك/الإدارة)
            if (user.role == 'member')
              const Text(
                'ملاحظة: تظهر الأيام المتبقية في شاشة "الأيام المتبقية" الرئيسية.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  // ويدجت مساعدة لعرض البيانات بشكل جميل
  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // لون خلفية أغمق قليلاً
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF8800)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}