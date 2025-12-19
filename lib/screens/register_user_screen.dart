import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../models/member.dart';
import '../widgets/input_field.dart';

// الثيم اللوني الموحد
const Color _kBackgroundColor = Color(0xFF121212);
const Color _kCardColor = Color(0xFF1E1E1E);
const Color _kPrimaryColor = Color(0xFFFF8800);
const Color _kTextColor = Colors.white;
const Color _kErrorColor = Color(0xFFCF6679);
const Color _kSuccessColor = Color(0xFF00C853);

class RegisterUserScreen extends StatefulWidget {
  final Member? member;
  const RegisterUserScreen({super.key, this.member});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _daysController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // إذا كانت العملية "تعديل"، نملأ الحقول بالبيانات الحالية
    if (widget.member != null) {
      _nameController.text = widget.member!.name;
      _emailController.text = widget.member!.email;
      // عرض الأيام المتبقية الحالية كقيمة افتراضية عند التعديل
      _daysController.text = widget.member!.remainingDays.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _daysController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // نستخدم listen: true هنا لمتابعة حالة isLoading فقط
    final provider = Provider.of<MemberProvider>(context);
    final String title = widget.member != null ? 'تعديل بيانات المشترك' : 'تسجيل مشترك جديد';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBackgroundColor,
        appBar: AppBar(
          title: Text(title, style: const TextStyle(color: _kTextColor)),
          backgroundColor: _kCardColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: _kPrimaryColor),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(25),
            children: [
              // حقل الاسم
              CustomInputField(
                  controller: _nameController,
                  label: 'الاسم الكامل',
                  icon: Icons.person,
                  themeColor: _kPrimaryColor
              ),
              const SizedBox(height: 18),

              // حقل الايميل
              CustomInputField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email,
                  themeColor: _kPrimaryColor,
                  keyboardType: TextInputType.emailAddress
              ),
              const SizedBox(height: 18),

              // حقل أيام الاشتراك
              CustomInputField(
                  controller: _daysController,
                  label: 'مدة الاشتراك (بالأيام)',
                  icon: Icons.history_toggle_off,
                  themeColor: _kPrimaryColor,
                  keyboardType: TextInputType.number
              ),

              // حقل كلمة المرور (يظهر فقط عند إضافة عضو جديد)
              if (widget.member == null) ...[
                const SizedBox(height: 18),
                CustomInputField(
                    controller: _passwordController,
                    label: 'كلمة المرور',
                    icon: Icons.lock,
                    themeColor: _kPrimaryColor,
                    obscureText: true
                ),
              ],

              const SizedBox(height: 40),

              // زر الحفظ / التعديل
              ElevatedButton(
                onPressed: provider.isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: provider.isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: _kTextColor, strokeWidth: 2),
                )
                    : Text(
                  widget.member != null ? 'تحديث البيانات' : 'إتمام التسجيل',
                  style: const TextStyle(
                      color: _kTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // دالة معالجة البيانات وإرسالها للسيرفر
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    final days = int.tryParse(_daysController.text.trim());
    if (days == null || days < 0) {
      _showSnackBar('الرجاء إدخال عدد أيام صحيح (0 أو أكثر)', _kErrorColor);
      return;
    }

    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'subscription_days': days, // الربط مع Laravel
    };

    final memberProvider = Provider.of<MemberProvider>(context, listen: false);

    try {
      if (widget.member == null) {
        // إضافة عضو جديد
        data['password'] = _passwordController.text;
        data['role'] = 'member';
        await memberProvider.addMember(data);
        _showSnackBar('تم تسجيل المشترك بنجاح', _kSuccessColor);
      } else {
        // تعديل عضو حالي
        await memberProvider.editMember(widget.member!.id, data);
        _showSnackBar('تم تحديث البيانات بنجاح', _kSuccessColor);
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        _showSnackBar('خطأ: ${e.toString().replaceAll('Exception: ', '')}', _kErrorColor);
      }
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: bgColor),
    );
  }
}