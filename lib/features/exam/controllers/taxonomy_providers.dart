import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../data/services/taxonomy_api_service.dart';

/// Shared [TaxonomyApiService] backing the providers below, so every
/// screen reuses the same cache instead of each constructing its own
/// service and refetching from the network.
final taxonomyApiServiceProvider = Provider<TaxonomyApiService>(
  (ref) =>
      TaxonomyApiService(accountApi: ref.watch(accountApiServiceProvider)),
);

/// The exam programs list. Not `autoDispose`: this is reference data that
/// almost never changes within a session, so every caller (subject
/// pickers, the syllabus browser, the বিসিএস flow) shares one fetch
/// instead of refetching each time its screen opens. Call
/// `ref.invalidate(taxonomyProgramsProvider)` to force a reload.
final taxonomyProgramsProvider = FutureProvider<List<ExamProgram>>(
  (ref) => ref.watch(taxonomyApiServiceProvider).getPrograms(),
);

/// A program's syllabus versions, keyed by programId. Not `autoDispose`,
/// for the same reason as [taxonomyProgramsProvider].
final syllabiProvider = FutureProvider.family<List<SyllabusVersion>, int>(
  (ref, programId) =>
      ref.watch(taxonomyApiServiceProvider).getSyllabi(programId),
);

/// A syllabus's node tree, keyed by syllabusId — shared by every caller
/// (including every বিসিএস edition built on that syllabus) so it's
/// fetched once instead of once per caller. Not `autoDispose`, for the
/// same reason as [taxonomyProgramsProvider].
final syllabusNodesProvider = FutureProvider.family<List<SyllabusNode>, int>(
  (ref, syllabusId) =>
      ref.watch(taxonomyApiServiceProvider).getNodes(syllabusId),
);
