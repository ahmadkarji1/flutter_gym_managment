import 'package:flutter/material.dart';

// تعريف الألوان الأساسية للثيم الناري الداكن
const Color _kBackgroundColor = Color(0xFF121212);
const Color _kTextColor = Colors.white;
const Color _kPrimaryColor = Color(0xFFFF8800);
const Color _kSecondaryTextColor = Color(0xFFAAAAAA);

// تم تغيير الدالة المساعدة إلى عنصر StatefulWidget للتحكم في حالة إخفاء/إظهار كلمة المرور
class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color themeColor;
  final TextInputType keyboardType;
  final bool obscureText; // ستبقى القيمة الافتراضية 'false'
  final String? Function(String?)? validator;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.themeColor,
    this.keyboardType = TextInputType.text,
    this.obscureText = false, // تم الإبقاء على الخاصية
    this.validator,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> with SingleTickerProviderStateMixin {
  late bool _isPassword;
  late bool _isObscured;

  // للتحكم في الأيقونة (فقط في حالة كلمة المرور)
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _isPassword = widget.obscureText;
    _isObscured = widget.obscureText;

    // تهيئة المتحكم فقط إذا كان حقل كلمة مرور
    if (_isPassword) {
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    }
  }

  @override
  void dispose() {
    if (_isPassword) {
      _animationController.dispose();
    }
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() {
      _isObscured = !_isObscured;
      // تشغيل الحركة بناءً على حالة الرؤية
      if (_isObscured) {
        _animationController.reverse(); // إخفاء -> العين مغلقة
      } else {
        _animationController.forward();  // إظهار -> العين مفتوحة
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      style: const TextStyle(color: _kTextColor),
      obscureText: _isObscured, // التحكم بالرؤية باستخدام الحالة المحلية
      validator: widget.validator,

      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: widget.themeColor),
        hintStyle: const TextStyle(color: _kSecondaryTextColor),

        // الأيقونة الأمامية
        prefixIcon: Icon(widget.icon, color: widget.themeColor),

        // 💡 الميزة الاحترافية: زر الرؤية مع الحركة
        suffixIcon: _isPassword
            ? IconButton(
          onPressed: _toggleVisibility,
          icon: AnimatedBuilder( // استخدام AnimatedBuilder لإضفاء الحركة
            animation: _animation,
            builder: (context, child) {
              return Icon(
                // تغيير الأيقونة بشكل تدريجي (احترافي)
                _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Color.lerp(
                  _kSecondaryTextColor, // رمادي في حالة الإخفاء
                  widget.themeColor, // ناري في حالة الإظهار
                  _animation.value,
                ),
              );
            },
          ),
        )
            : null, // لا يوجد زر للحقول غير الخاصة بكلمة المرور

        // تصميم الحدود (بما يتناسب مع الثيم الناري)
        fillColor: _kBackgroundColor, // الخلفية الداكنة
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kSecondaryTextColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: widget.themeColor, width: 2), // الحد الناري عند التركيز
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}