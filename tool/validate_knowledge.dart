import 'dart:convert';
import 'dart:io';

import 'package:town_pass/service/retrieval/knowledge_source.dart';
import 'package:town_pass/service/retrieval/vector_search.dart';

Future<void> main() async {
  final raw = readRawKnowledge(
    await File('assets/data/knowledge_raw.json').readAsString(),
  );
  final output = jsonDecode(
    await File('assets/data/knowledge.json').readAsString(),
  ) as List;
  if (raw.length != output.length) throw StateError('筆數不符');
  for (var i = 0; i < raw.length; i++) {
    for (final key in ['id', 'name', 'description', 'url']) {
      if (raw[i][key] != output[i][key]) {
        throw StateError('資料 ${raw[i]['id']} 欄位 $key 不符');
      }
    }
    KnowledgeEntry.fromJson(output[i] as Map<String, dynamic>);
  }
  stdout.writeln(
    'Verified ${raw.length} records: exact metadata, normalized URLs, finite nonzero 768D vectors.',
  );
}
