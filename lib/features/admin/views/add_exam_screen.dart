import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../exam/data/models/exam_model.dart';
import '../../exam/data/services/firestore_quiz_service.dart';

class AddExamScreen extends StatefulWidget {
  final String? examId;

  const AddExamScreen({super.key, this.examId});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _negativeMarkingController = TextEditingController(text: '0.25');

  bool _isSaving = false;
  bool _isLoading = true;
  DateTime? _scheduledDate;
  ExamStatus _examStatus = ExamStatus.draft;

  bool get _isEditing => widget.examId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExam();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadExam() async {
    try {
      final exam = await FirestoreQuizService().getExam(widget.examId!);
      if (exam == null || !mounted) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() {
        _titleController.text = exam.title;
        _durationController.text = (exam.durationSeconds ~/ 60).toString();
        _negativeMarkingController.text = exam.negativeMarks.toString();
        _scheduledDate = exam.scheduledDate;
        _examStatus = exam.status;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _negativeMarkingController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _scheduledDate = date);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Please enter an exam title');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final examId = widget.examId ?? const Uuid().v4();
      final exam = ExamModel(
        examId: examId,
        title: _titleController.text.trim(),
        durationSeconds: (int.tryParse(_durationController.text) ?? 30) * 60,
        negativeMarks:
            double.tryParse(_negativeMarkingController.text) ?? 0.25,
        status: _examStatus,
        scheduledDate: _scheduledDate,
      );

      final service = FirestoreQuizService();
      if (_isEditing) {
        await service.updateExam(exam);
        _showSnack('Exam updated');
        if (mounted) context.pop();
      } else {
        await service.saveExam(exam);
        _showSnack('Exam created');
        if (mounted) context.go('/admin/exam/$examId');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Exam')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Exam' : 'Add Exam')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ResponsiveWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Exam Title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _durationController,
                              decoration: const InputDecoration(
                                labelText: 'Duration (minutes)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.timer),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _negativeMarkingController,
                              decoration: const InputDecoration(
                                labelText: 'Negative Marks',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.remove_circle_outline),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ExamStatus>(
                        initialValue: _examStatus,
                        decoration: const InputDecoration(
                          labelText: 'Exam Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        items: ExamStatus.values
                            .map((s) => DropdownMenuItem(
                                value: s, child: Text(s.label)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _examStatus = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Scheduled Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _scheduledDate != null
                                ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                                : 'Not set',
                            style: TextStyle(
                              color: _scheduledDate != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (_scheduledDate != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _scheduledDate = null),
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Clear date'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Saving...'),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: Icon(_isEditing ? Icons.update : Icons.save),
                  label: Text(_isEditing ? 'Update Exam' : 'Create Exam'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
