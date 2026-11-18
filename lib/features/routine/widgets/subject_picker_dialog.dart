import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../exam/data/services/taxonomy_api_service.dart';

/// The picked subject; [none] means "unlink this block from any subject".
class SubjectChoice {
  final int? nodeId;
  final String? name;

  const SubjectChoice(this.nodeId, this.name);

  static const none = SubjectChoice(null, null);
}

/// Program → subject picker over the syllabus taxonomy, using each
/// program's current syllabus version.
class SubjectPickerDialog extends ConsumerStatefulWidget {
  final int? selectedNodeId;

  const SubjectPickerDialog({super.key, this.selectedNodeId});

  @override
  ConsumerState<SubjectPickerDialog> createState() =>
      _SubjectPickerDialogState();
}

class _SubjectPickerDialogState extends ConsumerState<SubjectPickerDialog> {
  late final TaxonomyApiService _api = TaxonomyApiService(
    accountApi: ref.read(accountApiServiceProvider),
  );
  late final Future<List<ExamProgram>> _programs = _api.getPrograms();
  ExamProgram? _program;
  Future<List<SyllabusNode>>? _subjects;

  Future<List<SyllabusNode>> _loadSubjects(ExamProgram program) async {
    final syllabi = await _api.getSyllabi(program.programId);
    if (syllabi.isEmpty) return const [];
    final syllabus = syllabi.firstWhere(
      (s) => s.status == 'current',
      orElse: () => syllabi.first,
    );
    final nodes = await _api.getNodes(syllabus.syllabusId);
    return nodes.where((n) => n.nodeType == 'subject' && n.active).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_program == null ? 'কোন পরীক্ষার সিলেবাস?' : _program!.name),
      content: SizedBox(
        width: double.maxFinite,
        height: 360,
        child: _program == null ? _buildPrograms() : _buildSubjects(),
      ),
      actions: [
        if (_program != null)
          TextButton(
            onPressed: () => setState(() {
              _program = null;
              _subjects = null;
            }),
            child: const Text('পেছনে'),
          ),
        if (widget.selectedNodeId != null)
          TextButton(
            onPressed: () => Navigator.pop(context, SubjectChoice.none),
            child: const Text('বিষয় সরাও'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('বাতিল'),
        ),
      ],
    );
  }

  Widget _buildPrograms() {
    return FutureBuilder<List<ExamProgram>>(
      future: _programs,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('লোড করা যায়নি: ${snapshot.error}');
        }
        final programs = snapshot.data ?? const [];
        return ListView(
          children: [
            for (final program in programs)
              ListTile(
                title: Text(program.name),
                subtitle: Text(program.code),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() {
                  _program = program;
                  _subjects = _loadSubjects(program);
                }),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSubjects() {
    return FutureBuilder<List<SyllabusNode>>(
      future: _subjects,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('লোড করা যায়নি: ${snapshot.error}');
        }
        final subjects = snapshot.data ?? const [];
        if (subjects.isEmpty) {
          return const Center(child: Text('এই সিলেবাসে কোনো বিষয় নেই।'));
        }
        return ListView(
          children: [
            for (final subject in subjects)
              ListTile(
                title: Text(subject.name),
                selected: subject.nodeId == widget.selectedNodeId,
                trailing: subject.nodeId == widget.selectedNodeId
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(
                  context,
                  SubjectChoice(subject.nodeId, subject.name),
                ),
              ),
          ],
        );
      },
    );
  }
}
