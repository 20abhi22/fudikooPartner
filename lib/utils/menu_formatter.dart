/// The API sends `menu_items` as newline separated entries. Cards render them
/// inline, so join the entries with ", " instead of breaking onto a new line.
String formatMenuItems(dynamic raw) {
  if (raw == null) return '';

  final items = raw
      .toString()
      .split(RegExp(r'[\r\n]+'))
      .map((item) => item.trim().replaceAll(RegExp(r'[,\s]+$'), ''))
      .where((item) => item.isNotEmpty)
      .toList();

  return items.join(', ');
}
