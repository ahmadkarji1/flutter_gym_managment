import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/input_field.dart'; // أصبح الآن CustomInputField

// تعريف الألوان الأساسية للثيم الناري الداكن
const Color _kBackgroundColor = Color(0xFF121212);    // الأسود الداكن (الخلفية)
const Color _kCardColor = Color(0xFF1E1E1E);          // رمادي داكن للبطاقة (Card)
const Color _kPrimaryColor = Color(0xFFFF8800);       // البرتقالي الناري (اللون الأساسي)
const Color _kTextColor = Colors.white;              // الأبيض (لون النص الرئيسي)
const Color _kErrorColor = Color(0xFFCF6679);         // الأحمر الداكن للأخطاء

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  // ✅ تهيئة متحكمات النصوص بدون قيم افتراضية
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _errorMessage = null);

    String? error = await authProvider.signIn(_emailController.text, _passwordController.text);

    if (!mounted) return;

    if (error != null) {
      setState(() => _errorMessage = error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(color: _kTextColor)),
          backgroundColor: _kErrorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBackgroundColor,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: _kCardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                        'تسجيل الدخول',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: _kPrimaryColor
                        )
                    ),
                    const SizedBox(height: 35),
                    if (_errorMessage != null)
                      Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _kErrorColor)
                      ),

                    // حقل البريد الإلكتروني (باستخدام CustomInputField)
                    CustomInputField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      themeColor: _kPrimaryColor,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),

                    // حقل كلمة المرور (باستخدام CustomInputField مع obscureText)
                    CustomInputField(
                        controller: _passwordController,
                        label: 'كلمة المرور',
                        icon: Icons.lock_outline,
                        themeColor: _kPrimaryColor,
                        obscureText: true // هذا المفتاح يفعل زر الرؤية
                    ),
                    const SizedBox(height: 40),

                    // زر تسجيل الدخول
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: _kTextColor)
                          : const Text('دخول', style: TextStyle(color: _kTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}