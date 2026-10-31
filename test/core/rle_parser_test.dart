import 'package:conway_game_of_life/core/rle_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'comments, run counts and row offsets decode into column-major cells',
    () {
      final cells = parseRLE(
        '#N Glider\nx = 3, y = 3, rule = B3/S23\nbo\$2bo\$3o!',
      );
      expect(cells, [
        [false, false, true],
        [true, false, true],
        [false, true, true],
      ]);
    },
  );
  test('multi-digit counts and skipped rows', () {
    final cells = parseRLE('x = 12, y = 4\n12o3\$bo!');
    expect(cells.where((column) => column[0]).length, 12);
    expect(cells[1][3], isTrue);
    expect(cells[0][1], isFalse);
  });
  test('invalid and non-Conway patterns fail explicitly', () {
    for (final input in [
      '',
      'x = 0, y = 1\n!',
      'x = 1, y = 1\n2o!',
      'x = 1, y = 1\no',
      'x = 1, y = 1\nq!',
      'x = 1, y = 1, rule = B36/S23\no!',
      'x = 1, y = 1\n0o!',
      'x = 1, y = 1\no!o',
      'x = 1, y = 1\n\$o!',
      'x = 1000000, y = 1000000\n!',
    ]) {
      expect(() => parseRLE(input), throwsFormatException, reason: input);
    }
  });
  test('bundled RLE loads through Flutter assets', () async {
    final matrix = await readRLE('assets/RLE_files/glider.rle');
    expect(matrix.expand((column) => column).where((alive) => alive).length, 5);
  });
}
