import 'dart:typed_data';

import 'node.dart';

/// Interns branches by their four children without allocating a lookup key.
///
/// Slots use linear probing; the stored hash avoids comparing children on most
/// collisions and lets a resize move nodes without hashing them again.
final class NodeTable {
  var _slots = List<Node?>.filled(256, null);
  var _hashes = Uint32List(256);
  int _length = 0;

  int get length => _length;

  Node join(Node a, Node b, Node c, Node d) {
    final hash = Object.hash(a, b, c, d);
    final mask = _slots.length - 1;
    var index = hash & mask;
    while (true) {
      final node = _slots[index];
      if (node == null) {
        final added = Node.branch(a, b, c, d);
        _slots[index] = added;
        _hashes[index] = hash;
        _length++;
        if (_length * 4 >= _slots.length * 3) _grow();
        return added;
      }
      if (_hashes[index] == hash &&
          identical(node.nw, a) &&
          identical(node.ne, b) &&
          identical(node.sw, c) &&
          identical(node.se, d)) {
        return node;
      }
      index = (index + 1) & mask;
    }
  }

  void _grow() {
    final oldSlots = _slots, oldHashes = _hashes;
    _slots = List<Node?>.filled(oldSlots.length * 2, null);
    _hashes = Uint32List(_slots.length);
    final mask = _slots.length - 1;
    for (var i = 0; i < oldSlots.length; i++) {
      final node = oldSlots[i];
      if (node == null) continue;
      final hash = oldHashes[i];
      var index = hash & mask;
      while (_slots[index] != null) {
        index = (index + 1) & mask;
      }
      _slots[index] = node;
      _hashes[index] = hash;
    }
  }

  void clear() {
    _slots = List<Node?>.filled(256, null);
    _hashes = Uint32List(256);
    _length = 0;
  }
}
