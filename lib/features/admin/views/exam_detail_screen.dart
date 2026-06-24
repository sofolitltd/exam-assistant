import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tex_text/tex_text.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../exam/data/models/exam_model.dart';
import '../../exam/data/models/question_model.dart';
import '../../exam/data/services/firestore_quiz_service.dart';

const _subjectOptions = [
  'General', 'Bangla', 'English', 'Mathematics', 'Science',
  'International Affairs', 'Geography', 'Bangladesh Affairs', 'Islam & Moral Education',
  'ICT', 'Mental Ability',
];

class ExamDetailScreen extends StatefulWidget {
  final String examId;

  const ExamDetailScreen({super.key, required this.examId});

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = FirestoreQuizService();

  ExamModel? _exam;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  // Question editor state
  List<Map<String, dynamic>> _questions = [];
  bool _isSavingQuestions = false;
  bool _hasChanges = false;
  bool _isSelecting = false;
  final Set<int> _selectedIndices = {};
  final Set<int> _editModeIndices = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final exam = await _service.getExam(widget.examId);
      final questions = await _service.getExamQuestions(widget.examId);
      final results = await _service.getExamResults(widget.examId);
      if (mounted) {
        setState(() {
          _exam = exam;
          _questions = questions
              .map((q) => <String, dynamic>{
                    'id': q.id,
                    'questionText': q.questionText,
                    'subject': q.subject,
                    'options': {
                      for (final o in q.options) o.key: o.value,
                    },
                    'correctOption': q.correctOption ?? 'A',
                    'explanation': q.explanation,
                  })
              .toList();
          _hasChanges = false;
          _results = results;
          _isLoading = false;
          _isSelecting = false;
          _selectedIndices.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Failed to load data: $e');
        setState(() => _isLoading = false);
      }
    }
  }



