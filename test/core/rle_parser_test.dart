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
  test(
    'sparse RLE retains wide coordinates and header names without a matrix',
    () {
      final block = parseRlePattern(
        '#N Wide gliders\nx = 1000000, y = 1000000, rule = S23/B3\no999999\$999999bo!',
      );
      expect(block.name, 'Wide gliders');
      expect(block.liveCells.toSet(), {(0, 0), (999999, 999999)});
      expect(block.population, 2);
    },
  );
  test('common exported RLE accepts a final row break and trailing notes', () {
    final block = parseRlePattern(
      '\uFEFF#CXRLE Pos=-20,-10\r\nx = 3, y = 3\r\nbo\$2bo\$3o\$!\nAuthor notes follow the pattern.',
    );
    expect(block.population, 5);
    expect(block.liveCells, contains((2, 2)));
  });
  test('sparse decoding rejects excess coordinates and live-cell counts', () {
    for (final source in [
      'x = 1000001, y = 1\no!',
      'x = 1, y = 1\n2\$!',
      'x = 1, y = 1\no\$o!',
      'x = 1000000, y = 2\n1000000o\$o!',
      'x = 2, y = 2, rule = B3/S23:T10,10\no!',
    ]) {
      expect(() => parseRlePattern(source), throwsFormatException);
    }
  });
}
