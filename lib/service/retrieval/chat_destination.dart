import 'package:town_pass/page/city_service/model/my_service_model.dart';

import 'knowledge_source.dart';
import 'vector_search.dart';

enum ChatDestinationKind { missing, unsupported, route, web, tab, activities }

class ChatDestination {
  final ChatDestinationKind kind;
  final String? value;
  final int? tab;
  const ChatDestination(this.kind, {this.value, this.tab});
  bool get enabled =>
      kind != ChatDestinationKind.missing &&
      kind != ChatDestinationKind.unsupported;
}

final _services = MyServiceItemId.values
    .map((id) => id.item)
    .toList(growable: false);

/// JSON name matches the actual service title. IDs/descriptions are never used.
ChatDestination resolveDestination(KnowledgeEntry entry) {
  final title = entry.name.trim();
  final rawUrl = normalizeUrl(entry.url);
  if (isWebUrl(rawUrl)) {
    return ChatDestination(ChatDestinationKind.web, value: rawUrl);
  }
  const bills = {
    '停車費': 'fee-5',
    '水費': 'fee-6',
    '學雜費': 'fee-7',
    '國/社宅租金維管費': 'fee-8',
    '聯合醫院醫療費': 'fee-9',
    '平價住宅維護費': 'fee-10',
    '公訓處自費課程': 'fee-11',
    '地方稅': 'tax-1',
  };
  final bill = bills[title];
  if (bill != null) {
    return ChatDestination(
      ChatDestinationKind.web,
      value: 'https://taipei-pass-service.vercel.app/fee-payment/detail/$bill/',
    );
  }
  final shortcut = const {'掃描': 'scan', '紀錄': 'history'}[title];
  if (shortcut != null) {
    return ChatDestination(
      ChatDestinationKind.web,
      value: 'https://taipei-pass-service.vercel.app/fee-payment/$shortcut/',
    );
  }
  if (title == '警政服務') {
    return const ChatDestination(
      ChatDestinationKind.route,
      value: '/online_police',
    );
  }
  if (title == '個人資料') {
    return const ChatDestination(
      ChatDestinationKind.route,
      value: '/basic_info',
    );
  }
  if (title == '活動訊息') {
    return const ChatDestination(ChatDestinationKind.activities);
  }
  if (title == '優惠券列表') {
    return const ChatDestination(ChatDestinationKind.tab, tab: 2);
  }
  if (title == '票夾' || title == '入場券列表') {
    return const ChatDestination(
      ChatDestinationKind.web,
      value: 'https://taipei-pass-service.vercel.app/ticket-wallet',
    );
  }
  final matches = _services
      .where((item) => item.title.trim() == title)
      .toList();
  if (matches.length == 1 && isWebUrl(matches.single.destinationUrl)) {
    return ChatDestination(
      ChatDestinationKind.web,
      value: matches.single.destinationUrl,
    );
  }
  if (matches.length > 1) {
    return const ChatDestination(ChatDestinationKind.unsupported);
  }
  return ChatDestination(
    rawUrl == null
        ? ChatDestinationKind.missing
        : ChatDestinationKind.unsupported,
  );
}
