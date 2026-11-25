library;

const _accents = {
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n', //
};

String slugify(String text) {
  final lower = text.toLowerCase().split('').map((c) => _accents[c] ?? c);
  final slug = lower
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'equipo' : slug;
}

String uniqueId(String base, Set<String> taken) {
  if (!taken.contains(base)) return base;
  var i = 2;
  while (taken.contains('$base-$i')) {
    i++;
  }
  return '$base-$i';
}

String defaultShortName(String name) {
  final words = slugify(name).split('-').where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return 'EQ';
  final short = words.length == 1
      ? words.first.substring(0, words.first.length.clamp(0, 3))
      : words.take(3).map((w) => w[0]).join();
  return short.toUpperCase();
}

String matchId(String localId, String visitId, DateTime start) {
  String two(int n) => n.toString().padLeft(2, '0');
  final stamp =
      '${start.year}${two(start.month)}${two(start.day)}-'
      '${two(start.hour)}${two(start.minute)}';
  return '${localId}_vs_${visitId}_$stamp';
}
