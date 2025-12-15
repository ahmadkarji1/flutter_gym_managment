import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/member_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/main_app_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        // 1. ✅ تهيئة AuthProvider أولاً
        ChangeNotifierProvider(create: (context) => AuthProvider()..tryAutoLogin()),

        // 2. ✅ تهيئة MemberProvider باستخدام ChangeNotifierProxyProvider
        // هذا يضمن أن MemberProvider يستطيع الوصول إلى AuthProvider
        ChangeNotifierProxyProvider<AuthProvider, MemberProvider>(
          // عند الإنشاء لأول مرة: (يمكن استدعاء AuthProvider من السياق)
          create: (context) => MemberProvider(context.read<AuthProvider>()),

          // عند تحديث AuthProvider (مثلاً، تسجيل الخروج/الدخول)، قم بتحديث MemberProvider:
          update: (context, auth, previousMemberProvider) {
            // نمرر كائن AuthProvider المحدث إلى MemberProvider
            return MemberProvider(auth);
          },
        ),
      ],
      child: const GymApp(),
    ),
  );
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      // 💡 منطق عرض الشاشة الرئيسي بناءً على حالة المصادقة
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // يتم عرض شاشة البداية (Splash) أثناء محاولة تسجيل الدخول التلقائي
          if (auth.isLoading && !auth.isAuth && auth.user == null) {
            return const SplashScreen();
          }
          // إذا تمت المصادقة، انتقل إلى الواجهة الرئيسية، وإلا فانتقل إلى تسجيل الدخول
          return auth.isAuth ? const MainAppLayout() : const SignInScreen();
        },
      ),
    );
  }
}