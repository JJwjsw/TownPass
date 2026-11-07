import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:town_pass/page/chat/chat_results.dart';
import 'package:town_pass/page/city_service/model/my_service_model.dart';
import 'package:town_pass/service/retrieval/chat_destination.dart';
import 'package:town_pass/service/retrieval/vector_search.dart';

void main() {
  KnowledgeEntry entry(
    String name, {
    Object id = 999,
    String description = '不同的說明',
    String? url = 'lib/changed.dart',
  }) => KnowledgeEntry(id, name, description, const [], url: url);
  test('matches actual service title independently of ID description and source path', () {
    for (final id in MyServiceItemId.values) {
      final item = id.item;
      final target = resolveDestination(entry(item.title));
      if (item.destinationUrl.startsWith('https://')) {
        expect(target.value, item.destinationUrl);
      }
    }
    expect(
      resolveDestination(entry('圖書借閱', id: 1, description: '完全不同')).value,
      endsWith('/library-service/'),
    );
    expect(
      resolveDestination(entry('圖書借閱', id: 123, url: null)).value,
      endsWith('/library-service/'),
    );
    expect(resolveDestination(entry('不相符的名稱', id: 39)).enabled, false);
    expect(
      resolveDestination(entry(' 圖書借閱 ')).value,
      endsWith('/library-service/'),
    );
  });
  test('bill shortcuts and native pages match names', () {
    expect(resolveDestination(entry('停車費')).value, endsWith('/fee-5/'));
    expect(resolveDestination(entry('水費')).value, endsWith('/fee-6/'));
    expect(resolveDestination(entry('地方稅')).value, endsWith('/tax-1/'));
    expect(resolveDestination(entry('掃描')).value, endsWith('/scan/'));
    expect(resolveDestination(entry('紀錄')).value, endsWith('/history/'));
    expect(resolveDestination(entry('警政服務')).value, '/online_police');
    expect(resolveDestination(entry('個人資料')).value, '/basic_info');
    expect(
      resolveDestination(entry('活動訊息')).kind,
      ChatDestinationKind.activities,
    );
    expect(resolveDestination(entry('優惠券列表')).tab, 2);
    expect(resolveDestination(entry('票夾')).value, endsWith('/ticket-wallet'));
  });
  test('all 46 real records resolve identically when IDs descriptions and paths change', () {
    final rows = jsonDecode(
      File('assets/data/knowledge_raw.json').readAsStringSync(),
    ) as List;
    expect(rows.length, 46);
    for (final row in rows) {
      final original = resolveDestination(
        entry(
          row['name'],
          id: row['id'],
          description: row['description'],
          url: row['url'],
        ),
      );
      final changed = resolveDestination(
        entry(
          row['name'],
          id: 'new-id',
          description: '說明不同',
          url: row['url'] == null ? null : 'lib/other.dart',
        ),
      );
      expect(
        [changed.kind, changed.value, changed.tab],
        [original.kind, original.value, original.tab],
        reason: row['name'],
      );
    }
  });
  test('empty destinations stay unsupported; external URLs remain usable', () {
    for (final name in ['疫苗預約', '台北電台', '新增綁定', '發票', '收據']) {
      expect(
        resolveDestination(entry(name)).kind,
        ChatDestinationKind.unsupported,
      );
    }
    for (final url in [null, 'NaN', ' ', 'null']) {
      expect(
        resolveDestination(entry('未知服務', url: url)).kind,
        ChatDestinationKind.missing,
      );
    }
    expect(
      resolveDestination(entry('未知服務', url: 'https://example.com')).value,
      'https://example.com',
    );
  });
  testWidgets(
    'structured UI shows title-based link and preserves original record',
    (tester) async {
      final item = entry('圖書借閱', id: 'changed');
      KnowledgeEntry? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatResults(
              entries: [item, entry('未知', url: null), entry('疫苗預約')],
              onOpen: (e) => selected = e,
            ),
          ),
        ),
      );
      expect(find.text('圖書借閱'), findsOneWidget);
      expect(find.text('未提供連結'), findsOneWidget);
      expect(find.text('此功能暫不支援直接開啟'), findsOneWidget);
      expect(find.textContaining('lib/'), findsNothing);
      await tester.tap(find.text('圖書借閱'));
      expect(identical(selected, item), true);
    },
  );
  testWidgets('empty result remains no matches', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatResults(entries: const [], onOpen: (_) {}),
      ),
    );
    expect(find.text('找不到相關結果'), findsOneWidget);
  });
}
