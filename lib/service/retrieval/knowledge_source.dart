import 'dart:convert';

String? normalizeUrl(Object? value) {
  if (value == null || value is num && value.isNaN) return null;
  if (value is! String) throw const FormatException('url 必須為字串或 null');
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty || normalized == 'nan' || normalized == 'null') {
    return null;
  }
  return value;
}

bool isWebUrl(String? value) {
  final uri = value == null ? null : Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

/// Replace only unquoted NaN tokens; quoted text is copied byte-for-byte.
List<Map<String, dynamic>> readRawKnowledge(String source) {
  final out = StringBuffer();
  bool quoted = false, escaped = false;
  for (var i = 0; i < source.length; i++) {
    final c = source[i];
    if (quoted) {
      out.write(c);
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (c == '"') {
        quoted = false;
      }
    } else if (c == '"') {
      quoted = true;
      out.write(c);
    } else if (source.startsWith('NaN', i) &&
        (i == 0 || RegExp(r'[\s:\[,]').hasMatch(source[i - 1])) &&
        (i + 3 == source.length ||
            RegExp(r'[\s,\]}]').hasMatch(source[i + 3]))) {
      out.write('null');
      i += 2;
    } else {
      out.write(c);
    }
  }
  final decoded = jsonDecode(out.toString());
  if (decoded is! List) throw const FormatException('來源必須為 JSON 陣列');
  final ids = <Object>{};
  return decoded.map((item) {
    if (item is! Map<String, dynamic>) throw const FormatException('每筆資料必須為物件');
    final id = item['id'];
    if ((id is! String && id is! int) || !ids.add(id!)) {
      throw FormatException('無效或重複 id：$id');
    }
    for (final key in ['name', 'description']) {
      if (item[key] is! String || (item[key] as String).trim().isEmpty) {
        throw FormatException('資料 $id：缺少或無效 $key');
      }
    }
    if (!item.containsKey('url')) throw FormatException('資料 $id：缺少 url');
    return <String, dynamic>{
      'id': id,
      'name': item['name'],
      'description': item['description'],
      'url': normalizeUrl(item['url']),
    };
  }).toList();
}
