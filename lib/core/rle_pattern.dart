import 'models/block.dart';

/// Decode two-state Conway RLE without allocating the empty bounding rectangle.
/// Comments and CXRLE annotations are accepted; placement uses local coordinates.
Block parseRlePattern(String source, {String? name, String description = ''}) {
  if (source.length > 4000000) {
    throw const FormatException('RLE source exceeds 4 MB');
  }
  final lines = source.replaceFirst('\uFEFF', '').split(RegExp(r'\r?\n'));
  String? headerLine;
  final body = StringBuffer();
  String? embeddedName;
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('#')) {
      if (line.startsWith('#N ')) embeddedName ??= line.substring(3).trim();
      continue;
    }
    if (headerLine == null) {
      headerLine = line;
    } else {
      body.write(line);
      // RLE files may carry free-form author notes after the terminated line.
      if (line.contains('!')) break;
    }
  }
  final header = RegExp(
    r'^x\s*=\s*(\d+)\s*,\s*y\s*=\s*(\d+)(?:\s*,\s*rule\s*=\s*(\S+))?\s*$',
    caseSensitive: false,
  ).firstMatch(headerLine ?? '');
  if (header == null) {
    throw const FormatException('Invalid or missing RLE header');
  }
  final width = int.tryParse(header[1]!);
  final height = int.tryParse(header[2]!);
  final rule = header[3]?.toUpperCase();
  if (rule != null && !['B3/S23', 'S23/B3', '23/3'].contains(rule)) {
    throw const FormatException('Only Conway B3/S23 is supported');
  }
  if (width == null ||
      height == null ||
      width < 1 ||
      height < 1 ||
      width > 1000000 ||
      height > 1000000) {
    throw const FormatException(
      'Pattern dimensions must be between 1 and 1,000,000',
    );
  }
  final cells = <(int, int)>[];
  final data = body.toString().replaceAll(RegExp(r'\s'), '');
  var x = 0, y = 0, count = 0;
  var hasCount = false;
  for (var i = 0; i < data.length; i++) {
    final code = data.codeUnitAt(i);
    if (code >= 48 && code <= 57) {
      hasCount = true;
      count = count * 10 + code - 48;
      if (count > 1000000) throw const FormatException('Run too large');
      continue;
    }
    final token = data[i];
    final run = hasCount ? count : 1;
    if (run == 0) throw const FormatException('Zero-length run');
    if (token == '!') {
      if (hasCount || i != data.length - 1) {
        throw const FormatException('Invalid terminator');
      }
      return Block.sparse(
        name: name ?? embeddedName ?? 'Untitled pattern',
        des: description,
        cols: width,
        rows: height,
        positions: List.unmodifiable(cells),
      );
    }
    if (token == r'$') {
      y += run;
      x = 0;
      // A final row separator before ! is valid in common RLE exports.
      if (y > height) throw const FormatException('Too many rows');
    } else if (token == 'b' || token == 'o') {
      if (y >= height || x + run > width) {
        throw const FormatException('Run exceeds pattern bounds');
      }
      if (token == 'o') {
        if (cells.length + run > 1000000) {
          throw const FormatException('Pattern exceeds 1,000,000 live cells');
        }
        for (var dx = 0; dx < run; dx++) {
          cells.add((x + dx, y));
        }
      }
      x += run;
    } else {
      throw FormatException('Invalid RLE token: $token');
    }
    count = 0;
    hasCount = false;
  }
  throw const FormatException('Missing RLE terminator');
}
