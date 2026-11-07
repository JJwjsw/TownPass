import 'dart:async';

import 'package:flutter/material.dart';
import 'package:town_pass/util/tp_colors.dart';

import 'chat_panel.dart';

class DraggableChatButton extends StatefulWidget {
  final VoidCallback? onOpen;
  const DraggableChatButton({super.key, this.onOpen});
  @override
  State<DraggableChatButton> createState() => _DraggableChatButtonState();
}

class _DraggableChatButtonState extends State<DraggableChatButton> {
  Timer? _idle;
  Offset? _position;
  bool _faded = false, _opening = false;
  @override
  void initState() {
    super.initState();
    _resetIdle();
  }

  void _resetIdle() {
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _faded = true);
    });
  }

  void _wake() {
    if (_faded) setState(() => _faded = false);
    _resetIdle();
  }

  @override
  void dispose() {
    _idle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      const size = 56.0, margin = 12.0;
      final maxX = (c.maxWidth - size - margin).clamp(margin, double.infinity);
      final maxY = (c.maxHeight - size - margin).clamp(margin, double.infinity);
      final p = Offset(
        (_position?.dx ?? maxX).clamp(margin, maxX),
        (_position?.dy ?? maxY - 36).clamp(margin, maxY),
      );
      return Stack(
        children: [
          Positioned(
            left: p.dx,
            top: p.dy,
            child: GestureDetector(
              onPanStart: (_) {
                _wake();
                _idle?.cancel();
              },
              onPanUpdate: (d) => setState(
                () => _position = Offset(
                  (p.dx + d.delta.dx).clamp(margin, maxX),
                  (p.dy + d.delta.dy).clamp(margin, maxY),
                ),
              ),
              onPanEnd: (_) => _resetIdle(),
              onPanCancel: _resetIdle,
              child: Listener(
                onPointerDown: (_) => _wake(),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _faded ? 0.3 : 1,
                  child: FloatingActionButton(
                    heroTag: 'home_chat',
                    tooltip: '開啟 AI 小幫手',
                    backgroundColor: TPColors.primary500,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    onPressed: () async {
                      if (_opening) return;
                      _wake();
                      _opening = true;
                      _idle?.cancel();
                      try {
                        if (widget.onOpen != null) {
                          widget.onOpen!();
                        } else {
                          await showChatPanel(context);
                        }
                      } finally {
                        _opening = false;
                        if (mounted) _resetIdle();
                      }
                    },
                    child: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
