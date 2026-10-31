import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/block.dart';
import '../core/pattern_catalog.dart';
import '../core/view_model/model_board.dart';

const _muted = Color(0xFF9BA897);
const _accent = Color(0xFFB8F36D);

class SubBlockExplorer extends StatefulWidget {
  const SubBlockExplorer({super.key, this.loadCatalog});
  final Future<PatternCatalog> Function()? loadCatalog;
  @override
  State<SubBlockExplorer> createState() => _SubBlockExplorerState();
}

class _SubBlockExplorerState extends State<SubBlockExplorer> {
  late Future<PatternCatalog> _catalog = _load();
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _expanded = <String>{};
  bool _alphabetical = false;
  String _query = '';

  Future<PatternCatalog> _load() =>
      (widget.loadCatalog ?? PatternCatalog.load)();

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _updateQuery(String query) {
    setState(() => _query = query);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF171C19),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
          child: Text(
            'PATTERN LIBRARY',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
              color: _accent,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Small to extraordinary.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
            'Explore a family. Find your next experiment.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _search,
            onChanged: _updateQuery,
            decoration: InputDecoration(
              hintText: 'Find a pattern',
              prefixIcon: const Icon(Icons.search, size: 19),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _search.clear();
                        _updateQuery('');
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<PatternCatalog>(
            future: _catalog,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load the library.'),
                      TextButton(
                        onPressed: () => setState(() {
                          _catalog = _load();
                        }),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _library(snapshot.data!);
            },
          ),
        ),
      ],
    ),
  );

  Widget _library(PatternCatalog catalog) {
    final searching = _query.trim().isNotEmpty;
    final rows = <Widget>[];
    var count = 0;
    for (final group in catalog.groups) {
      final entries = catalog.patterns
          .where(
            (entry) => entry.group == group.id && entry.matches(_query, group),
          )
          .toList();
      if (entries.isEmpty) continue;
      count += entries.length;
      if (_alphabetical) entries.sort((a, b) => a.name.compareTo(b.name));
      final expanded = searching || _expanded.contains(group.id);
      rows.add(
        Semantics(
          key: ValueKey('group-${group.id}'),
          expanded: expanded,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(
              '${group.name} · ${entries.length}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              group.description,
              style: const TextStyle(fontSize: 11, color: _muted),
            ),
            trailing: Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            onTap: searching
                ? null
                : () => setState(() {
                    if (!_expanded.remove(group.id)) _expanded.add(group.id);
                  }),
          ),
        ),
      );
      if (expanded) {
        for (final entry in entries) {
          rows.add(
            _PatternCard(
              key: ValueKey(entry.id),
              entry: entry,
              catalog: catalog,
            ),
          );
        }
      }
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 12, 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$count ${searching ? 'matches' : 'patterns · ${catalog.groups.length} families'}',
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ),
              DropdownButton<bool>(
                value: _alphabetical,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 11, color: _muted),
                items: const [
                  DropdownMenuItem(value: false, child: Text('Explore order')),
                  DropdownMenuItem(value: true, child: Text('Name A–Z')),
                ],
                onChanged: (value) => setState(() => _alphabetical = value!),
              ),
            ],
          ),
        ),
        Expanded(
          child: count == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, color: _muted),
                        const SizedBox(height: 12),
                        const Text('No matching patterns'),
                        const SizedBox(height: 6),
                        const Text(
                          'Try “glider”, “circuit” or “growth”.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () {
                            _search.clear();
                            _updateQuery('');
                          },
                          child: const Text('Show all patterns'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: rows.length,
                  itemBuilder: (_, index) => rows[index],
                ),
        ),
      ],
    );
  }
}

class _PatternCard extends StatefulWidget {
  const _PatternCard({super.key, required this.entry, required this.catalog});
  final PatternEntry entry;
  final PatternCatalog catalog;
  @override
  State<_PatternCard> createState() => _PatternCardState();
}

class _PatternCardState extends State<_PatternCard> {
  late Future<Block> _block = widget.catalog.loadPattern(widget.entry);

  void _select(Block block, {bool place = false}) {
    final model = context.read<ModelBoard>();
    if (place) {
      model.enableBlockInsertionMode(block);
    } else {
      model.loadPattern(block);
    }
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _details() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(widget.entry.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.entry.description),
            const SizedBox(height: 16),
            Text(widget.entry.tip),
            const SizedBox(height: 24),
            Text(
              widget.entry.credit,
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.entry.source,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: const Color(0xFF202720),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF343E32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Block>(
        future: _block,
        builder: (context, snapshot) {
          final block = snapshot.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: block == null ? null : () => _select(block),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 50,
                            height: 44,
                            child: block == null
                                ? const Icon(Icons.grid_4x4, color: _muted)
                                : RepaintBoundary(
                                    child: CustomPaint(
                                      painter: PatternPainter(block),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.entry.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  block == null
                                      ? (snapshot.hasError
                                            ? 'Pattern unavailable'
                                            : 'Loading preview…')
                                      : '${block.cols} × ${block.rows} · ${block.population} alive',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.entry.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (snapshot.hasError)
                TextButton(
                  onPressed: () => setState(() {
                    _block = widget.catalog.loadPattern(widget.entry);
                  }),
                  child: const Text('Retry pattern'),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'About ${widget.entry.name}',
                      onPressed: _details,
                      icon: const Icon(Icons.info_outline, size: 16),
                    ),
                    TextButton(
                      onPressed: block == null
                          ? null
                          : () => _select(block, place: true),
                      child: const Text(
                        'Place',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    TextButton(
                      onPressed: block == null ? null : () => _select(block),
                      child: const Text(
                        'Load world',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class PatternPainter extends CustomPainter {
  PatternPainter(this.block) {
    // Bound painting work by thumbnail resolution, even for very wide circuits.
    final scale = min(50 / block.cols, 44 / block.rows);
    _pixels = {
      for (final (x, y) in block.liveCells)
        ((x * scale).floor(), (y * scale).floor()),
    };
  }
  final Block block;
  late final Set<(int, int)> _pixels;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(50 / block.cols, 44 / block.rows);
    final offset = Offset(
      (size.width - block.cols * scale) / 2,
      (size.height - block.rows * scale) / 2,
    );
    final paint = Paint()..color = _accent;
    for (final (x, y) in _pixels) {
      canvas.drawRect(
        Rect.fromLTWH(
          offset.dx + x,
          offset.dy + y,
          max(1, scale * .85),
          max(1, scale * .85),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) => oldDelegate.block != block;
}
