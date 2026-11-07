import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:town_pass/service/retrieval/vector_search.dart';

void main() {
  test('production threshold replays all 18 stored real-model queries', () {
    expect(RetrievalConfig.minSimilarity, 0.35);
    final report = jsonDecode(
      File('assets/data/evaluation.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final cases = report['cases'] as List;
    expect(cases.length, 18);
    for (final item in cases) {
      final hits = (item['top3'] as List)
          .where(
            (hit) => (hit['score'] as num) >= RetrievalConfig.minSimilarity,
          )
          .toList();
      if (item['expected'] == null) {
        expect(hits, isEmpty, reason: item['input']);
      } else {
        expect(hits, isNotEmpty, reason: item['input']);
        expect(hits.first['id'], item['expected'], reason: item['input']);
      }
    }
  });
  List<double> v(double a, double b) => [a, b, ...List.filled(766, 0.0)];
  KnowledgeEntry e(String id, List<double> vector) =>
      KnowledgeEntry(id, id, 'test', vector);
  test('cosine and invalid vectors', () {
    expect(cosine([1, 0], [1, 0]), 1);
    expect(cosine([1, 0], [0, 1]), 0);
    expect(cosine([1, 0], [-1, 0]), -1);
    expect(() => cosine([1], [1, 0]), throwsFormatException);
    expect(() => cosine([0, 0], [1, 0]), throwsFormatException);
    expect(() => cosine([double.nan, 1], [1, 0]), throwsFormatException);
    expect(() => cosine([double.infinity, 1], [1, 0]), throwsFormatException);
  });
  test('descending scores and numeric ID ties', () {
    final entries = [
      KnowledgeEntry(10, 'ten', 'test', v(1, 0)),
      KnowledgeEntry(2, 'two', 'test', v(1, 0)),
      KnowledgeEntry(3, 'three', 'test', v(1, 1)),
      KnowledgeEntry(4, 'four', 'test', v(0, 1)),
    ];
    expect(search(v(1, 0), entries, minSimilarity: 0).map((h) => h.entry.id), [
      2,
      10,
      3,
    ]);
    expect(search(v(1, 0), [entries.first], minSimilarity: 1).length, 1);
    expect(
      () => search(v(1, 0), [
        KnowledgeEntry(1, 'bad', 'bad', [1]),
      ]),
      throwsFormatException,
    );
  });
  test('inclusive threshold, stable ties, top three and no matches', () {
    final entries = [
      '004',
      '002',
      '003',
      '001',
    ].map((id) => e(id, v(1, 0))).toList();
    expect(search(v(1, 0), entries, minSimilarity: 1).map((h) => h.entry.id), [
      '001',
      '002',
      '003',
    ]);
    expect(search(v(0, 1), entries, minSimilarity: 0.1), isEmpty);
    expect(
      search(v(1, 0), entries.take(2).toList(), minSimilarity: 1).length,
      2,
    );
    expect(search(v(1, 0), []), isEmpty);
  });
}
