import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:town_pass/service/retrieval/knowledge_source.dart';

/// Render preserved response lines; only complete HTTP(S) lines are links.
class ChatResponse extends StatelessWidget {
  final String text;
  final Future<bool> Function(Uri)? openUrl;
  const ChatResponse(this.text, {super.key, this.openUrl});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: text.split('\n').map((line) {
      final value = line.trim();
      if (!isWebUrl(value)) {
        return SelectableText(
          line,
          style: const TextStyle(fontSize: 15, height: 1.5),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(left: 12),
        child: InkWell(
          onTap: () async {
            try {
              final success = await (openUrl ?? launchUrl)(Uri.parse(value));
              if (!success) throw StateError('無法開啟');
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('無法開啟連結，請稍後再試。')));
              }
            }
          },
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    }).toList(),
  );
}
