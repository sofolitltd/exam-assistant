import 'routine_block_model.dart';

/// An admin-published routine that a user can clone and then customize.
class RoutineTemplateModel {
  final String templateId;
  final String title;
  final String description;
  final List<RoutineBlockModel> blocks;

  const RoutineTemplateModel({
    required this.templateId,
    required this.title,
    required this.description,
    this.blocks = const [],
  });

  factory RoutineTemplateModel.fromMap(Map<String, dynamic> map) {
    return RoutineTemplateModel(
      templateId: map['templateId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      blocks:
          (map['blocks'] as List<dynamic>?)
              ?.map(
                (e) => RoutineBlockModel.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }
}
