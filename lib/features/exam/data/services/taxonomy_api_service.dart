import '../../../auth/data/services/account_api_service.dart';
import '../models/question_model.dart';

class ExamProgram {
  final int programId;
  final String code;
  final String name;

  const ExamProgram({
    required this.programId,
    required this.code,
    required this.name,
  });

  factory ExamProgram.fromJson(Map<String, dynamic> json) => ExamProgram(
    programId: (json['programId'] as num).toInt(),
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );
}

class SyllabusVersion {
  final int syllabusId;
  final int programId;
  final String version;
  final String title;
  final String sourceUrl;
  final DateTime? effectiveFrom;
  final String status;

  const SyllabusVersion({
    required this.syllabusId,
    required this.programId,
    required this.version,
    required this.title,
    required this.sourceUrl,
    required this.effectiveFrom,
    required this.status,
  });

  factory SyllabusVersion.fromJson(Map<String, dynamic> json) =>
      SyllabusVersion(
        syllabusId: (json['syllabusId'] as num).toInt(),
        programId: (json['programId'] as num).toInt(),
        version: json['version'] as String? ?? '',
        title: json['title'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        effectiveFrom: DateTime.tryParse(
          json['effectiveFrom'] as String? ?? '',
        ),
        status: json['status'] as String? ?? 'draft',
      );
}

class SyllabusNode {
  final int nodeId;
  final int syllabusId;
  final int? parentId;
  final String nodeType;
  final String code;
  final String name;
  final int sortOrder;
  final double? marks;
  final bool active;

  const SyllabusNode({
    required this.nodeId,
    required this.syllabusId,
    required this.parentId,
    required this.nodeType,
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.marks,
    required this.active,
  });

  factory SyllabusNode.fromJson(Map<String, dynamic> json) => SyllabusNode(
    nodeId: (json['nodeId'] as num).toInt(),
    syllabusId: (json['syllabusId'] as num).toInt(),
    parentId: (json['parentId'] as num?)?.toInt(),
    nodeType: json['nodeType'] as String? ?? '',
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    sortOrder: (json['sortOrder'] as num? ?? 0).toInt(),
    marks: (json['marks'] as num?)?.toDouble(),
    active: json['active'] as bool? ?? false,
  );
}

class TaxonomyApiService {
  final AccountApiService _accountApi;

  TaxonomyApiService({required this._accountApi});

  Future<List<ExamProgram>> getPrograms() async {
    final json = await _get('/v1/taxonomy/programs');
    return _list(json).map(ExamProgram.fromJson).toList();
  }

  Future<List<SyllabusVersion>> getSyllabi(int programId) async {
    final json = await _get('/v1/taxonomy/programs/$programId/syllabi');
    return _list(json).map(SyllabusVersion.fromJson).toList();
  }

  Future<List<SyllabusNode>> getNodes(int syllabusId) async {
    final json = await _get('/v1/taxonomy/syllabi/$syllabusId/nodes');
    return _list(json).map(SyllabusNode.fromJson).toList();
  }

  Future<List<QuestionModel>> getQuestionBank({
    int? programId,
    int? syllabusId,
    int? nodeId,
  }) async {
    final query = <String, String>{
      if (programId != null) 'programId': '$programId',
      if (syllabusId != null) 'syllabusId': '$syllabusId',
      if (nodeId != null) 'nodeId': '$nodeId',
    };
    final json = await _get('/v1/question-bank', query: query);
    return _list(json)
        .map((item) => QuestionModel.fromMap(item, item['id'] as String? ?? ''))
        .toList();
  }

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    return _accountApi.getApiJson(path, query: query);
  }

  List<Map<String, dynamic>> _list(dynamic json) {
    if (json is! List) {
      throw const FormatException('Expected an API list response.');
    }
    return json.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}
