import 'vector_search.dart';

String formatResults(List<SearchHit> hits) {
  if (hits.isEmpty) return RetrievalConfig.noResultsMessage;
  return '以下為相關資訊\n\n${hits.asMap().entries.map((item) {
    final e = item.value.entry;
    return '${item.key + 1}. ${e.name}\n   ${e.description}\n   ${e.url ?? '未提供連結'}';
  }).join('\n\n')}';
}
