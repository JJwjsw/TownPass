import 'package:get/get.dart';
import 'package:town_pass/page/main/main_view_controller.dart';
import 'package:town_pass/page/home/widget/activity_info/activity_banner_widget_controller.dart';
import 'package:town_pass/util/tp_route.dart';
import 'package:town_pass/util/tp_web_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:town_pass/service/retrieval/chat_destination.dart';
import 'package:town_pass/service/retrieval/knowledge_source.dart';
import 'package:town_pass/service/retrieval/vector_search.dart';

Future<void> openChatDestination(KnowledgeEntry entry) async {
  final target = resolveDestination(entry);
  switch (target.kind) {
    case ChatDestinationKind.route:
      await Get.toNamed(target.value!, preventDuplicates: false);
    case ChatDestinationKind.web:
      if (isWebUrl(entry.url)) {
        if (!await launchUrl(Uri.parse(target.value!))) {
          throw StateError('無法開啟連結');
        }
      } else {
        // Same in-app WebView and permission behavior used by existing service cards.
        await Get.toNamed(
          TPRoute.webView,
          preventDuplicates: false,
          arguments: WebViewArgument(
            url: target.value!,
            forceTitle: entry.name,
          ),
        );
      }
    case ChatDestinationKind.tab:
      Get.find<MainViewController>().currentIndex.value = target.tab!;
    case ChatDestinationKind.activities:
      final controller = Get.find<ActivityBannerWidgetController>();
      for (
        var attempt = 0;
        controller.list == null && attempt < 25;
        attempt++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      final list = controller.list;
      if (list == null) throw StateError('活動資料尚未載入，請稍後再試。');
      await Get.toNamed(
        TPRoute.activityList,
        arguments: list,
        preventDuplicates: false,
      );
    case ChatDestinationKind.missing:
    case ChatDestinationKind.unsupported:
      throw StateError('此功能暫不支援直接開啟');
  }
}
