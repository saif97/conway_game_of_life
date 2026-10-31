# Pattern library

The library bundles 42 patterns in six expandable families: still lifes,
oscillators, spaceships, long-lived seeds, guns/puffers/breeders, and large
constructions. Families progress from introductory examples to complex
experiments. Within each family, Explore order follows the catalog's curated
sequence; Name A–Z sorts alphabetically. Search matches every word across
names, descriptions, tips, and family names, automatically showing matches
inside collapsed families. Clearing search restores the expanded families.

Cards show a preview, bounding dimensions, live population, and description.
Load world (or clicking the card) replaces the world and fits the camera.
The largest constructions also select a useful initial generation jump.
For RLE patterns, Place pauses playback and prepares insertion into the current world; Escape
cancels. The info button shows an experiment tip, attribution and a selectable
source URL. The same library appears in the mobile drawer.

## Sources

Patterns are downloaded from a pinned revision of the Golly collection,
its bundled Life Lexicon, and Golly’s official Very Large Patterns archive.
Archive downloads are recorded by content hash. See
[the pattern attribution notice](../assets/patterns/NOTICE.md).
Original Golly RLE and M2 macrocell files retain their author notes byte-for-byte
(after gzip decompression where applicable); small Lexicon
diagrams are mechanically converted to RLE with credit and a source entry.
The app works offline after its assets have loaded and never queries an
external pattern site at runtime.

Large examples include the Golly ticker, an LWSS breeder, a Turing machine,
a Life metacell, and a constructor memory loop spanning 31,473 × 31,101 cells.
Published macrocell worlds include Brice Due’s OTCA metapixel galaxy: a
complete Kok’s galaxy simulated inside Conway Life, with 7,408,195 initial live
cells. The OTCA p216 gun uses Conway circuitry to simulate **B35/S236** at the
metacell level. The Demonoid is Dave Greene’s published HashLife-friendly
self-constructing spaceship, compiled with Adam P. Goucher’s tooling. Adam P. Goucher’s three-digit hexadecimal counter and pi calculator add
working switching, memory and computation. Their
original files, author notes and download hashes are preserved. The older
512 × 512 Unit Life cell is labeled as a component, not a complete meta-world.

Macrocell constructions load as complete worlds; Place is available for the
smaller RLE patterns. Their card dimensions describe the enclosing quadtree,
including surrounding empty space. Previews aggregate the tree at thumbnail
resolution, and worker messages carry the compressed source rather than a list
of millions of cells. Save/Restore and generation jumps work as usual.

Some constructions require setup: the Turing machine's original notes describe
removing a blocking glider to start the program. The card's info panel calls
this out. Generation jumps and Fit world help explore large patterns.

## Add a pattern

1. Put a Conway `.rle` or two-state M2 `.mc` file in `assets/patterns/`, preserving its attribution.
2. Add a record to `assets/patterns/catalog.json`: `id` (unique), `name`,
   `group` (an existing group ID), `description`, `tip`, `asset` (full asset
   path), `source` (original page URL), and `credit`. Its position within the
   family defines Explore order. An optional `jumpExponent` (0–20) selects
   a starting jump of 2^exponent generations when loaded. Add a group record to create a new family.
3. Run `flutter test test/core/pattern_catalog_test.dart` to validate the whole
   catalog, including loading its coordinates into HashLife. Rebuild the app
   to include changed Flutter assets.

For reproducible upstream downloads, also record `upstream` (a raw URL pinned
to a revision), then run `python3 tool/sync_patterns.py`. The script downloads
RLE/M2 files unchanged (decompressing `.gz` sources) and records their SHA-256. To extract a Life Lexicon
pattern, use a pinned Lexicon HTML URL plus `lexiconAnchor`; the first diagram
in that entry is converted. Review the resulting pattern and preserve the
applicable attribution/license notice. Hand-bundled patterns can omit `upstream` and are left unchanged.

No Dart code changes are needed to add catalog entries. `saved_blocks.dart`
contains only the small synchronous startup/benchmark fixtures, not the UI
catalog. Assets are loaded and cached on demand when cards become visible;
failed loads offer Retry. Preview painting aggregates live cells into a small
thumbnail so wide sparse circuits do not require scanning their empty area.

## RLE support

`parseRlePattern` decodes two-state Conway RLE directly into live coordinates.
It supports comments, `#N` names, CXRLE comment annotations, wrapped bodies,
run counts, skipped rows, optional rules, a final row separator, and author
notes on lines after the `!` terminator. Conway rule spellings `B3/S23`,
`S23/B3`, and `23/3` are accepted. CXRLE position/generation annotations are
ignored: each selection starts a local pattern at generation zero.

Bounds, tokens, run lengths and population are checked before loading.
Limits are 4 million source characters, one million cells per dimension,
and one million live cells. Other rules, bounded universes, multistate RLE,
and Life 1.05/1.06 files are not supported by the RLE parser. Existing matrix-based
`parseRLE`/`readRLE` callers retain a one-million-square-cell area limit.
Large patterns use the sparse API throughout loading, placement and previews.

## Macrocell support

Golly’s two-state M2 format is decoded directly into shared quadtrees. Only
Conway B3/S23 is accepted as the underlying rule; multi-state formats are
rejected. Limits are 4 million source characters, 100,000 node records,
a root depth of 30, and population within JavaScript’s exact integer range.
Child references and depths are validated before replacing the world. Like RLE
entries, imported positions are local and generation starts at zero; file
origin/generation annotations are not restored. Repeated subtrees remain shared
through loading, preview, worker transfer and simulation.

File import is not exposed yet. A future importer can use this same sparse
parser; bundled discovery is the current focus. The older unattributed metapixel RLE exports under `assets/RLE_files/`
remain outside the curated library; the new worlds use pinned upstream files.
