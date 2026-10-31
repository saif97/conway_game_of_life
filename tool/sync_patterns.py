#!/usr/bin/env python3
"""Refresh bundled patterns from the pinned sources in catalog.json (Python 3).

RLE files are copied byte-for-byte. Life Lexicon diagrams are mechanically
converted to RLE, with attribution and the source entry recorded in the file.
No network is used by the app itself. Review upstream changes before bundling.
"""
import concurrent.futures
import hashlib
import gzip
import json
from pathlib import Path
import re
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'assets/patterns/catalog.json'


def fetch(url):
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read()


def lexicon_rle(html, entry):
    anchor = re.escape(entry['lexiconAnchor'])
    section = re.search(r'<a name=' + anchor + r'>.*?(?=<p><a name=|\Z)', html, re.S)
    if not section:
        raise ValueError(f"Missing Lexicon entry: {anchor}")
    diagram = re.search(r'<a href="lexpatt:">\s*([.O*\s]+)</a>', section[0])
    if not diagram:
        raise ValueError(f"Missing diagram: {anchor}")
    rows = diagram[1].strip().splitlines()
    rows = [row.strip() for row in rows]
    encoded = []
    for row in rows:
        row = row.replace('O', 'o').replace('*', 'o').replace('.', 'b').rstrip('b')
        encoded.append(''.join((str(len(m[0])) if len(m[0]) > 1 else '') + m[0][0]
                               for m in re.finditer(r'(.)\1*', row)))
    result = (f"#N {entry['name']}\n#C {entry['credit']}\n"
              f"#C Source: {entry['source']}\n"
              '#C Diagram converted to RLE by this project; cell arrangement unchanged.\n'
              '#C https://creativecommons.org/licenses/by-sa/3.0/\n'
              f"x = {max(map(len, rows))}, y = {len(rows)}, rule = B3/S23\n"
              + '$'.join(encoded).rstrip('$') + '!\n')
    return result.encode()


def main():
    catalog = json.loads(CATALOG.read_text())
    urls = sorted({entry['upstream'] for entry in catalog['patterns'] if 'upstream' in entry})
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        sources = dict(zip(urls, pool.map(fetch, urls)))
    # Finish fetching and conversion before changing any assets.
    outputs = []
    for entry in catalog['patterns']:
        data = (sources[entry['upstream']] if 'upstream' in entry
                else (ROOT / entry['asset']).read_bytes())
        if 'lexiconAnchor' in entry:
            data = lexicon_rle(data.decode(), entry)
        if data.startswith(b'\x1f\x8b'):
            data = gzip.decompress(data)
        if not (re.search(rb'^x\s*=\s*\d+', data, re.M) or data.startswith(b'[M2]')):
            raise ValueError(f"Not an RLE or M2 pattern: {entry['id']}")
        entry['sha256'] = hashlib.sha256(data).hexdigest()
        outputs.append((ROOT / entry['asset'], data))
    for path, data in outputs:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    CATALOG.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + '\n')
    print(f'Bundled {len(outputs)} attributed patterns.')


if __name__ == '__main__':
    main()
