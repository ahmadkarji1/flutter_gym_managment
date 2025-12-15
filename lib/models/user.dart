class User {
  final int id;
  final String name;
  final int remainingDays; // ✅ الحقل الجديد: عدد الأيام المتبقية
  final String email;
  final String? role;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.profileImage,
    required this.remainingDays, // ✅ أصبح مطلوباً الآن
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // 💡 ملاحظة: يجب أن يتطابق هذا الحقل مع المفتاح الذي يرسله Laravel
    // Laravel يرسله كـ 'remaining_days' بعد الحساب في الـ AuthController
    final int days = (json['remaining_days'] as int?) ?? 0;

    return User(
      // يجب أن تكون القيم متطابقة مع أنواع البيانات في JSON
      id: (json['id'] as int?) ?? -1,
      name: (json['name'] as String?) ?? 'مستخدم غير معروف',
      email: (json['email'] as String?) ?? 'no_email@domain.com',
      role: json['role'] as String?,
      profileImage: json['profileImage'] as String?,

      // ✅ ربط الحقل المحسوب
      remainingDays: days,
    );
  }
}

// ❌ تم حذف الدالة الزائدة get remainSession من هنا.