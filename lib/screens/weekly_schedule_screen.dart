import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/training_storage.dart';
import 'day_training_screen.dart';

// (الألوان ثابتة كما هي في كودك الأصلي)
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
  // تخزين البيانات: اليوم -> {id, content}
  Map<String, Map<String, dynamic>> _weeklyTrainingData = {};
  bool _isLoading = true;

  final List<String> daysOfWeek = const [
    'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت',
  ];

  // ✅ جلب البيانات من السيرفر وتحويلها لتناسب الواجهة
  Future<void> _fetchWeeklySchedule() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      // استدعاء السيرفر
      final List<dynamic> sessions = await TrainingDataStorage.fetchAllTrainings(token);

      Map<String, Map<String, dynamic>> tempSchedule = {};

      for (var day in daysOfWeek) {
        // البحث عن الجلسة المطابقة لليوم في البيانات القادمة من السيرفر
        final session = sessions.firstWhere(
              (s) => s['day'].toString().trim() == day,
          orElse: () => null,
        );

        if (session != null) {
          tempSchedule[day] = {
            'id': session['id'],
            'content': session['description'] ?? "لا يوجد وصف",
          };
        } else {
          tempSchedule[day] = {
            'id': null,
            'content': "لا توجد تدريبات محددة لهذا اليوم.",
          };
        }
      }

      setState(() {
        _weeklyTrainingData = tempSchedule;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading schedule: $e");
    }
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
          title: const Text('الجدول الأسبوعي', style: TextStyle(color: _kTextColor)),
          backgroundColor: _kCardColor,
          iconTheme: const IconThemeData(color: _kPrimaryColor),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: _kPrimaryColor),
              onPressed: _isLoading ? null : _fetchWeeklySchedule,
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
              childAspectRatio: 1.1,
            ),
            itemCount: daysOfWeek.length,
            itemBuilder: (context, index) {
              final day = daysOfWeek[index];
              final sessionData = _weeklyTrainingData[day]!;

              return _buildDayCard(
                  context,
                  day,
                  isOwner,
                  sessionData['content'],
                  sessionData['id']
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, String day, bool isOwner, String content, int? id) {
    final isToday = day == _getCurrentDayName();
    final contentSnippet = content.length > 35 ? "${content.substring(0, 35)}..." : content;

    return InkWell(
      onTap: () async {
        if (id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('هذه الجلسة غير مسجلة في السيرفر'))
          );
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DayTrainingScreen(
              dayName: day,
              isOwner: isOwner,
              sessionId: id, // ✅ مررنا الـ ID الحقيقي القادم من MySQL
            ),
          ),
        );
        _fetchWeeklySchedule();
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kCardColor,
          borderRadius: BorderRadius.circular(15),
          border: isToday ? Border.all(color: _kPrimaryColor, width: 2) : null,
          boxShadow: [
            if (isToday) BoxShadow(color: _kPrimaryColor.withOpacity(0.3), blurRadius: 10)
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isToday ? Icons.stars : Icons.calendar_today,
              color: isToday ? _kPrimaryColor : _kSecondaryTextColor,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              day,
              style: TextStyle(
                color: isToday ? _kPrimaryColor : _kTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                contentSnippet,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kSecondaryTextColor, fontSize: 10),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDayName() {
    final now = DateTime.now();
    const weekdays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    // تحويل weekday من Flutter (1=Mon..7=Sun) إلى ترتيب القائمة لدينا
    int index = now.weekday == 7 ? 0 : now.weekday;
    return weekdays[index];
  }
}