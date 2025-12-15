import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'owner_dashboard_screen.dart';
import 'profile_screen.dart' hide MemberHomeDashboard; // ✅ استيراد شاشة البروفايل (للمالك)
import 'member_list_screen.dart';
import 'weekly_schedule_screen.dart';
import 'member_home_dashboard.dart'; // ✅ استيراد شاشة الأيام المتبقية (للعضو)

// تعريف الألوان الأساسية للثيم الناري الداكن
const Color _kBackgroundColor = Color(0xFF121212);    // الأسود الداكن (الخلفية)
const Color _kPrimaryColor = Color(0xFFFF8800);       // البرتقالي الناري (اللون الأساسي)
const Color _kInactiveColor = Color(0xFFAAAAAA);      // الرمادي الفاتح للأيقونات غير النشطة
const Color _kTextColor = Colors.white;              // الأبيض (لون النص الرئيسي)


class MainAppLayout extends StatefulWidget {
  const MainAppLayout({super.key});

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout> {
  int _selectedIndex = 0; // مؤشر الشاشة المحددة

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 💡 التحقق من حالة التحميل أو عدم وجود مستخدم لتجنب خطأ 'Null' is not a subtype of 'Widget'
    if (authProvider.user == null) {
      // إذا لم يتم تسجيل الدخول بعد أو كان يتم التحميل
      return const Scaffold(
        backgroundColor: _kBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: _kPrimaryColor),
        ),
      );
    }

    // --------------------------------------------------------
    // قائمة الشاشات الخاصة بالمالك (Owner)
    // --------------------------------------------------------
    final List<Widget> ownerScreens = [
      const OwnerDashboardScreen(),
      const WeeklyScheduleScreen(),
      const MemberListScreen(),
       ProfileScreen(), // ✅ أصبح const الآن بعد التأكد من أنه لا يتطلب حقولاً
    ];

    // --------------------------------------------------------
    // قائمة الشاشات الخاصة بالعضو (Member)
    // --------------------------------------------------------
    final List<Widget> memberScreens = [
      const WeeklyScheduleScreen(),
      MemberHomeDashboard(), // ✅ استخدام الشاشة الجديدة للأيام المتبقية
    ];

    // تحديد قائمة الشاشات وعنصر الشريط السفلي بناءً على الدور
    final List<Widget> currentScreens = authProvider.isOwner ? ownerScreens : memberScreens;

    // بناء عناصر الشريط السفلي
    final List<BottomNavigationBarItem> ownerItems = const <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'الرئيسية'),
      BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'التدريب'),
      BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'الأعضاء'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'حسابي'),
    ];

    final List<BottomNavigationBarItem> memberItems = const <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'التدريب'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'الأيام المتبقية'),
    ];

    final List<BottomNavigationBarItem> currentItems = authProvider.isOwner ? ownerItems : memberItems;

    // 💡 نقطة مهمة: عند التبديل بين قوائم الشاشات (مالك/عضو)، يجب إعادة تعيين الفهرس إلى الصفر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex >= currentScreens.length) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: currentScreens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          // تطبيق الثيم الناري الداكن
          backgroundColor: _kBackgroundColor,
          selectedItemColor: _kPrimaryColor,
          unselectedItemColor: _kInactiveColor,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,

          items: currentItems,
        ),
      ),
    );
  }
}

// ❌ تم حذف التعريف الخاطئ للدالة ProfileScreen() {}