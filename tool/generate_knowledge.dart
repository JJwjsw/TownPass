import 'dart:convert';
import 'dart:io';

import 'package:town_pass/service/retrieval/embedding_model.dart';
import 'package:town_pass/service/retrieval/vector_search.dart';
import 'package:town_pass/service/retrieval/knowledge_source.dart';

Future<void> main(List<String> args) async {
  final source = args.isEmpty ? 'assets/data/knowledge_raw.json' : args.first;
  final records = readRawKnowledge(await File(source).readAsString());
  final cases = (jsonDecode(
    await File('tool/retrieval_cases.json').readAsString(),
  ) as List).cast<Map<String, dynamic>>();
  final model = EmbeddingModel();
  final failures = <Object>[];
  try {
    await model.load('assets/models/${RetrievalConfig.modelName}');
    for (final r in records) {
      try {
        r['vector'] = await model.document(r['name'], r['description']);
        validateVector(
          (r['vector'] as List<double>),
          RetrievalConfig.dimensions,
          '資料 ${r['id']}',
        );
      } catch (e) {
        failures.add(r['id']);
        stderr.writeln('資料 ${r['id']} 產生失敗：$e');
      }
    }
    if (failures.isNotEmpty) throw StateError('失敗 id：$failures；不覆寫輸出');
    final entries = records.map(KnowledgeEntry.fromJson).toList();
    for (final c in cases) {
      final q = await model.query(c['input']);
      c['queryVector'] = q;
      final candidates = search(q, entries, minSimilarity: -1);
      c['top3'] = candidates
          .map((h) => {'id': h.entry.id, 'score': h.similarity})
          .toList();
      c['expectedScore'] = c['expected'] == null
          ? null
          : cosine(q, entries.singleWhere((e) => e.id == c['expected']).vector);
    }
    final calibration = cases.where((c) => c['split'] == 'calibration');
    final positives =
        calibration
            .where((c) => c['expected'] != null)
            .map((c) => c['expectedScore'] as double)
            .toList()
          ..sort();
    final negatives =
        calibration
            .where((c) => c['expected'] == null)
            .map((c) => (c['top3'] as List).first['score'] as double)
            .toList()
          ..sort();
    final suggestedThreshold = (positives.first + negatives.last) / 2;
    const threshold = RetrievalConfig.minSimilarity;
    for (final c in cases) {
      final hits = search(
        (c.remove('queryVector') as List<double>),
        entries,
        minSimilarity: threshold,
      );
      c['actual'] = hits.map((h) => h.entry.id).toList();
      c['passed'] = c['expected'] == null
          ? hits.isEmpty
          : hits.isNotEmpty && hits.first.entry.id == c['expected'];
    }
    const encoder = JsonEncoder.withIndent('  ');
    final temp = File('assets/data/knowledge.json.tmp');
    await temp.writeAsString(encoder.convert(records));
    await temp.rename('assets/data/knowledge.json');
    await File('assets/data/evaluation.json').writeAsString(
      encoder.convert({
        'source': source,
        'inputCount': records.length,
        'outputCount': entries.length,
        'failedIds': failures,
        'model': RetrievalConfig.modelName,
        'documentFormat': 'title: none | text: {name}:{description}',
        'dimensions': 768,
        'minPositive': positives.first,
        'maxNegative': negatives.last,
        'minSimilarity': threshold,
        'suggestedCalibrationThreshold': suggestedThreshold,
        'separable': positives.first > negatives.last,
        'cases': cases,
      }),
    );
    stdout.writeln(
      'input=${records.length} output=${entries.length} failed=$failures threshold=$threshold',
    );
    for (final c in cases) {
      stdout.writeln(
        '${c['split']} expected=${c['expected']} actual=${c['actual']} passed=${c['passed']}',
      );
    }
  } finally {
    await model.dispose();
  }
}
