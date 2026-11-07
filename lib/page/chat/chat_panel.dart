import 'chat_response.dart';
import 'chat_results.dart';
import 'chat_navigation.dart';

import 'package:town_pass/service/retrieval/vector_search.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:town_pass/service/chat_service.dart';
import 'package:town_pass/service/speech_input_service.dart';
import 'package:town_pass/util/tp_colors.dart';

Future<void> showChatPanel(BuildContext context) async {
  TransitionRoute<dynamic>? sheetRoute;
  final entry = await showModalBottomSheet<KnowledgeEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      sheetRoute = ModalRoute.of(sheetContext) as TransitionRoute<dynamic>?;
      return SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
            const ChatPanel(),
          ],
        ),
      );
    },
  );
  if (entry == null) return;
  await sheetRoute?.completed;
  if (!context.mounted) return;
  try {
    await openChatDestination(entry);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('無法開啟此功能，請稍後再試。')));
    }
  }
}

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _inputKey = GlobalKey();
  final _scroll = ScrollController();
  final _service = ChatService();
  final Map<int, List<KnowledgeEntry>> _results = {};
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'content': ChatService.greeting},
  ];
  bool _sending = false;
  bool _recognizing = false;

  Future<void> _voiceInput() async {
    if (_recognizing || _sending) return;
    setState(() => _recognizing = true);
    _inputFocus.unfocus();
    try {
      final text = await SpeechInputService().recognize();
      if (!mounted) return;
      if (text != null && text.trim().isNotEmpty) {
        final previous = _input.text.trimRight();
        final combined = previous.isEmpty
            ? text.trim()
            : '$previous ${text.trim()}';
        setState(() {
          _input.value = TextEditingValue(
            text: combined,
            selection: TextSelection.collapsed(offset: combined.length),
          );
        });
      }
      _inputFocus.requestFocus();
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message ?? '無法啟動語音輸入')));
      }
    } on MissingPluginException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('目前平台不支援語音輸入')));
      }
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  Animation<double>? _routeAnimation;
  bool _requestedKeyboard = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeStatusListener(_showKeyboard);
      _routeAnimation = animation;
      animation?.addStatusListener(_showKeyboard);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          (animation == null ||
              animation.status == AnimationStatus.completed)) {
        _showKeyboard(AnimationStatus.completed);
      }
    });
  }

  void _showKeyboard(AnimationStatus status) {
    if (!mounted || _requestedKeyboard || status != AnimationStatus.completed) {
      return;
    }
    _requestedKeyboard = true;
    _inputFocus.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _routeAnimation?.removeStatusListener(_showKeyboard);
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || _recognizing) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _sending = true;
      _input.clear();
    });
    _scrollToBottom();
    try {
      final response = await _service.retrieve(message: text);
      if (!mounted) return;
      setState(() {
        _results[_messages.length] = response.entries;
        _messages.add({'role': 'assistant', 'content': response.text});
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'error', 'content': error.toString()});
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).top -
        keyboard;
    return Listener(
      onPointerDown: (event) {
        final box = _inputKey.currentContext?.findRenderObject() as RenderBox?;
        if (_inputFocus.hasFocus &&
            box != null &&
            !(box.localToGlobal(Offset.zero) & box.size).contains(
              event.position,
            )) {
          _inputFocus.unfocus();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: availableHeight * .88,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Material(
              color: const Color(0xFFEDF3F5),
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: TPColors.primary50,
                          foregroundColor: TPColors.primary600,
                          child: Icon(Icons.support_agent_rounded),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI 小幫手',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '本機服務檢索',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: TPColors.primary600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '關閉聊天',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return Padding(
                            padding: EdgeInsets.only(left: 44, bottom: 12),
                            child: Text(
                              '正在載入模型並檢索…',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        final message = _messages[index];
                        final isUser = message['role'] == 'user';
                        if (_results.containsKey(index)) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ChatResults(
                              entries: _results[index]!,
                              onOpen: (entry) =>
                                  Navigator.of(context).pop(entry),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: TPColors.primary500,
                                  child: Icon(
                                    Icons.support_agent_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.sizeOf(context).width * .7,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? const Color(0xFFB8E8C3)
                                          : Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(
                                          isUser ? 18 : 4,
                                        ),
                                        topRight: Radius.circular(
                                          isUser ? 4 : 18,
                                        ),
                                        bottomLeft: const Radius.circular(18),
                                        bottomRight: const Radius.circular(18),
                                      ),
                                    ),
                                    child: _results.containsKey(index)
                                        ? ChatResults(
                                            entries: _results[index]!,
                                            onOpen: (entry) =>
                                                Navigator.of(context)
                                                    .pop(entry),
                                          )
                                        : ChatResponse(message['content']!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                key: _inputKey,
                                focusNode: _inputFocus,
                                autofocus: true,
                                onTapOutside: (_) => _inputFocus.unfocus(),
                                keyboardType: TextInputType.text,
                                enableSuggestions: true,
                                controller: _input,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: '輸入想詢問的內容…',
                                  filled: true,
                                  fillColor: const Color(0xFFF3F5F6),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: '語音輸入',
                              color: TPColors.primary500,
                              onPressed: _sending || _recognizing
                                  ? null
                                  : _voiceInput,
                              icon: Icon(
                                _recognizing
                                    ? Icons.mic
                                    : Icons.mic_none_rounded,
                              ),
                            ),
                            IconButton.filled(
                              tooltip: '傳送訊息',
                              style: IconButton.styleFrom(
                                backgroundColor: TPColors.primary500,
                                foregroundColor: Colors.white,
                              ),
                              onPressed:
                                  _sending ||
                                      _recognizing ||
                                      _input.text.trim().isEmpty
                                  ? null
                                  : _send,
                              icon: const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
