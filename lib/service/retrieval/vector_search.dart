import 'dart:math';

import 'knowledge_source.dart';

class RetrievalConfig {
  static const modelName = 'embeddinggemma-300M-Q8_0.gguf';
  static const dimensions = 768;
  static const minSimilarity = 0.35;
  static const noResultsMessage = '找不到相關結果';
}

class KnowledgeEntry {
  final Object id;
  final String name, description;
  final String? url;
  final List<double> vector;
  KnowledgeEntry(this.id, this.name, this.description, this.vector, {this.url});
  factory KnowledgeEntry.fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    if (id is! String && id is! int) throw const FormatException('無效 id');
    final v = (j['vector'] as List).map((x) => (x as num).toDouble()).toList();
    validateVector(v, RetrievalConfig.dimensions, '資料 $id');
    return KnowledgeEntry(
      id,
      j['name'] as String,
      j['description'] as String,
      v,
      url: normalizeUrl(j['url']),
    );
  }
}

void validateVector(List<double> v, int dimensions, String label) {
  if (v.length != dimensions ||
      v.any((x) => !x.isFinite) ||
      v.fold<double>(0, (s, x) => s + x * x) <= 0) {
    throw FormatException('$label：向量維度不符、非有限數值或零向量');
  }
}

double cosine(List<double> a, List<double> b) {
  validateVector(a, b.length, '查詢');
  validateVector(b, a.length, '資料');
  double dot = 0, aa = 0, bb = 0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    aa += a[i] * a[i];
    bb += b[i] * b[i];
  }
  return (dot / sqrt(aa * bb)).clamp(-1.0, 1.0);
}

class SearchHit {
  final KnowledgeEntry entry;
  final double similarity;
  SearchHit(this.entry, this.similarity);
}

List<SearchHit> search(
  List<double> query,
  List<KnowledgeEntry> entries, {
  double minSimilarity = RetrievalConfig.minSimilarity,
}) {
  validateVector(query, RetrievalConfig.dimensions, '查詢');
  final hits = entries
      .map((e) => SearchHit(e, cosine(query, e.vector)))
      .where((h) => h.similarity >= minSimilarity)
      .toList();
  hits.sort((a, b) {
    final c = b.similarity.compareTo(a.similarity);
    return c == 0
        ? a.entry.id is int && b.entry.id is int
              ? (a.entry.id as int).compareTo(b.entry.id as int)
              : a.entry.id.toString().compareTo(b.entry.id.toString())
        : c;
  });
  return hits.take(3).toList();
}
