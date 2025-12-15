class Member {
  final int id;
  final String name;
  final String email;
  final int remainingDays;        // ✅ الحقل الصحيح: الأيام المتبقية
  final String? role;             // ✅ حقل اختياري (لتجنب Null Error)
  final String? profileImage;     // ✅ حقل اختياري (لتجنب Null Error)

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.remainingDays,
    this.role,
    this.profileImage,
  });

  // 🛠️ المصنع (Factory) لتحويل JSON إلى كائن Member
  factory Member.fromJson(Map<String, dynamic> json) {
    // 💡 طريقة آمنة لقراءة remaining_days من الخادم:
    // 1. يتحقق مما إذا كانت القيمة الموجودة نوعها int (وهو النوع المتوقع).
    // 2. إذا كانت int، يتم قراءتها مباشرة.
    // 3. إذا لم تكن int (مثل null أو String)، يتم تعيينها كـ 0 لتجنب خطأ 'Null is not a subtype of int'.
    final int days = json['remaining_days'] is int
        ? json['remaining_days'] as int
        : 0;

    return Member(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,

      remainingDays: days,

      // قراءة الحقول الاختيارية كـ String?
      role: json['role'] as String?,
      profileImage: json['profileImage'] as String?,
    );
  }

  // 📝 دالة copyWith لتحديث الكائن بشكل غير قابل للتغيير (Immutable)
  Member copyWith({String? name, String? email, int? remainingDays, String? role, String? profileImage}) {
    return Member(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,

      remainingDays: remainingDays ?? this.remainingDays,

      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}