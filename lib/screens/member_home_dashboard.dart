import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// تعريف الألوان الأساسية للثيم الناري الداكن
const Color _kBackgroundColor = Color(0xFF121212);    // الأسود الداكن
const Color _kPrimaryColor = Color(0xFFFF8800);       // البرتقالي الناري
const Color _kExpiredColor = Color(0xFFCF6679);       // أحمر داكن (لانتهاء الصلاحية)
const Color _kTextColor = Colors.white;              // الأبيض

class MemberHomeDashboard extends StatelessWidget {
  const MemberHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب بيانات المستخدم من AuthProvider
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    // الحصول على الأيام المتبقية، الافتراضي هو 0
    final int days = user?.remainingDays ?? 0;

    // تحديد اللون والرسالة بناءً على حالة الاشتراك
    final Color indicatorColor = days > 0 ? _kPrimaryColor : _kExpiredColor;
    final String statusMessage = days > 0 ? 'متبقي على نهاية اشتراكك' : 'انتهى اشتراكك!';
    final String motivationalMessage = days > 0 ? 'استمر في العطاء، القوة بداخلك!' : 'الرجاء تجديد اشتراكك!';

    return Scaffold(
      backgroundColor: _kBackgroundColor, // خلفية داكنة
      body: Stack(
        children: [
          // 1. تأثير الوهج الناري (الـ Glow Effect) في المنتصف
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: indicatorColor.withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // 2. المحتوى الرئيسي (الرقم والرسالة)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // رسالة الحالة
                Text(
                  statusMessage,
                  style: TextStyle(
                    color: days > 0 ? Colors.white70 : _kExpiredColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // الدائرة التي تحتوي على عداد الأيام
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // إطار خارجي بلون ناري/أحمر حسب الحالة
                    border: Border.all(color: indicatorColor, width: 4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$days',
                        style: TextStyle(
                          color: indicatorColor, // لون النص داخل الدائرة
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        // تحسين بسيط لـ "يوم" أو "أيام"
                        days == 1 ? 'يوم' : 'أيام',
                        style: const TextStyle(color: _kTextColor, fontSize: 22),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                Text(
                  'كابتن: ${user?.name ?? ""}',
                  style: const TextStyle(color: _kTextColor, fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Text(
                  motivationalMessage,
                  style: TextStyle(
                      color: indicatorColor,
                      fontStyle: FontStyle.italic
                  ),
                ),
              ],
            ),
          ),

          // 3. زر تسجيل الخروج في الأعلى
          Positioned(
            top: 50,
            left: 20, // (الاتجاه RTL)
            child: IconButton(
              icon: Icon(Icons.logout, color: indicatorColor),
              onPressed: () => auth.logout(),
            ),
          ),
        ],
      ),
    );
  }
}