import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../exam/data/models/question_model.dart';

class AddQuestionScreen extends StatefulWidget {
  final String examId;

  const AddQuestionScreen({super.key, required this.examId});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _jsonController = TextEditingController();
  final _uuid = const Uuid();
  bool _isSaving = false;
  bool _showReview = false;
  List<Map<String, dynamic>> _parsed = [];

  @override
  void initState() {
    super.initState();
    _jsonController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _import() {
    final raw = _jsonController.text.trim();
    if (raw.isEmpty) {
      _showSnack('Paste JSON first');
      return;
    }

    List<Map<String, dynamic>> parsed;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _showSnack('JSON must be an array of question objects');
        return;
      }
      parsed = decoded
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .toList();
    } catch (e) {
      _showSnack('Invalid JSON: $e');
      return;
    }

    if (parsed.isEmpty) {
      _showSnack('No questions found in JSON');
      return;
    }

    for (final item in parsed) {
      if (!item.containsKey('id')) item['id'] = _uuid.v4();
      if (!item.containsKey('subject') || (item['subject'] as String?)?.isEmpty == true) {
        item['subject'] = 'General';
      }
      if (!item.containsKey('correctOption') || (item['correctOption'] as String?)?.isEmpty == true) {
        item['correctOption'] = 'A';
      }
    }

    setState(() {
      _parsed = parsed;
      _showReview = false;
    });
    _showSnack('Imported ${parsed.length} question${parsed.length == 1 ? '' : 's'}');
  }

  Future<void> _upload() async {
    if (_parsed.isEmpty) return;
    setState(() => _isSaving = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final item in _parsed) {
        final optsRaw = item['options'];
        final List<QuestionOption> options;
        if (optsRaw is List) {
          options = optsRaw
              .map((o) => QuestionOption(
                    key: (o['key'] ?? '').toString(),
                    value: (o['value'] ?? '').toString().trim(),
                  ))
              .toList();
        } else {
          options = [];
        }

        final correctKeys = item['correctOptionKeys'] is List
            ? List<String>.from(
                (item['correctOptionKeys'] as List).map((e) => e.toString()))
            : [(item['correctOption'] ?? 'A').toString().trim()];

        final sourceRaw = item['source'];
        final source = sourceRaw is String && sourceRaw.isNotEmpty ? sourceRaw : null;

        final question = QuestionModel(
          id: item['id'] as String? ?? _uuid.v4(),
          examId: widget.examId,
          questionText: (item['questionText'] ?? '').toString().trim(),
          subject: (item['subject'] ?? 'General').toString().trim(),
          options: options,
          correctOptionKeys: correctKeys,
          explanation: item['explanation']?.toString().trim(),
          source: source,
          sourceYear: item['sourceYear']?.toString().trim(),
        );
        batch.set(
          FirebaseFirestore.instance
              .collection(AppConstants.questionsCollection)
              .doc(question.id),
          question.toMap(),
        );
      }
      await batch.commit();
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnack('Error: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickJsonFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) {
      _showSnack('Could not read file');
      return;
    }
    _jsonController.text = utf8.decode(bytes);
  }

  void _clearJson() {
    _jsonController.clear();
    setState(() => _showReview = false);
  }

  void _updateField(int index, String field, dynamic value) {
    _parsed[index][field] = value;
    setState(() {});
  }

  void _updateOption(int index, String key, String value) {
    final opts = _parsed[index]['options'];
    if (opts is List) {
      for (final o in opts) {
        if (o['key'] == key) {
          o['value'] = value;
          break;
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Questions')),
      body: ResponsiveWrapper(
        child: Column(
          children: [
            if (!_showReview) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Paste JSON questions below',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '[{"questionText":"...","options":[{"key":"A","value":"..."},{"key":"B","value":"..."}],"correctOptionKeys":["A"]}]',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Flexible(
                            child: OutlinedButton.icon(
                              onPressed: _pickJsonFile,
                              icon: const Icon(Icons.folder_open, size: 18),
                              label: const Text('Pick JSON File'),
                            ),
                          ),
                          const Spacer(),
                          if (_jsonController.text.isNotEmpty)
                            TextButton.icon(
                              onPressed: _clearJson,
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Clear'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
                          controller: _jsonController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            hintText:
                                '[{\n  "questionText": "What is 2+2?",\n  "options": [{"key":"A","value":"3"},{"key":"B","value":"4"}],\n  "correctOptionKeys": ["B"]\n}]',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  itemCount: _parsed.length,
                  itemBuilder: (context, index) => _buildReviewCard(index),
                ),
              ),
            ],
            if (!_showReview && _parsed.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _import,
                    icon: const Icon(Icons.content_paste, color: Colors.white),
                    label: const Text('Import'),
                  ),
                ),
              ),
            if (!_showReview && _parsed.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _showReview = true),
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('Review'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _upload,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload, color: Colors.white),
                          label: Text(_isSaving ? 'Uploading...' : 'Upload to DB'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_showReview)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _jsonController.text = const JsonEncoder.withIndent('  ').convert(_parsed);
                            setState(() => _showReview = false);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit JSON'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _upload,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_upload, color: Colors.white),
                          label: Text(_isSaving ? 'Uploading...' : 'Upload to DB'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(int index) {
    if (index >= _parsed.length) return const SizedBox();
    final q = _parsed[index];
    final questionText = '${q['questionText'] ?? ''}';
    final subject = '${q['subject'] ?? 'General'}';
    final correct = '${q['correctOption'] ?? 'A'}';
    final correctKeys = q['correctOptionKeys'] is List
        ? List<String>.from((q['correctOptionKeys'] as List).map((e) => e.toString()))
        : [correct];

    final optsRaw = q['options'];
    final List<Map<String, dynamic>> options;
    if (optsRaw is List) {
      options = optsRaw.map((o) => Map<String, dynamic>.from(o as Map)).toList();
    } else {
      options = [];
    }

    return Card(
      key: ValueKey(q['id']),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    items: _subjectOptions
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _updateField(index, 'subject', v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            ...options.asMap().entries.map((entry) {
              final i = entry.key;
              final opt = entry.value;
              final key = '${opt['key'] ?? String.fromCharCode(65 + i)}';
              final val = '${opt['value'] ?? ''}';
              final isCorrect = correctKeys.contains(key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _updateField(index, 'correctOption', key);
                        _updateField(index, 'correctOptionKeys', [key]);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCorrect ? AppTheme.primaryColor : Colors.grey[100],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCorrect ? AppTheme.primaryColor : Colors.grey[300]!,
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
                          TextEditingValue(text: val),
                        ),
                        onChanged: (v) => _updateOption(index, key, v),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

const _subjectOptions = [
  'General', 'Bangla', 'English', 'Mathematics', 'Science',
  'International Affairs', 'Geography', 'Bangladesh Affairs', 'Islam & Moral Education',
  'ICT', 'Mental Ability',
];
