import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'retrieval/embedding_model.dart';
import 'retrieval/vector_search.dart';
import 'retrieval/format_results.dart';

class ChatReply {
  final List<KnowledgeEntry> entries;
  ChatReply(List<KnowledgeEntry> entries)
    : entries = List.unmodifiable(entries);
  String get text =>
      formatResults(entries.map((e) => SearchHit(e, 0)).toList());
}

class ChatService {
  static const greeting = '您好，請問您需要甚麼幫忙？';
  static final _model = EmbeddingModel();
  static Future<void>? _initializing;
  static List<KnowledgeEntry> _entries = [];
  static bool _busy = false;
  Future<void> _initialize() async {
    try {
      final json = jsonDecode(
        await rootBundle.loadString('assets/data/knowledge.json'),
      ) as List;
      _entries = json
          .map((e) => KnowledgeEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      if (_entries.map((e) => e.id).toSet().length != _entries.length) {
        throw const FormatException('重複 id');
      }
    } catch (e) {
      throw StateError('檢索資料讀取失敗：$e');
    }
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/${RetrievalConfig.modelName}');
      if (!await file.exists()) {
        final data = await rootBundle.load(
          'assets/models/${RetrievalConfig.modelName}',
        );
        final temp = File('${file.path}.tmp');
        await temp.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
        await temp.rename(file.path);
      }
      await _model.load(file.path);
    } catch (e) {
      throw StateError('模型載入失敗：$e');
    }
  }

  Future<String> reply({
    required String message,
    required List<Map<String, String>> history,
  }) async => (await retrieve(message: message)).text;

  Future<ChatReply> retrieve({required String message}) async {
    final input = message.trim();
    if (input.isEmpty) throw ArgumentError('請輸入問題');
    if (_busy) throw StateError('正在處理上一個問題');
    _busy = true;
    try {
      try {
        await (_initializing ??= _initialize());
      } catch (_) {
        _initializing = null;
        rethrow;
      }
      List<double> query;
      try {
        query = await _model.query(input);
      } catch (_) {
        throw StateError('向量推論失敗，請縮短問題後重試。');
      }
      final hits = search(query, _entries);
      return ChatReply(hits.map((h) => h.entry).toList());
    } finally {
      _busy = false;
    }
  }
}
