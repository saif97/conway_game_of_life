# Pattern sources and attribution

The cell arrangements in this directory come from the Golly distribution,
including Stephen Silver's Life Lexicon. They were downloaded from the
[AlephAlpha/golly mirror](https://github.com/AlephAlpha/golly) at revision
`2cf06330cab58dccec085724067e17ddd7a56905`.

`catalog.json` records each original URL and the SHA-256 of its bundled RLE.
Golly RLE files are copied unchanged, including original author/discoverer
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
