import 'package:flutter/services.dart';

/// Load bundled patterns on web and native targets without dart:io.
Future<List<List<bool>>> readRLE(String asset) async =>
    parseRLE(await rootBundle.loadString(asset));

/// Parse Conway RLE into the app's column-major [x][y] matrix.
List<List<bool>> parseRLE(String source) {
  final lines = source
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toList();
  if (lines.isEmpty) throw const FormatException('Missing RLE header');
  final header = RegExp(
    r'^x\s*=\s*(\d+)\s*,\s*y\s*=\s*(\d+)(?:\s*,\s*rule\s*=\s*(\S+))?\s*$',
    caseSensitive: false,
  ).firstMatch(lines.first);
  if (header == null) throw const FormatException('Invalid RLE header');
  final width = int.parse(header[1]!);
  final height = int.parse(header[2]!);
  final rule = header[3]?.toUpperCase();
  if (rule != null && rule != 'B3/S23' && rule != '23/3') {
    throw const FormatException('Only Conway B3/S23 is supported');
  }
  if (width < 1 || height < 1 || width * height > 1000000) {
    throw const FormatException('Invalid or oversized pattern');
  }
  final cells = List.generate(width, (_) => List.filled(height, false));
  final body = lines.skip(1).join().replaceAll(RegExp(r'\s'), '');
  var x = 0, y = 0, count = 0;
  var hasCount = false;
  for (var i = 0; i < body.length; i++) {
    final token = body[i];
    final digit = int.tryParse(token);
    if (digit != null) {
      hasCount = true;
      count = count * 10 + digit;
      if (count > 1000000) throw const FormatException('Run too large');
      continue;
    }
    final run = hasCount ? count : 1;
    if (run == 0) throw const FormatException('Zero-length run');
    if (token == '!') {
      if (hasCount || i != body.length - 1) {
        throw const FormatException('Invalid terminator');
      }
      return cells;
    }
    if (token == r'$') {
      y += run;
      x = 0;
      if (y >= height) throw const FormatException('Too many rows');
    } else if (token == 'b' || token == 'o') {
      if (y >= height || x + run > width) {
        throw const FormatException('Run exceeds pattern bounds');
      }
      if (token == 'o') {
        for (var dx = 0; dx < run; dx++) {
          cells[x + dx][y] = true;
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
