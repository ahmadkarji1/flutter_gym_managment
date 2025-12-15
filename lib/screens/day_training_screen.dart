// في ملف lib/screens/day_training_screen.dart

import 'package:flutter/material.dart';
// ✅ استيراد خدمة التخزين التي فصلناها
import '../services/training_storage.dart';

// تعريف الألوان الأساسية للثيم الناري الداكن
const Color _kBackgroundColor = Color(0xFF121212);
const Color _kCardColor = Color(0xFF1E1E1E);
const Color _kPrimaryColor = Color(0xFFFF8800);
const Color _kTextColor = Colors.white;
const Color _kSecondaryTextColor = Color(0xFFAAAAAA);
const Color _kSuccessColor = Color(0xFF00C853);
const Color _kErrorColor = Color(0xFFCF6679);

class DayTrainingScreen extends StatefulWidget {
  final String dayName;
  final bool isOwner;

  const DayTrainingScreen({
    super.key,
    required this.dayName,
    required this.isOwner,
  });

  @override
  State<DayTrainingScreen> createState() => _DayTrainingScreenState();
}

class _DayTrainingScreenState extends State<DayTrainingScreen> {
  String _trainingContent = "لا توجد تدريبات محددة لهذا اليوم.";
  bool _isEditing = false;
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 💡 جلب المحتوى من نظام التخزين الوهمي (المفصول)
    _trainingContent = TrainingDataStorage.get(widget.dayName);
    _contentController.text = _trainingContent;
  }

  void _saveContent() {
    // ⚠️ في تطبيق حقيقي: يجب هنا استدعاء API لحفظ المحتوى على الخادم.
    // (مثلاً: TrainingProvider().updateTraining(widget.dayName, _contentController.text))

    // 💡 تحديث نظام التخزين الوهمي (لأغراض المحاكاة)
    TrainingDataStorage.update(widget.dayName, _contentController.text);

    setState(() {
      _trainingContent = _contentController.text;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ التدريب بنجاح!'),
        backgroundColor: _kSuccessColor,
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBackgroundColor,
        appBar: AppBar(
          title: Text('تدريب يوم ${widget.dayName}', style: const TextStyle(color: _kTextColor)),
          backgroundColor: _kCardColor,
          iconTheme: const IconThemeData(color: _kPrimaryColor),
          actions: [
            if (widget.isOwner) // المدير فقط يمكنه التعديل
              IconButton(
                icon: Icon(_isEditing ? Icons.save : Icons.edit, color: _kPrimaryColor),
                onPressed: () {
                  if (_isEditing) {
                    _saveContent();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
              ),
            if (widget.isOwner && _isEditing)
              IconButton(
                icon: const Icon(Icons.cancel, color: _kErrorColor),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _contentController.text = _trainingContent; // التراجع عن التعديلات
                  });
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kCardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _kPrimaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'التدريب المخصص ليوم ${widget.dayName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _kPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_isEditing)
                  TextFormField(
                    controller: _contentController,
                    maxLines: 15,
                    minLines: 5,
                    autofocus: true,
                    style: const TextStyle(color: _kTextColor),
                    decoration: InputDecoration(
                      hintText: 'أدخل تفاصيل التدريب هنا...',
                      hintStyle: const TextStyle(color: _kSecondaryTextColor),
                      fillColor: _kBackgroundColor,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kPrimaryColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kPrimaryColor, width: 2),
                      ),
                    ),
                  )
                else
                  Text(
                    _trainingContent,
                    style: const TextStyle(fontSize: 16, color: _kTextColor, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}