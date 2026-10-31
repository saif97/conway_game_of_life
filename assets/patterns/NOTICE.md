# Pattern sources and attribution

The cell arrangements in this directory come from the Golly distribution and
its official Very Large Patterns archive,
including Stephen Silver's Life Lexicon. Most were downloaded from the
[AlephAlpha/golly mirror](https://github.com/AlephAlpha/golly) at revision
`2cf06330cab58dccec085724067e17ddd7a56905`.

`catalog.json` records each original URL and the SHA-256 of its bundled RLE or macrocell file.
Golly files are copied unchanged (after gzip decompression for `.gz` sources), including original author/discoverer
comments and any trailing documentation. See [Golly's license](GOLLY-LICENSE.html)
for the upstream distribution's licensing notice (GNU GPL v2 or later).
These third-party assets are not relicensed under the application's MIT notice.

The small patterns extracted from Life Lexicon diagrams are credited to
Stephen Silver, Dave Greene and the contributors acknowledged in the
[original introduction and copying notice](LIFE-LEXICON-NOTICE.html).
Life Lexicon is copyright Stephen Silver, 1997–2018, distributed under
[Creative Commons Attribution-ShareAlike 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/).
The extracted diagrams retain that license. This project's only modification
to these diagrams is mechanical conversion from text diagrams to RLE;
cell arrangements are unchanged. Each converted file includes its source
entry and attribution. Catalog descriptions and usage tips are written for
this application.

To reproduce the downloads and conversions, run `python3 tool/sync_patterns.py`
from the repository root. No scraping or remote downloads occur in the app.

OTCA metapixel galaxy and p216 gun tilings credit Brice Due (2005–2006),
with model patterns by Jan Kok and David Eppstein respectively. The underlying
rule is Conway B3/S23 in both files; the p216 tiling simulates B35/S236.
The HashLife-friendly Demonoid credits Dave Greene (10 October 2019), compiled
with Adam P. Goucher’s `slsparse`. Full original notes remain in each `.mc` file.

The three-digit hexadecimal counter (Adam P. Goucher / Calcyman, 2008) and
pi calculator (Adam P. Goucher, 2010) come from Golly’s official
[Very Large Patterns archive](https://golly.sourceforge.net/patterns/golly-access.html).
Their original comments are preserved; `catalog.json` pins the downloaded
content by SHA-256. These archive URLs are not revision-pinned Git sources.
