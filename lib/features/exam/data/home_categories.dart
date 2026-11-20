import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../bcs/data/bcs_models.dart';

/// The exam tiles on the home grid, from `/v1/home/categories` (admin
/// console → "Home categories"). Each tile's `id` is its program code in
/// lower case: `bcs` opens the বিসিএস page, `jobs` opens all exams, the rest
/// show "coming soon".
final homeCategoriesProvider = FutureProvider.autoDispose<List<ExamCategory>>((
  ref,
) async {
  final json = await ref
      .read(accountApiServiceProvider)
      .getApiJson('/v1/home/categories');
  if (json is! List) {
    throw const FormatException('Expected a home categories list.');
  }
  return [
    for (final item in json)
      if (item is Map)
        ExamCategory(
          id: (item['code'] as String? ?? '').toLowerCase(),
          name: item['label'] as String? ?? item['name'] as String? ?? '',
          status: item['subtitle'] as String? ?? '',
        ),
  ];
});
