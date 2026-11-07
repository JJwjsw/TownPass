import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:town_pass/page/chat/chat_panel.dart';
import 'package:town_pass/page/chat/draggable_chat_button.dart';

void main() {
  testWidgets(
    'button drags, stays on screen, fades after five seconds and wakes',
    (tester) async {
      var opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DraggableChatButton(onOpen: () => opens++)),
        ),
      );
      final button = find.byType(FloatingActionButton);
      final before = tester.getCenter(button);
      await tester.drag(button, const Offset(-200, -200));
      await tester.pump();
      expect(tester.getCenter(button).dx, lessThan(before.dx));
      expect(opens, 0);
      await tester.drag(button, const Offset(-2000, -2000));
      await tester.pump();
      expect(tester.getTopLeft(button).dx, greaterThanOrEqualTo(0));
      expect(tester.getTopLeft(button).dy, greaterThanOrEqualTo(0));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        .3,
      );
      await tester.tap(button);
      await tester.pump();
      expect(opens, 1);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'chat autofocus, tap outside hides keyboard without dismissing panel',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showChatPanel(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final input = find.byType(TextField);
      expect(tester.widget<TextField>(input).focusNode!.hasFocus, true);
      expect(tester.testTextInput.isVisible, true);
      await tester.tap(find.text('您好，請問您需要甚麼幫忙？'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(input).focusNode!.hasFocus, false);
      expect(find.byType(ChatPanel), findsOneWidget);
      await tester.tap(input);
      await tester.pump();
      expect(tester.widget<TextField>(input).focusNode!.hasFocus, true);
      await tester.tapAt(const Offset(10, 40));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(input).focusNode!.hasFocus, false);
      expect(find.byType(ChatPanel), findsOneWidget);
    },
  );
}
