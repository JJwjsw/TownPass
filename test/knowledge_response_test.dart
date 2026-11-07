import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:town_pass/page/chat/chat_response.dart';
import 'package:town_pass/service/chat_service.dart';
import 'package:town_pass/service/retrieval/format_results.dart';
import 'package:town_pass/service/retrieval/knowledge_source.dart';
import 'package:town_pass/service/retrieval/vector_search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('NaN token handling preserves quoted text and fields', () {
    final data = readRawKnowledge(
      r'''[{"id":1,"name":"NaN \"quoted\"","description":"keep NaN:null","url":NaN},{"id":2,"name":"B","description":"C","url":"https://example.com/NaN"}]''',
    );
    expect(data.first['url'], isNull);
    expect(data.first['name'], 'NaN "quoted"');
    expect(data.first['description'], 'keep NaN:null');
    expect(data.last['url'], 'https://example.com/NaN');
    for (final value in [null, double.nan, '', '  ', 'NaN', ' NULL ']) {
      expect(normalizeUrl(value), isNull);
    }
    expect(() => readRawKnowledge('[{"id":1}]'), throwsFormatException);
    expect(isWebUrl('lib/page/bill/bill_view.dart'), false);
  });
  test('format contains exact names descriptions URLs, no scores or IDs', () {
    final a = KnowledgeEntry(999, '名稱', '原文說明', [
      1,
    ], url: 'https://example.com/info');
    final b = KnowledgeEntry(998, '第二項', '另一說明', [1]);
    expect(
      formatResults([SearchHit(a, .9), SearchHit(b, .8)]),
      '以下為相關資訊\n\n1. 名稱\n   原文說明\n   https://example.com/info\n\n2. 第二項\n   另一說明\n   未提供連結',
    );
    expect(formatResults([]), '找不到相關結果');
  });
  testWidgets('valid URL clickable, null and source paths not clickable', (
    tester,
  ) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatResponse(
            '以下為相關資訊\nhttps://example.com/info\n未提供連結\nlib/page/bill/bill_view.dart',
            openUrl: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      ),
    );
    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.text('https://example.com/info'));
    await tester.pump();
    expect(opened.toString(), 'https://example.com/info');
  });
  testWidgets('URL launch failure visible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatResponse(
            'https://example.com',
            openUrl: (_) async => false,
          ),
        ),
      ),
    );
    await tester.tap(find.text('https://example.com'));
    await tester.pump();
    expect(find.text('無法開啟連結，請稍後再試。'), findsOneWidget);
  });
  test('corrupt JSON returns data error, not no matches', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'flutter/assets',
          (message) async => ByteData.sublistView(
            Uint8List.fromList(utf8.encode('broken JSON')),
          ),
        );
    try {
      await expectLater(
        ChatService().reply(message: 'test', history: []),
        throwsA(predicate((e) => e.toString().contains('檢索資料讀取失敗'))),
      );
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    }
  });
}