  void _moveQuestion(int from, int to) {
    if (to < 0 || to >= _questions.length) return;
    final q = _questions.removeAt(from);
    _questions.insert(to, q);
    setState(() => _hasChanges = true);
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndices.length == _questions.length) {
        _isSelecting = false;
        _selectedIndices.clear();
      } else {
        _isSelecting = true;
        _selectedIndices.addAll(List.generate(_questions.length, (i) => i));
      }
    });
  }

  Future<void> _deleteSelected() async {
    final ids = _selectedIndices
        .map((i) => _questions[i]['id'] as String?)
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return;

    final count = _selectedIndices.length;
    await _service.deleteQuestionsByIds(widget.examId, ids);
    setState(() {
      _questions.removeWhere((q) => ids.contains(q['id']));
      _selectedIndices.clear();
      _isSelecting = false;
      _hasChanges = true;
    });
    _showSnack('Deleted $count question${count == 1 ? '' : 's'}');
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      _hasChanges = true;
    });
  }

  void _updateField(int index, String field, dynamic value) {
    if (index >= _questions.length) return;
    _questions[index][field] = value;
    setState(() => _hasChanges = true);
  }

  void _updateOption(int index, String key, String value) {
    if (index >= _questions.length) return;
    final opts = _questions[index]['options'];
    if (opts == null) {
      _questions[index]['options'] = <String, dynamic>{};
    }
    _questions[index]['options'][key] = value;
    setState(() => _hasChanges = true);
  }

  void _showJsonImportDialog() {
    final jsonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Questions (JSON)'),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: jsonController,
            maxLines: 10,
            minLines: 6,
            decoration: const InputDecoration(
              hintText: '[{"questionText": "...", "options": {"A": "..."}, "correctOption": "A"}]',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = jsonController.text.trim();
              if (raw.isEmpty) return;
              try {
                final parsed = jsonDecode(raw) as List;
                final imported = parsed.map((e) {
                  final item = Map<String, dynamic>.from(e as Map);
                  if (item['options'] is Map) {
                    item['options'] = Map<String, dynamic>.from(item['options'] as Map);
                  }
                  if (!item.containsKey('subject')) item['subject'] = 'General';
                  if (!item.containsKey('correctOption')) item['correctOption'] = 'A';
                  item['id'] = const Uuid().v4();
                  return item;
                }).toList();

                if (imported.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No questions found in JSON')),
                  );
                  return;
                }

                setState(() {
                  _questions.addAll(imported);
                  _hasChanges = true;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Imported ${imported.length} question${imported.length == 1 ? '' : 's'}',
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid JSON: $e')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQuestions() async {
    final validQuestions = _questions.where((q) {
      final text = (q['questionText'] ?? '').toString().trim();
      final options = q['options'] is Map ? Map<String, dynamic>.from(q['options'] as Map) : <String, dynamic>{};
      return text.isNotEmpty &&
          options.values.any((v) => v.toString().trim().isNotEmpty);
    }).toList();

    if (validQuestions.isEmpty) {
      _showSnack('No complete questions to save');
      return;
    }

    setState(() => _isSavingQuestions = true);

    try {
      final questionModels = validQuestions.map((q) {
        final opts = (q['options'] is Map ? q['options'] as Map : <String, dynamic>{})
            .map((k, v) => MapEntry(k.toString(), v.toString().trim()));
        return QuestionModel(
          id: q['id'] as String? ?? const Uuid().v4(),
          examId: widget.examId,
          questionText: (q['questionText'] ?? '').toString().trim(),
          subject: (q['subject'] ?? 'General').toString().trim(),
          options: opts.entries
              .map((e) => QuestionOption(key: e.key, value: e.value))
              .toList(),
          correctOptionKeys: [(q['correctOption'] ?? 'A').toString().trim()],
          explanation: q['explanation']?.toString().trim(),
        );
      }).toList();

      await _service.deleteAllQuestions(widget.examId);
      await _service.saveQuestions(widget.examId, questionModels);
      _showSnack('Questions saved');
      _loadData();
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSavingQuestions = false);
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
      appBar: AppBar(
        title: Text(
            _exam?.title.isNotEmpty == true ? _exam!.title : 'Exam Detail'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Questions'),
                  Tab(text: 'Results'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveWrapper(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestionsTab(),
                  _buildResultsTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () async {
                try {
              await context.push(
                '/admin/exam/${widget.examId}/add-question',
              );
              await _loadData();
                } catch (e) {
                  debugPrint('FAB navigation error: $e');
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildQuestionsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showJsonImportDialog,
                icon: const Icon(Icons.content_paste, size: 18),
                label: const Text('Import JSON'),
              ),
            ),
            const SizedBox(width: 8),
            if (_questions.isNotEmpty)
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _isSelecting ? AppTheme.primaryColor : null,
                  ),
                  onPressed: _toggleSelectAll,
                  child: Text(_isSelecting ? 'Deselect All' : 'Select All'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isSelecting && _selectedIndices.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  '${_selectedIndices.length} selected',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(
                    'Delete Selected (${_selectedIndices.length})',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        if (_questions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Center(
              child: Text(
                'No questions yet',
                style: TextStyle(color: Colors.grey[500], fontSize: 15),
              ),
            ),
          )
        else ...[
          ..._questions.asMap().entries.map((e) => _buildQuestionCard(e.key)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: _isSavingQuestions
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _hasChanges ? _saveQuestions : null,
                    icon: const Icon(Icons.save),
                    label: Text(
                      'Save ${_questions.length} Question${_questions.length == 1 ? '' : 's'}',
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionCard(int index) {
    if (index >= _questions.length) return const SizedBox();
    final q = _questions[index];

    final rawOptions = q['options'];
    final Map<String, dynamic> options;
    if (rawOptions is Map) {
      options = Map<String, String>.from(
          rawOptions.map((k, v) => MapEntry(k.toString(), v.toString())));
    } else {
      options = <String, String>{};
    }
    final correct = (q['correctOption'] ?? 'A').toString();
    final subject = '${q['subject'] ?? 'General'}';
    final questionText = '${q['questionText'] ?? ''}';
    final explanation = '${q['explanation'] ?? ''}';
    final id = '${q['id'] ?? index}';

    return Card(
      key: ValueKey(id),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (_isSelecting)
                  Checkbox(
                    value: _selectedIndices.contains(index),
                    onChanged: (_) => _toggleSelection(index),
                  ),
                Column(
                  children: [
                    InkWell(
                      onTap: index == 0 ? null : () => _moveQuestion(index, index - 1),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        color: index == 0 ? Colors.grey[300] : Colors.grey[600],
                        size: 22,
                      ),
                    ),
                    InkWell(
                      onTap: index == _questions.length - 1
                          ? null
                          : () => _moveQuestion(index, index + 1),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: index == _questions.length - 1
                            ? Colors.grey[300]
                            : Colors.grey[600],
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _subjectOptions.contains(subject) ? subject : 'General',
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: _subjectOptions
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child:
                                Text(s, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _updateField(index, 'subject', v);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    _editModeIndices.contains(index)
                        ? Icons.visibility
                        : Icons.edit,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_editModeIndices.contains(index)) {
                        _editModeIndices.remove(index);
                      } else {
                        _editModeIndices.add(index);
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteQuestion(index),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_editModeIndices.contains(index)) ...[
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Enter the question text',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController.fromValue(
                  TextEditingValue(text: questionText),
                ),
                onChanged: (v) => _updateField(index, 'questionText', v),
              ),
              const SizedBox(height: 12),
              ...options.keys.map((key) {
                final isCorrect = correct == key;
                final optText = options.containsKey(key) ? '${options[key]}' : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _updateField(index, 'correctOption', key),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? AppTheme.primaryColor
                                : Colors.grey[100],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCorrect
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              key,
                              style: TextStyle(
                                color: isCorrect ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: isCorrect
                              ? InputDecoration(
                                  hintText: 'Option $key',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10,
                                  ),
                                  suffixIcon: Icon(Icons.check_circle,
                                      color: AppTheme.primaryColor, size: 20),
                                )
                              : InputDecoration(
                                  hintText: 'Option $key',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10,
                                  ),
                                ),
                          controller: TextEditingController.fromValue(
                            TextEditingValue(text: optText),
                          ),
                          onChanged: (v) => _updateOption(index, key, v),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Explanation (optional)',
                  hintText: 'Explain the answer',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController.fromValue(
                  TextEditingValue(text: explanation),
                ),
                onChanged: (v) => _updateField(index, 'explanation', v),
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(fontSize: 13),
              ),
            ] else ...[
              ClipRect(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44, maxHeight: 86),
                  child: TexText(
                    questionText.isNotEmpty ? questionText : ' ',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...options.keys.map((key) {
                final isCorrect = correct == key;
                final optText = options.containsKey(key) ? '${options[key]}' : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: isCorrect ? AppTheme.primaryColor : Colors.grey[100],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCorrect ? AppTheme.primaryColor : Colors.grey[300]!,
                          ),
                        ),
                        child: Center(
                          child: isCorrect
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : Text(key, style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRect(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 24, maxHeight: 72),
                            child: TexText(
                              optText.isNotEmpty ? optText : ' ',
                              style: TextStyle(fontSize: 14, color: isCorrect ? AppTheme.primaryColor : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRect(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 20, maxHeight: 72),
                            child: TexText(
                              explanation,
                              style: const TextStyle(fontSize: 13, color: Colors.blue),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsTab() {
    if (_results.isEmpty) {
      return const Center(child: Text('No results yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final r = _results[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(r['userName'] ?? ''),
          subtitle: Text(
              'Score: ${(r['score'] ?? 0).toStringAsFixed(1)} | Correct: ${r['correctCount'] ?? 0}'),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    if (_exam == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: const Text('Status'),
            subtitle: Text(_exam!.status.label),
            trailing: DropdownButton<ExamStatus>(
              value: _exam!.status,
              items: ExamStatus.values
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (s) async {
                if (s == null || s == _exam!.status) return;
                final updated = ExamModel(
                  examId: _exam!.examId,
                  title: _exam!.title,
                  durationSeconds: _exam!.durationSeconds,
                  negativeMarks: _exam!.negativeMarks,
                  status: s,
                  scheduledDate: _exam!.scheduledDate,
                  createdAt: _exam!.createdAt,
                );
                // TODO: Send FCM notification when status changes to published
                // e.g., if (s == ExamStatus.published) { await _sendPushNotification(examTitle: _exam!.title); }
                await _service.updateExam(updated);
                _loadData();
              },
            ),
          ),
          const Divider(),
          ElevatedButton.icon(
            onPressed: () => context.push('/admin/exam/edit/${widget.examId}'),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Exam Details'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Exam'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam'),
        content: const Text(
          'This will permanently delete this exam, all questions, and results.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteExamCascade(widget.examId);
      if (mounted) context.go('/admin');
    }
  }
}
