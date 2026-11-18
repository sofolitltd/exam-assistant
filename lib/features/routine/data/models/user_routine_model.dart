import 'routine_block_model.dart';

/// The signed-in user's own active routine.
class UserRoutineModel {
  final String title;
  final String? sourceTemplateId;
  final List<RoutineBlockModel> blocks;

  const UserRoutineModel({
    required this.title,
    this.sourceTemplateId,
    required this.blocks,
  });

  factory UserRoutineModel.fromMap(Map<String, dynamic> map) {
    return UserRoutineModel(
      title: map['title'] as String? ?? 'My Routine',
      sourceTemplateId: map['sourceTemplateId'] as String?,
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

  List<RoutineBlockModel> get sortedBlocks =>
      [...blocks]..sort((a, b) => a.startTime.compareTo(b.startTime));
}
