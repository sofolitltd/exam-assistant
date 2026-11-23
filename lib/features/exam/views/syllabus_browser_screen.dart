import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/taxonomy_providers.dart';
import '../data/services/taxonomy_api_service.dart';

class SyllabusBrowserScreen extends ConsumerStatefulWidget {
  final int programId;

  const SyllabusBrowserScreen({super.key, required this.programId});

  @override
  ConsumerState<SyllabusBrowserScreen> createState() =>
      _SyllabusBrowserScreenState();
}

class _SyllabusBrowserScreenState extends ConsumerState<SyllabusBrowserScreen> {
  late Future<List<SyllabusVersion>> _syllabiFuture;
  Future<List<SyllabusNode>>? _nodesFuture;
  int? _selectedSyllabusId;

  @override
  void initState() {
    super.initState();
    _syllabiFuture = _loadSyllabi();
  }

  Future<List<SyllabusVersion>> _loadSyllabi() async {
    final versions = await ref.read(syllabiProvider(widget.programId).future);
    if (versions.isNotEmpty && mounted) {
      final selected = versions.firstWhere(
        (version) => version.status == 'current',
        orElse: () => versions.first,
      );
      setState(() {
        _selectedSyllabusId = selected.syllabusId;
        _nodesFuture = ref.read(
          syllabusNodesProvider(selected.syllabusId).future,
        );
      });
    }
    return versions;
  }

  void _selectSyllabus(int? syllabusId) {
    if (syllabusId == null) return;
    setState(() {
      _selectedSyllabusId = syllabusId;
      _nodesFuture = ref.read(syllabusNodesProvider(syllabusId).future);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a syllabus')),
      body: FutureBuilder<List<SyllabusVersion>>(
        future: _syllabiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorMessage(message: '${snapshot.error}');
          }
          final versions = snapshot.data ?? const <SyllabusVersion>[];
          if (versions.isEmpty) {
            return const _ErrorMessage(
              message: 'No syllabus versions are available for this program.',
            );
          }
          final selected =
              versions.any(
                (version) => version.syllabusId == _selectedSyllabusId,
              )
              ? _selectedSyllabusId
              : versions.first.syllabusId;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<int>(
                  initialValue: selected,
                  decoration: const InputDecoration(
                    labelText: 'Syllabus version',
                    border: OutlineInputBorder(),
                  ),
                  items: versions
                      .map(
                        (version) => DropdownMenuItem(
                          value: version.syllabusId,
                          child: Text('${version.title} · ${version.status}'),
                        ),
                      )
                      .toList(),
                  onChanged: _selectSyllabus,
                ),
              ),
              Expanded(
                child: _nodesFuture == null
                    ? const Center(child: Text('Choose a syllabus version.'))
                    : FutureBuilder<List<SyllabusNode>>(
                        future: _nodesFuture,
                        builder: (context, nodeSnapshot) {
                          if (nodeSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (nodeSnapshot.hasError) {
                            return _ErrorMessage(
                              message: '${nodeSnapshot.error}',
                            );
                          }
                          final nodes = (nodeSnapshot.data ?? const [])
                              .where((node) => node.active)
                              .toList();
                          final byId = {
                            for (final node in nodes) node.nodeId: node,
                          };
                          if (nodes.isEmpty) {
                            return const Center(
                              child: Text(
                                'No subjects or topics are configured yet.',
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: nodes.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final node = nodes[index];
                              final parent = byId[node.parentId];
                              final marks = node.marks == null
                                  ? null
                                  : '${node.marks} marks';
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.menu_book_outlined),
                                  title: Text(node.name),
                                  subtitle: Text(
                                    [
                                      node.nodeType,
                                      if (parent != null) parent.name,
                                      ?marks,
                                    ].join(' · '),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => context.push(
                                    '/taxonomy-questions/${node.syllabusId}/${node.nodeId}?title=${Uri.encodeQueryComponent(node.name)}',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
