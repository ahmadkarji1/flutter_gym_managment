import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import '../services/training_data_storage.dart';
import '../providers/auth_provider.dart';
import '../services/training_storage.dart';

class DayTrainingScreen extends StatefulWidget {
  final String dayName;
  final bool isOwner;
  final int? sessionId; // يمكن أن يكون null للجديد

  const DayTrainingScreen({super.key, required this.dayName, required this.isOwner, this.sessionId});

  @override
  State<DayTrainingScreen> createState() => _DayTrainingScreenState();
}

class _DayTrainingScreenState extends State<DayTrainingScreen> {
  final _contentController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  int? _activeSessionId;

  @override
  void initState() {
    super.initState();
    _activeSessionId = widget.sessionId;
    if (_activeSessionId != null && _activeSessionId != 0) {
      _loadData();
    } else {
      if (widget.isOwner) _isEditing = true;
    }
  }

  Future<void> _loadData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    setState(() => _isLoading = true);
    final sessions = await TrainingDataStorage.fetchAllTrainings(token!);
    final current = sessions.firstWhere((s) => s['id'] == _activeSessionId, orElse: () => null);
    if (current != null) {
      _contentController.text = current['description'] ?? "";
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    setState(() => _isLoading = true);

    bool success;

    // إذا كان الـ sessionId نل أو صفر، نقوم بعملية إضافة (POST)
    if (widget.sessionId == null || widget.sessionId == 0) {
      success = await TrainingDataStorage.saveNewTraining(token!, {
        'name': 'تدريب ${widget.dayName}',
        'day': widget.dayName,
        'description': _contentController.text,
        'starts_at': '09:00:00',
        'finishes_at': '10:00:00',
      });
    } else {
      // إذا كان موجوداً، نقوم بعملية تعديل (PUT)
      success = await TrainingDataStorage.updateInDatabase(token!, widget.sessionId!, {
        'description': _contentController.text,
      });
    }

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم الحفظ بنجاح")));
      Navigator.pop(context, true); // نرسل true لنخبر الشاشة السابقة بضرورة التحديث
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("يوم ${widget.dayName}"),
        actions: [
          if (widget.isOwner) IconButton(icon: Icon(_isEditing ? Icons.save : Icons.edit), onPressed: () => _isEditing ? _save() : setState(() => _isEditing = true))
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _contentController,
          enabled: _isEditing,
          maxLines: 10,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "ادخل تفاصيل التدريب...", filled: true, fillColor: Color(0xFF1E1E1E)),
        ),
      ),
    );
  }
}