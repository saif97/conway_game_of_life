import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/block.dart';
import 'macrocell.dart';
import 'rle_pattern.dart';

class PatternGroup {
  const PatternGroup(this.id, this.name, this.description);
  final String id, name, description;
}

class PatternEntry {
  const PatternEntry({
    required this.id,
    required this.name,
    required this.group,
    required this.description,
    required this.tip,
    required this.asset,
    required this.source,
    required this.credit,
    this.jumpExponent,
  });
  final String id, name, group, description, tip, asset, source, credit;
  final int? jumpExponent;

  bool matches(String query, PatternGroup category) {
    final text = '$name $description $tip ${category.name}'.toLowerCase();
    return query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .every(text.contains);
  }
}

/// Metadata loads once; pattern bodies are decoded only as their cards are visited.
class PatternCatalog {
  PatternCatalog._(this.groups, this.patterns, this._bundle);
  final List<PatternGroup> groups;
  final List<PatternEntry> patterns;
  final AssetBundle _bundle;
  final _loaded = <String, Future<Block>>{};

  static Future<PatternCatalog> load({AssetBundle? bundle}) async {
    bundle ??= rootBundle;
    final data = jsonDecode(
      await bundle.loadString('assets/patterns/catalog.json', cache: false),
    ) as Map<String, dynamic>;
    final groups = <PatternGroup>[];
    final groupIds = <String>{};
    for (final item in data['groups'] as List) {
      final id = item['id'] as String;
      if (!groupIds.add(id)) throw FormatException('Duplicate group: $id');
      groups.add(
        PatternGroup(id, item['name'] as String, item['description'] as String),
      );
    }
    final patterns = <PatternEntry>[];
    final ids = <String>{};
    for (final item in data['patterns'] as List) {
      final id = item['id'] as String;
      final group = item['group'] as String;
      if (!ids.add(id) || !groupIds.contains(group)) {
        throw FormatException('Duplicate pattern or unknown group: $id');
      }
      final jumpExponent = item['jumpExponent'] as int?;
      if (jumpExponent != null && (jumpExponent < 0 || jumpExponent > 20)) {
        throw FormatException('Invalid starting jump: $id');
      }
      patterns.add(
        PatternEntry(
          id: id,
          name: item['name'] as String,
          group: group,
          description: item['description'] as String,
          tip: item['tip'] as String,
          asset: item['asset'] as String,
          source: item['source'] as String,
          credit: item['credit'] as String,
          jumpExponent: jumpExponent,
        ),
      );
    }
    return PatternCatalog._(
      List.unmodifiable(groups),
      List.unmodifiable(patterns),
      bundle,
    );
  }

  Future<Block> loadPattern(PatternEntry entry) =>
      _loaded.putIfAbsent(entry.id, () => _decode(entry));

  Future<Block> _decode(PatternEntry entry) async {
    try {
      final source = await _bundle.loadString(entry.asset, cache: false);
      if (entry.asset.endsWith('.mc')) {
        return Block.macrocell(
          name: entry.name,
          des: entry.description,
          root: parseMacrocell(source),
          source: source,
        );
      }
      return parseRlePattern(
        source,
        name: entry.name,
        description: entry.description,
      );
    } catch (_) {
      _loaded.remove(entry.id);
      rethrow;
    }
  }
}
