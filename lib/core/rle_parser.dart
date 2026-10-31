import 'package:flutter/services.dart';

import 'rle_pattern.dart';
export 'rle_pattern.dart';

/// Load bundled patterns on web and native targets without dart:io.
Future<List<List<bool>>> readRLE(String asset) async =>
    parseRLE(await rootBundle.loadString(asset));

/// Compatibility API for small column-major [x][y] matrices.
/// Use [parseRlePattern] for large, sparse patterns.
List<List<bool>> parseRLE(String source) {
  final pattern = parseRlePattern(source);
  if (pattern.cols * pattern.rows > 1000000) {
    throw const FormatException(
      'Matrix exceeds 1,000,000 cells; use sparse RLE',
    );
  }
  return pattern.matrixBlock;
}
