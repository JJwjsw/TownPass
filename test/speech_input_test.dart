import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:town_pass/page/chat/chat_panel.dart';
import 'package:town_pass/service/speech_input_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SpeechInputService.channel, null),
  );
  testWidgets('mic left of send inserts speech without sending', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SpeechInputService.channel, (call) async {
          expect(call.method, 'recognize');
          return '停車費';
        });
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChatPanel())),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.byTooltip('語音輸入')).dx,
      lessThan(tester.getCenter(find.byTooltip('傳送訊息')).dx),
    );
    await tester.enterText(find.byType(TextField), '我要查');
    await tester.pump();
    await tester.tap(find.byTooltip('語音輸入'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '我要查 停車費',
    );
    expect(find.text('正在載入模型並檢索…'), findsNothing);
  });
  testWidgets('cancel keeps input; launch failure is visible', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SpeechInputService.channel,
          (_) async => null,
        );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChatPanel())),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '保留文字');
    await tester.pump();
    await tester.tap(find.byTooltip('語音輸入'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '保留文字',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SpeechInputService.channel, (_) async {
          throw PlatformException(code: 'unavailable', message: '未安裝語音服務');
        });
    await tester.tap(find.byTooltip('語音輸入'));
    await tester.pumpAndSettle();
    expect(find.text('未安裝語音服務'), findsOneWidget);
  });
}
