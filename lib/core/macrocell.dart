import 'hashlife/node.dart';

/// Golly M2, two-state Conway trees. Repeated subtrees remain shared; never
/// expand a macrocell into a list of its potentially millions of live cells.
/// Source: https://golly.sourceforge.io/Help/formats.html#mc
Node parseMacrocell(String source) {
  if (source.length > 4000000) {
    throw const FormatException('Macrocell source exceeds 4 MB');
  }
  final lines = source.trim().split(RegExp(r'\r?\n'));
  if (!lines.first.startsWith('[M2]')) {
    throw const FormatException('Missing M2 macrocell header');
  }
  const dead = Node.leaf(false), alive = Node.leaf(true);
  final nodes = <Node>[];
  final interned = <(Node, Node, Node, Node), Node>{};
  Node join(Node a, Node b, Node c, Node d) =>
      interned.putIfAbsent((a, b, c, d), () => Node.branch(a, b, c, d));
  final empties = <Node>[dead];
  Node empty(int depth) {
    while (empties.length <= depth) {
      final e = empties.last;
      empties.add(join(e, e, e, e));
    }
    return empties[depth];
  }

  var largestDepth = 0;
  for (final raw in lines.skip(1)) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('#')) {
      if (line.startsWith('#R') &&
          ![
            'B3/S23',
            'S23/B3',
            '23/3',
            'LIFE',
          ].contains(line.substring(2).trim().toUpperCase())) {
        throw const FormatException('Only Conway B3/S23 is supported');
      }
      continue;
    }
    if (nodes.length >= 100000) {
      throw const FormatException('Macrocell exceeds 100,000 records');
    }
    late Node node;
    if (line.startsWith('.') || line.startsWith('*') || line.startsWith(r'$')) {
      final pixels = List.filled(64, dead);
      var x = 0, y = 0;
      for (final code in line.codeUnits) {
        if (code == 36) {
          y++;
          x = 0;
          if (y > 8) throw const FormatException('Too many macrocell rows');
        } else if ((code == 46 || code == 42) && x < 8 && y < 8) {
          pixels[y * 8 + x++] = code == 42 ? alive : dead;
        } else {
          throw const FormatException('Invalid 8 × 8 macrocell leaf');
        }
      }
      Node tile(int x, int y, int side) {
        if (side == 1) return pixels[y * 8 + x];
        final half = side ~/ 2;
        return join(
          tile(x, y, half),
          tile(x + half, y, half),
          tile(x, y + half, half),
          tile(x + half, y + half, half),
        );
      }

      node = tile(0, 0, 8);
    } else {
      final fields = line.split(RegExp(r'\s+')).map(int.tryParse).toList();
      if (fields.length != 5 || fields.any((v) => v == null)) {
        throw const FormatException('Invalid macrocell branch');
      }
      final depth = fields[0]!;
      if (depth < 4 || depth > 30) {
        throw const FormatException('Macrocell depth must be 4–30');
      }
      Node child(int index) {
        if (index < 0 || index > nodes.length) {
          throw const FormatException('Invalid macrocell reference');
        }
        final n = index == 0 ? empty(depth - 1) : nodes[index - 1];
        if (n.depth != depth - 1) {
          throw const FormatException('Macrocell child has the wrong depth');
        }
        return n;
      }

      node = join(
        child(fields[1]!),
        child(fields[2]!),
        child(fields[3]!),
        child(fields[4]!),
      );
      if (node.population > 9007199254740991) {
        throw const FormatException(
          'Macrocell population exceeds exact web integers',
        );
      }
    }
    largestDepth = node.depth > largestDepth ? node.depth : largestDepth;
    nodes.add(node);
  }
  if (nodes.isEmpty ||
      nodes.last.depth != largestDepth ||
      nodes.take(nodes.length - 1).any((n) => n.depth >= nodes.last.depth)) {
    throw const FormatException(
      'Macrocell must end with a single largest root',
    );
  }
  // Like RLE library entries, each selection starts at generation zero, with
  // the enclosing tree at local (0, 0). Golly's absolute origin is not imported.
  return nodes.last;
}
