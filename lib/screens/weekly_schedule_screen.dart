import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/training_storage.dart';
import 'day_training_screen.dart';
import 'day_training_screen.dart' show TrainingDataStorage; // استيراد نظام التخزين من ملف التفاصيل

// تعريف الألوان الأساسية للثيم الناري الداكن
const Color _kBackgroundColor = Color(0xFF121212);
const Color _kCardColor = Color(0xFF1E1E1E);
const Color _kPrimaryColor = Color(0xFFFF8800);
const Color _kTextColor = Colors.white;
const Color _kSecondaryTextColor = Color(0xFFAAAAAA);

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  Map<String, String> _weeklyTrainingData = {};
  bool _isLoading = true;

  final List<String> daysOfWeek = const [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  Future<void> _fetchWeeklySchedule() async {
    setState(() {
      _isLoading = true;
    });

    // محاكاة وقت التحميل
    await Future.delayed(const Duration(milliseconds: 500));

    // جلب البيانات المحدثة من نظام التخزين المركزي
    final newSchedule = {
      'الأحد': TrainingDataStorage.get('الأحد'),
      'الاثنين': TrainingDataStorage.get('الاثنين'),
      'الثلاثاء': TrainingDataStorage.get('الثلاثاء'),
      'الأربعاء': TrainingDataStorage.get('الأربعاء'),
      'الخميس': TrainingDataStorage.get('الخميس'),
      'الجمعة': TrainingDataStorage.get('الجمعة'),
      'السبت': TrainingDataStorage.get('السبت'),
    };

    setState(() {
      _weeklyTrainingData = newSchedule;
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchWeeklySchedule();
  }


  @override
  Widget build(BuildContext context) {
    final isOwner = Provider.of<AuthProvider>(context).isOwner;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBackgroundColor,
        appBar: AppBar(
          title: const Text('الجدول الأسبوعي للتدريب', style: TextStyle(color: _kTextColor)),
          backgroundColor: _kCardColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: _kPrimaryColor),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: _kPrimaryColor),
              onPressed: _isLoading ? null : _fetchWeeklySchedule, // زر تحديث
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimaryColor))
            : RefreshIndicator(
          onRefresh: _fetchWeeklySchedule,
          color: _kPrimaryColor,
          child: GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.2,
            ),
            itemCount: daysOfWeek.length,
            itemBuilder: (context, index) {
              final day = daysOfWeek[index];
              final trainingContent = _weeklyTrainingData[day] ?? "لا يوجد محتوى";
              final contentSnippet = trainingContent.substring(0, trainingContent.length > 40 ? 40 : trainingContent.length);

              return _buildDayCard(context, day, isOwner, contentSnippet);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, String day, bool isOwner, String contentSnippet) {
    final currentDayName = _getCurrentDayName();
    final isToday = day == currentDayName;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DayTrainingScreen(
              dayName: day,
              isOwner: isOwner,
            ),
          ),
        );
        _fetchWeeklySchedule(); // إعادة جلب البيانات عند العودة
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kCardColor,
          borderRadius: BorderRadius.circular(15),
          border: isToday
              ? Border.all(color: _kPrimaryColor, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.run_circle_outlined,
              color: isToday ? _kPrimaryColor : _kSecondaryTextColor,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              day,
              style: TextStyle(
                color: isToday ? _kPrimaryColor : _kTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              contentSnippet + (contentSnippet.length >= 40 ? '...' : ''),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kSecondaryTextColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDayName() {
    final now = DateTime.now();
    switch (now.weekday) {
      case 1: return 'الاثنين';
      case 2: return 'الثلاثاء';
      case 3: return 'الأربعاء';
      case 4: return 'الخميس';
      case 5: return 'الجمعة';
      case 6: return 'السبت';
      case 7: return 'الأحد';
      default: return '';
    }
  }
}