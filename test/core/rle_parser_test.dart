import 'package:conway_game_of_life/core/rle_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rle parser ...', (tester) async {
    readRLE("assets/RLE_files/glider.rle");
  });
}
