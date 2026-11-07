import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:town_pass/main.dart' as app;
import 'package:town_pass/service/retrieval/vector_search.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real model chat and reopen', (tester) async {
    final results = <String>[];
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (finder.evaluate().isNotEmpty) return;
      }
      throw StateError('Timed out: $finder');
    }

    Future<void> send(String input, Finder expected) async {
      await tester.enterText(find.byType(TextField), input);
      await tester.pump();
      await tester.tap(find.byTooltip('傳送訊息'));
      await waitFor(expected);
      // Allow scroll animation to complete, and capture exceptions.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }

    app.main();
    await waitFor(find.byTooltip('開啟 AI 小幫手'));
    await tester.tap(find.byTooltip('開啟 AI 小幫手'));
    await waitFor(find.byType(TextField));
    await send('新設一間有限公司，要在哪裡付辦理登記的費用？', find.text('公司登記費'));
    expect(find.textContaining('筆相關內容'), findsWidgets);
    expect(find.text('未提供連結'), findsWidgets);
    results.add(
      'related query -> company registration, exact format and null URL placeholder',
    );
    final dir = await getApplicationSupportDirectory();
    final model = File('${dir.path}/${RetrievalConfig.modelName}');
    final before = await model.stat();

    await send('請教我用奶油製作巧克力布朗尼', find.text('找不到相關結果'));
    results.add('unrelated query -> no matches');
    await send('我想打流感預防針，要先到哪裡約時間？', find.text('疫苗預約'));
    expect(find.text('此功能暫不支援直接開啟'), findsWidgets);
    results.add(
      'consecutive query -> vaccine, unsupported navigation status shown',
    );

    await tester.tap(find.byTooltip('關閉聊天'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('開啟 AI 小幫手'));
    await waitFor(find.byType(TextField));
    await send('想在手機上收聽臺北的廣播節目', find.text('台北電台'));
    final after = await model.stat();
    expect(after.modified, before.modified);
    expect(after.size, before.size);
    results.add(
      'close/reopen -> radio result; model cache size and mtime unchanged',
    );
    await send('我要使用警政服務線上報案', find.text('警政服務'));
    await tester.ensureVisible(find.text('警政服務'));
    await tester.tap(find.text('警政服務'));
    await waitFor(find.text('警政報案系統'));
    expect(find.byType(TextField), findsNothing);
    results.add(
      'police query -> navigation closes chat and opens police reporting page',
    );
    await tester.pageBack();
    await waitFor(find.byTooltip('開啟 AI 小幫手'));
    await tester.tap(find.byTooltip('開啟 AI 小幫手'));
    await waitFor(find.byType(TextField));
    await send('想在手機上收聽臺北的廣播節目', find.text('台北電台'));
    results.add('return from navigation -> chat works again');
    await File('${dir.path}/android-test-results.json')
        .writeAsString(jsonEncode(results));
  }, timeout: const Timeout(Duration(minutes: 5)));
}
