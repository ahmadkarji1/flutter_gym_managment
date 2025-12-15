import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../models/member.dart';
import '../widgets/input_field.dart'; // أصبح الآن CustomInputField

// تعريف الألوان الأساسية للثيم الناري الداكن
const Color _kBackgroundColor = Color(0xFF121212);    // الأسود الداكن (الخلفية)
const Color _kCardColor = Color(0xFF1E1E1E);          // رمادي داكن للبطاقة والعنوان
const Color _kPrimaryColor = Color(0xFFFF8800);       // البرتقالي الناري (اللون الأساسي)
const Color _kTextColor = Colors.white;              // الأبيض (لون النص الرئيسي)
const Color _kErrorColor = Color(0xFFCF6679);         // الأحمر الداكن للأخطاء

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
  // 1. ✅ تغيير اسم المتحكم إلى _daysController
  final _daysController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _nameController.text = widget.member!.name;
      _emailController.text = widget.member!.email;

      // 2. ✅ استخدام الحقل الجديد remainingDays من User/Member Model
      // نفترض أن Member Model تم تحديثه ليحتوي على remainingDays
      _daysController.text = widget.member!.remainingDays?.toString() ?? '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    // ✅ التخلص من المتحكم الجديد
    _daysController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // دالة بناء (build)
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MemberProvider>(context);

    final Color themeColor = _kPrimaryColor;
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
              CustomInputField(controller: _nameController, label: 'الاسم', icon: Icons.person, themeColor: themeColor),
              const SizedBox(height: 18),

              // حقل الايميل
              CustomInputField(controller: _emailController, label: 'الايميل', icon: Icons.email, themeColor: themeColor, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 18),

              // 3. ✅ تغيير الحقل إلى "عدد أيام الاشتراك" واستخدام المتحكم الجديد
              CustomInputField(
                  controller: _daysController, // استخدام المتحكم الجديد
                  label: 'عدد أيام الاشتراك', // تغيير النص المعروض في الواجهة
                  icon: Icons.calendar_today, // تغيير الأيقونة لتناسب الأيام
                  themeColor: themeColor,
                  keyboardType: TextInputType.number
              ),

              if (widget.member == null) ...[
                const SizedBox(height: 18),
                // حقل كلمة المرور (يظهر فقط عند التسجيل الجديد)
                CustomInputField(controller: _passwordController, label: 'كلمة المرور', icon: Icons.lock, themeColor: themeColor, obscureText: true)
              ],

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: provider.isLoading ? null : () async {
                  if (!_formKey.currentState!.validate()) return;

                  final daysText = _daysController.text.trim(); // استخدام المتحكم الجديد
                  final days = int.tryParse(daysText);

                  if (days == null || days < 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          // تغيير رسالة الخطأ
                            content: Text('الرجاء إدخال عدد صحيح موجب لأيام الاشتراك.'),
                            backgroundColor: _kErrorColor
                        ),
                      );
                    }
                    return;
                  }

                  // 4. ✅ تغيير المفتاح المرسل إلى الخادم إلى 'subscription_days'
                  final data = {
                    'name': _nameController.text,
                    'email': _emailController.text,
                    'subscription_days': days, // المفتاح الذي يتوقعه الخادم الآن
                  };

                  final memberProviderAction = Provider.of<MemberProvider>(context, listen: false);

                  try {
                    if (widget.member == null) {
                      data['password'] = _passwordController.text;
                      data['role'] = 'member';
                      await memberProviderAction.addMember(data);
                    } else {
                      await memberProviderAction.editMember(widget.member!.id, data);
                    }

                    if (mounted) Navigator.pop(context);

                  } catch (e) {
                    if (mounted) {
                      String errorMessage = e.toString().replaceFirst('Exception: ', '');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('فشل الحفظ: $errorMessage'),
                            backgroundColor: _kErrorColor
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: _kTextColor)
                    : Text(widget.member != null ? 'تعديل البيانات' : 'حفظ المشترك',
                    style: const TextStyle(color: _kTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}