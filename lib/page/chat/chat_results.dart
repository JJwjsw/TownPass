import 'package:flutter/material.dart';
import 'package:town_pass/page/city_service/model/my_service_model.dart';
import 'package:town_pass/service/retrieval/chat_destination.dart';
import 'package:town_pass/service/retrieval/vector_search.dart';
import 'package:town_pass/util/tp_colors.dart';

String resultCategory(KnowledgeEntry entry) {
  final path = entry.url ?? '';
  if (path.contains('/bill/')) return '帳單';
  for (final id in MyServiceItemId.values) {
    final item = id.item;
    if (item.title == entry.name) return item.category.title;
  }
  if (path.contains('/perk/')) return '票券優惠';
  if (entry.name == '活動訊息') return '活動';
  if (entry.name == '個人資料') return '帳戶';
  return '市政服務';
}

class ChatResults extends StatelessWidget {
  final List<KnowledgeEntry> entries;
  final ValueChanged<KnowledgeEntry> onOpen;
  const ChatResults({super.key, required this.entries, required this.onOpen});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CircleAvatar(
        radius: 16,
        backgroundColor: TPColors.primary500,
        child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Text(
                entries.isEmpty
                    ? RetrievalConfig.noResultsMessage
                    : '找到 ${entries.length} 筆相關內容，您可以直接點選前往：',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF202829),
                ),
              ),
            ),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _ResultCard(entry: entry, onOpen: onOpen),
              ),
          ],
        ),
      ),
    ],
  );
}

class _ResultCard extends StatelessWidget {
  final KnowledgeEntry entry;
  final ValueChanged<KnowledgeEntry> onOpen;
  const _ResultCard({required this.entry, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final destination = resolveDestination(entry);
    return Semantics(
      button: destination.enabled,
      enabled: destination.enabled,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: destination.enabled ? () => onOpen(entry) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resultCategory(entry),
                        style: const TextStyle(
                          fontSize: 12,
                          color: TPColors.primary600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202829),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        entry.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: Color(0xFF808080),
                        ),
                      ),
                      if (!destination.enabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            destination.kind == ChatDestinationKind.missing
                                ? '未提供連結'
                                : '此功能暫不支援直接開啟',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 28,
                  color: destination.enabled
                      ? TPColors.primary600
                      : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
