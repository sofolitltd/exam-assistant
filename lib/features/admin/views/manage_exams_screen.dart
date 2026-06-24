import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/responsive_wrapper.dart';
import '../../exam/data/models/exam_model.dart';
import '../../exam/data/services/firestore_quiz_service.dart';

class ManageExamsScreen extends StatefulWidget {
  const ManageExamsScreen({super.key});

  @override
  State<ManageExamsScreen> createState() => _ManageExamsScreenState();
}

class _ManageExamsScreenState extends State<ManageExamsScreen> {
  List<ExamModel> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    try {
      final exams = await FirestoreQuizService().getExams();
      if (mounted) setState(() => _exams = exams);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteExam(String examId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam'),
        content: const Text(
          'This will permanently delete this exam and all its questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirestoreQuizService().deleteExamCascade(examId);
      _showSnack('Exam deleted');
      _loadExams();
    } catch (e) {
      _showSnack('Error deleting: $e');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Exams')),
      body: ResponsiveWrapper(child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/exam/add');
          _loadExams();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Exam'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_exams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No exams yet',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first exam',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),

            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExams,
      child: ListView.separated(
        separatorBuilder: (_,_)=> SizedBox(height: 16),
        padding: const EdgeInsets.all(16),
        itemCount: _exams.length,
        itemBuilder: (context, index) {
          final exam = _exams[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/admin/exam/${exam.examId}'),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _statusColor(exam.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.book,
                              color: _statusColor(exam.status), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exam.title.isNotEmpty ? exam.title : ' ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${exam.durationSeconds ~/ 60} min \u2022 -${exam.negativeMarks} each${exam.scheduledDate != null ? ' \u2022 ${exam.scheduledDate!.day}/${exam.scheduledDate!.month}/${exam.scheduledDate!.year}' : ''}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(exam.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            exam.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor(exam.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _actionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          color: Colors.orange,
                          onTap: () => _editExam(exam),
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          color: Colors.red,
                          onTap: () => _deleteExam(exam.examId),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(ExamStatus status) {
    switch (status) {
      case ExamStatus.draft:
        return Colors.grey;
      case ExamStatus.published:
        return Colors.green;
      case ExamStatus.archived:
        return Colors.orange;
    }
  }

  Future<void> _editExam(ExamModel exam) async {
    await context.push('/admin/exam/edit/${exam.examId}');
    _loadExams();
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
