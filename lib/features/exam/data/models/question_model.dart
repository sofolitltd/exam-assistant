class QuestionOption {
  final String key;
  final String value;

  QuestionOption({required this.key, required this.value});

  factory QuestionOption.fromMap(Map<String, dynamic> map) {
    return QuestionOption(key: map['key'] ?? '', value: map['value'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'key': key, 'value': value};
  }
}

class QuestionModel {
  final String id;
  final String examId;
  final String questionText;
  final String subject;
  final int? taxonomyNodeId;
  final List<QuestionOption> options;
  final List<String> correctOptionKeys;
  final String? explanation;
  final String? source;
  final String? sourceYear;
  final DateTime createdAt;

  QuestionModel({
    required this.id,
    required this.examId,
    required this.questionText,
    required this.subject,
    this.taxonomyNodeId,
    required this.options,
    required this.correctOptionKeys,
    this.explanation,
    this.source,
    this.sourceYear,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory QuestionModel.fromMap(Map<String, dynamic> map, String id) {
    final createdAtValue = map['createdAt'];
    return QuestionModel(
      id: id,
      examId: map['examId'] ?? '',
      questionText: map['questionText'] ?? '',
      subject: map['subject'] ?? 'General',
      taxonomyNodeId: (map['taxonomyNodeId'] as num?)?.toInt(),
      options: (map['options'] as List? ?? [])
          .map((o) => QuestionOption.fromMap(Map<String, dynamic>.from(o)))
          .toList(),
      correctOptionKeys: List<String>.from(map['correctOptionKeys'] ?? []),
      explanation: map['explanation'] as String?,
      source: map['source'] as String?,
      sourceYear: map['sourceYear'] as String?,
      createdAt:
          DateTime.tryParse(createdAtValue as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'questionText': questionText,
      'subject': subject,
      if (taxonomyNodeId != null) 'taxonomyNodeId': taxonomyNodeId,
      'options': options.map((o) => o.toMap()).toList(),
      'correctOptionKeys': correctOptionKeys,
      if (explanation != null && explanation!.isNotEmpty)
        'explanation': explanation,
      if (source != null && source!.isNotEmpty) 'source': source,
      if (sourceYear != null && sourceYear!.isNotEmpty)
        'sourceYear': sourceYear,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String? get correctOption =>
      correctOptionKeys.isNotEmpty ? correctOptionKeys.first : null;
}
