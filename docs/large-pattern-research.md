# Published large Conway constructions: import research

Researched 2026-10-31 against downloaded upstream files and their original author comments. This is an import recommendation, not a claim that these patterns have been benchmarked or evolved in this Flutter app.

## Recommended additions

Prioritize **OTCA Kok's galaxy, the three-digit hexadecimal counter, the pi calculator, the HashLife-friendly Demonoid, the triple-Snark wick extruder, and c/17 Caterloopillar**. These give the library a complete Life-in-Life demonstration, visible arithmetic circuitry, a computing machine, and several substantial published construction projects. Add Gemini once large-coordinate and alternate macrocell leaf support are tested. Caterpillar is a subsequent performance milestone, not the cheapest first addition.

A genuine compact binary adder is also available, with a fully specified input/output example. It requires mechanical Life 1.05-to-RLE conversion. No hand-invented gate diagrams, random soups, duplicated metacells presented as complete machines, or arbitrary stress patterns are recommended.

### Existing catalog checked

The starting catalog has 37 entries. Existing IDs are: block, beehive, loaf, boat, tub, eater-gallery, blinker, toad, beacon, pulsar, pentadecathlon, oscillator-gallery, glider, lwss, mwss, hwss, corderships, r-pentomino, diehard, acorn, rabbits, lidka, blom, gosper-gun, puffer-train, line-puffer, rakes, period-52-gun, quadratic-growth, spacefiller, lwss-breeder, racetrack, unit-life-cell, ticker, prime-calculator, turing-machine, memory-loop.

In particular, do not duplicate the three-state Turing machine, Fermat-prime construction, Golly ticker, constructor memory loop, or Unit-Life-Cell-512x512. The existing card called “Life inside Life” is **one unit cell**, not a running finite arrangement of simulated Life cells. Source: [current catalog](../assets/patterns/catalog.json) and [library documentation](pattern-library.md).

## Verified files and measured sizes

Dimensions below are **occupied bounding boxes at the downloaded phase**, not macrocell root-square sizes. Macrocell populations and bounds were computed bottom-up from the downloaded DAG, counting repeated child references each time they occur. RLE populations were counted from live runs; the adder was measured by unioning its Life 1.05 coordinate blocks. All listed files were downloaded successfully. Sizes are uncompressed file bytes unless specified otherwise.

| Construction / exact download | Format | Occupied dimensions | Live population | File bytes / macrocell nodes | Import recommendation |
| --- | --- | ---: | ---: | ---: | --- |
| [OTCA Kok's galaxy][galaxy] | `.mc.gz`, M2 | 30,720 × 30,720 | 7,408,195 | 122,585 / 5,536 | Best complete Life-in-Life example; import the DAG directly |
| [Three-digit hexadecimal counter][hex3] | `.mc.gz`, M2 | 9,568 × 6,767 | 328,591 | 666,900 / 33,376 | Strong arithmetic/logic/display example |
| [Pi calculator][pi] | `.mc`, M2 | 117,573 × 155,887 | 1,189,325 | 385,985 / 19,683 | Complete computing construction; direct DAG import |
| [Phi calculator][phi] | `.mc`, M2 | 108,741 × 152,543 | 1,192,719 | 386,318 / 19,701 | Similar to pi; optional second arithmetic program |
| [HashLife-friendly c/512 Demonoid][demonoid] | `.mc.gz`, M2 | 272,449 × 268,312 | 106,639 | 239,445 / 13,854 | Excellent published self-construction example |
| [Triple-Snark wick extruder][snark] | `.rle.gz` | 2,155 × 1,881 | 19,568 | 60,665 | Straightforward RLE addition after offline decompression |
| [c/17 Caterloopillar, author's pinned file][caterloopillar] | `.rle` | 448 × 151,773 | 99,354 | 349,764 | Fits existing sparse RLE limits |
| [Gemini][gemini] | `.mc.gz`, M2, numeric 2×2 leaves | 4,217,807 × 4,220,191 | 846,278 | 1,650,895 / 86,684 | Needs large coordinates and alternate leaf parsing |
| [Caterpillar][caterpillar] | `.mc.gz`, **M1** | 4,195 × 330,721 | 11,967,399 | 8,192,772 / 336,703 | Legacy header and larger source; defer or re-export faithfully |
| [Linear propagator][propagator] | `.mc.gz`, M2 | 14,826,990 × 14,826,908 | 290,096 | 91,482 / 5,085 | Small DAG, very large coordinates; advanced follow-up |
| [Two-digit hexadecimal display][hex2] | `.mc.gz`, M2 | 32,768 × 20,480 | 2,104,670 | 119,433 / 5,782 | Easy compact DAG, but programmed display sequence rather than general computer |
| [Binary adder, member `ADDER.LIF`][henselzip] | ZIP → Life 1.05 | 159 × 246 | 1,425 | Convert mechanically to RLE | Best small published arithmetic demonstration |

The pinned Golly revision used throughout is **`2cf06330cab58dccec085724067e17ddd7a56905`**, matching the existing catalog. Golly's [Very Large Patterns archive][archive] is an official collection separate from that Git checkout; archive URLs are not revision-pinned. Record SHA-256 and preserve author comments when importing from it.

## Behavior, attribution, and suggested setup

### OTCA Kok's galaxy: a complete Life-in-Life arrangement

The [download's author notes][galaxy] explicitly identify an OTCA tiling, a 15 × 15 model bounding box, the B3/S23 simulated rule, and Kok's galaxy, period 8. Credit **Brice Due**, OTCA metapixel, fall 2005–spring 2006; underlying galaxy **Jan Kok, 1971**. The physical rule is also B3/S23. Load the entire published arrangement, including the machinery representing OFF cells; five or eight isolated live tiles do not substitute for a communicating OTCA field.

Upstream recommends HashLife steps **8³–8⁶ = 512–262,144 generations** and explicitly says to allow the cache to warm after changing speed. Start at **4,096** as an app recommendation. One OTCA metageneration is **35,328** underlying generations. Golly's [metafier script][metafier] places cells at **2,048-cell spacing**, and documents an initial 35,328-tick communication/setup cycle for patterns it generates: it is not itself the first ordinary update. Do not promise a state change immediately after that startup cycle. An eight-update galaxy cycle corresponds to 282,624 underlying generations, after accounting for startup/phase.

This is a much better first import than converting the already-present giant `assets/RLE_files/metapixel.rle`: the local file is 15,771,861 bytes, has 6,291,535 live cells, and records `Gen=1110560`, with no provenance comments identifying its arrangement. The local `metatoad.rle` is 2,645,922 bytes and 1,052,566 live cells, already over the original one-million-live-cell cap. Their filenames alone do not establish verified published starting phases.

### Three-digit hexadecimal counter: observable logic and memory

The [file comments][hex3] explain the mechanism in useful detail: a p4600 input passes through two period doublers to p18400; each digit contains four more doublers, memory units, toggle switches, binary-to-hex conversion, and hex-to-seven-segment conversion. Credit **Adam P. Goucher / Calcyman, 2008**. The file is already B3/S23, with no LifeHistory conversion needed.

Upstream recommends **8⁵ = 32,768** generations per step, with 1/32 zoom making the display segments solid. Start by fitting the whole construction, then zoom into the displays or memory units. A smaller **256 or 1,024** jump is an editorial recommendation for inspecting signals; it is not the author's performance recommendation. No manual startup edit is specified.

### Pi and phi calculators: published computation

Both [pi][pi] and [phi][phi] are attributed in their files to **Adam P. Goucher, 2010**. The [official archive description][archive] says they compute and print decimal digits. Their short file comments do not provide a useful clock rate, first-result time, or precise output-region coordinates. Do not invent those facts for catalog tips. Recommend fitting the machine, inspecting the output structures, and **trying 32,768-generation jumps**, clearly an initial app recommendation that still needs benchmarking. Neither file specifies a blocking-glider edit.

The phi file contains **`#G 28853`**. Preserve or explicitly document this saved-generation offset; calling it generation zero is a UI normalization, not the original computation's start. Its embedded prose has `1.6180332...`, an apparent typo; use the name “golden ratio” rather than copying the inaccurate digits into a card.

### HashLife-friendly c/512 Demonoid

[Original comments][demonoid]: **Dave Greene, 10 October 2019**, compiled with **Adam P. Goucher's `slsparse`**. This published variant moves **4,096 cells diagonally per 2²¹ = 2,097,152-generation period**. Credit both the pattern author and compiler contribution; retain its [original discussion link](https://conwaylife.com/forums/viewtopic.php?p=64590#p64590).

Load unchanged. A **32,768** jump is a reasonable initial app recommendation; **2,097,152** lets the user compare complete-cycle positions after warm-up. A smaller jump while zoomed into the active construction arm explains the mechanism. Its file was explicitly compiled to favor HashLife and is a better initial demonstration than assuming every huge construction will run equally well.

### Triple-Snark wick extruder

[Original comments][snark]: **Dave Greene, 21 June 2017**, based on research and search utilities by **Simon Ekstrom and Adam P. Goucher**. Three single-channel arms extend three wicks using copies of a Snark recipe stored as glider streams in a double spiral. Period **262,144** generations. This is a working construction, not just stored constructor memory.

Upstream recommends **8⁴ or 8⁵ = 4,096 or 32,768**, particularly after the first construction cycle, when cached tiles can be reused. Decompress offline and preserve the RLE byte-for-byte. Original [discussion](https://conwaylife.com/forums/viewtopic.php?p=44384#p44377).

### c/17 Caterloopillar

Use [Michael Simkin's pinned original RLE][caterloopillar], revision **`e5f6e44e56093aeb368936e5362a6a9ddce7d454`**. Golly's [annotated copy][caterloopillar-golly] credits **Michael Simkin, 9 April 2016** and explains that each half constructs the other with slow salvos. This is a distinct project from the 2004 Caterpillar.

The author's RLE has no explanatory author header, so preserve the original file and put the credit, date, and [discussion link](https://conwaylife.com/forums/viewtopic.php?p=29796#p29796) in catalog metadata. Both checked versions measure 448 × 151,773 and 99,354 live cells. Golly's URL ends in `.gz` but this research request received **plain RLE bytes beginning `#C`**, so detect gzip magic bytes rather than blindly decompressing by extension.

No startup edit is specified. Initial **256–4,096** jumps are an editorial recommendation, not an upstream benchmark. Fit the entire very tall ship, then zoom into its ends. The inspected files establish speed c/17 but do not state the complete internal repeat period; do not derive that period from the speed alone.

### Gemini

[File comments][gemini]: **Andrew D. Wade, 2 May 2010**, based on construction-arm designs by **Paul Chapman and Dave Greene**. Two active replicator bodies reflect the instruction tape between opposite corners; construction and destruction move the entire spaceship. This is the complete spaceship, unlike the catalog's constructor memory loop.

Displacement **(5,120, 1,024)** in **33,699,586** generations. No manual startup edit specified. Begin at **32,768 or 65,536** as an editorial recommendation, then zoom into a corner to see construction. The underlying period is an exact target, not a claim the app can run it instantly.

Crucial importer detail: although the header says **`#R B3/S23`**, this download uses **numeric level-1 leaves**, e.g. `1 0 0 0 1`, rather than raster 8×8 leaves. Every leaf state in the checked file is 0 or 1. An importer accepting only raster leaves will reject this perfectly usable B3/S23 snapshot. Add explicit binary numeric-leaf support or losslessly re-export through Golly; do not accept arbitrary multistate files as Conway.

### Caterpillar

[Official archive][archive] credits **Gabriel Nivasch, Jason Summers, and David Bell** and gives **17c/45**, period **270**, displacement **102 cells upward**. The [actual downloaded macrocell][caterpillar] has a legacy **`[M1] (hlife 0.95)`** header and no author/rule comments. Its tree uses raster leaves and child-first node records; the measured population is 11,967,399.

For inspection, **16–64** generations per jump is an editorial recommendation. **270** is the exact phase comparison interval; power-of-two-only controls will need several jumps or an exact-generation command to hit it. Import requires intentionally supporting this M1 layout or documenting a faithful Golly M2 re-export. The decompressed source exceeds 8 MB, so a 4 MB text cap is insufficient even though it is only about 3 MB over the network. First benchmark UI responsiveness, loading, and tree rendering; do not flatten its population into twelve million coordinate objects.

### Linear propagator and two-digit hexadecimal display

[Linear propagator][propagator], credited to **Dave Greene** by the [official archive][archive], is a complete phase-shifted replicator. The parent returns to its original state after **237,228,340**, and the child exactly matches it after **237,228,617**. The child takes over replication and blocks further parent copies. The file recommends **2¹⁵–2²¹** jumps and gives milestones: first semi-Snark at roughly 2–4.5 million, main constructor body at 8.9–26.78 million, start of COPY at 118,614,170. It is only 5,085 macrocell nodes but spans almost fifteen million cells in each dimension.

[Two-digit hexadecimal][hex2]: **Brice Due, 9 March 2007**, movie reduced to 128 bits by **Dave Greene**. The file says the tile base period is **35,328**, first pixel updates start just before generation **6,000**, and recommends **8⁴ or 8⁵** steps. This version counts by hexadecimal 10 up to D0 first. Present it as the author's programmed display/counter sequence, not a general-purpose computer.

### Compact binary adder: verified input and expected output

The Golly-linked [Alan Hensel collection index][hensel] points to [lifep.zip][henselzip]. Member **`ADDER.LIF`** is a Life 1.05 file whose original header credits **David Buckingham**, with size optimization by **Mark Niemiec, 1975** (the file misspells the surname “Niemec”). The included glider inputs are **1110 + 0011**, and the documented output is **10001**, emerging at the middle right after approximately **1,000 generations**. Inputs and output are least-significant-bit first. No user wiring is necessary for this shipped example.

Decode each `#P x y` block into coordinates, union the live cells, translate the bounding box, and encode ordinary B3/S23 RLE. Preserve every `#D` author/explanation line as `#C`, and record the archive URL and member name. The measured result should be **159 × 246, population 1,425**. Try **16–64** jumps and inspect the output around generation 1,000. This is an established arithmetic circuit and should be labeled “Binary adder,” not an isolated AND/OR gate.

Standalone AND/OR/NOT gate truth-table examples remain a research gap: `conwaylife.com/patterns/logicaland.rle` returned HTTP 403, and its content was not verified. Do not fabricate a file or infer correctness from a plausible filename. The verified adder and hexadecimal counter provide real arithmetic, memory and switching behavior immediately. Existing pseudorandom-generator circuits were deliberately not promoted because the user rejects random-looking stress demonstrations.

## Other candidates and exclusions

- [OTCA p216 gun][p216]: physically **B3/S23**, but simulates **B35/S236**. Credit OTCA designer **Brice Due** and modeled gun **David Eppstein, 13 June 1998**. Measured 290,816 × 243,712, population **128,116,349**, 142,427 uncompressed bytes, 6,458 nodes. Complete published metapattern, suitable only when clearly labeled “another cellular automaton simulated in Life.” Upstream recommends 512–262,144 jumps.
- [OTCA parity64][parity]: physically **B3/S23**, simulates **B135/S135 with a von Neumann neighborhood**, including boundary feedback. Credit **Brice Due**. Measured 131,072 × 131,072, population **100,491,984**, 123,496 bytes, 5,572 nodes. Again a complete metapattern, but not B3/S23 at the simulated level. Same upstream jump guidance.
- [Unit-Life-Deep-Cell][deep]: **Jared James Prince**, modification of **David Bell's** unit cell. RLE 499 × 516, population 5,449. It interleaves two independent simulated universes at times n×7680 and n×7680+3840. Still **one isolated metacell**, not a complete recursive universe. Do not present it as satisfying the complete Life-in-Life request.
- [Spartan Universal Computer/Constructor ZIP][ucc]: verified archive with `spartan-ucc.mc`, `manual.txt`, `schematic.txt`, `multiply.txt`, `ucc-readme.txt`, and diagram. Credit **Adam P. Goucher, 7 June 2009**. Eleven registers, three binary tapes, eight gates, 64 microinstructions, 148 states. However the pattern is **LifeHistory**, with real multistate numeric leaves. It is not a direct binary Conway import. The README describes activation by one glider entering from below, and a supplied sample loop taking **over 200 million generations** to write repeating `110`. The multiplication program is a separate text program, not already loaded into a verified multiplication demo. Defer until a documented LifeHistory-to-Life conversion and setup have been verified; merely changing the rule label is incorrect.
- [0E0P metaglider](https://golly.sourceforge.net/patterns/0e0p-metaglider.mc.gz): the official archive describes **Adam P. Goucher's** complete five-cell self-constructing metaglider at c/1,048,576. This is a compelling later target. **Archive entry verified, binary file not downloaded or measured in this research**; listed compressed size 7.88 MB. Do not invent dimensions/population or claim readiness.
- Golly's `fangtian-*` and `fangtian2-*` metacell examples have physical rule **B3-jknr4ity5ijk6i8/S23-a4city6c7c**, not Conway B3/S23. Exclude them even where the simulated pattern looks like Life.

## Import implications and validation handoff

The initial [RLE parser](../lib/core/rle_pattern.dart) limits source length to 4,000,000 characters, dimensions to 1,000,000, and population to 1,000,000. These recommendations describe import requirements; see [pattern-library.md](pattern-library.md) for the implemented subset.

1. Keep **macrocell DAGs compressed through load, worker transfer, bounds calculation, population calculation, previews, and rendering**. Expanding a seven-million-cell OTCA file discards its main advantage. Compute bounds with node memoization plus child offsets.
2. Follow Golly's pinned [macrocell format documentation][formats]: child-first numbering, zero as empty at the required level, children in NW/NE/SW/SE order, final node as root. Validate references and level relationships. Binary raster leaves are 8×8 with `.`, `*`, `$`; numeric leaves require separate handling. Gemini proves rule name alone does not predict leaf encoding.
3. Treat absent `#R` deliberately: the verified pi/phi/hexadecimal archive files omit it. They are published as Conway Life; an importer may accept a documented Conway default for this curated path. Do not silently coerce an explicit other rule. Preserve `#G` as metadata or explain normalization.
4. Separate compressed-download size from decompressed-source size; detect gzip by content. Extend sync tooling for `.mc`, offline gzip decoding, and ZIP-member extraction only where needed. The current synchronizer assumes RLE headers.
5. Verify imported population and occupied bounds against this document, then run a small real evolution check and a useful longer jump on selected examples. The research verified structure and provenance, **not dynamical behavior or app performance**. For three-digit counter, pi, Gemini and OTCA, check that fitting/previewing never enumerates all live cells.
6. Preserve the existing Golly attribution/license notice for files from that distribution. Retain original authors and comments for archive downloads. The checked external Hensel and Caterloopillar files did not establish a fresh blanket license grant; do not claim that the app's MIT license relicenses these third-party patterns.

### Reproducibility hashes

SHA-256 below applies to the **decompressed exact bytes**, except the author's already-uncompressed Caterloopillar RLE. Golly archive entries can move; pin the checked bytes in the repository's import metadata.

```text
metapixel-galaxy.mc                    38441e70174212436e83b540a77ea626be2215e0cc9754808047c472b120b06c
hex-3digit-7seg.mc                     938e3b324e1e29c852b37165b2bedbfd9e8a60f4c1367bfd704a82e4b8dad6c5
pi.mc                                 ba2baf318cbbddb07ab0a172040339803cd60dfce8ddd7d93a22bf1c3d88e967
phi.mc                                67a9c02a50bd2deb7457f6dc5bfcc53a3e4e3181947546223b42f49461a52b76
demonoid-c512-hashlife-friendly.mc      a3337f2287db9f4d3404657b0ed9d164f033bac3937e3d1ab4ace9d5fcefc11b
triple-Snark-wick-extruder.rle          33a9f8e60f584f15a30d3827dbdf99e8db42f815bab437c5b0b3ed778f8ddcc9
Caterloopillar_c17.rle                 5d2573bc0463e3601b2863a49a4089b0cf59e6a59edfe65b7a79dfad2067ee76
gemini.mc                             fe94b20efbb7a202abeb72dc1d840d8c30613bfe3da617baeafde385bde32ebd
caterpillar.mc                        85dec928d81810bcfa81af6f5f5eb62035326e2feb657426143c714eb5b0ba12
linear-propagator-p237228340.mc        09e0c9359e1089505676e7558a7e86a77d65b81162a2e92ca5b7e28d7080dea3
```

## Exact source links

[archive]: https://golly.sourceforge.net/patterns/golly-access.html
[galaxy]: https://raw.githubusercontent.com/AlephAlpha/golly/2cf06330cab58dccec085724067e17ddd7a56905/Patterns/HashLife/Metacell/metapixel-galaxy.mc.gz
[metafier]: https://github.com/AlephAlpha/golly/blob/2cf06330cab58dccec085724067e17ddd7a56905/Scripts/Python/metafier.py
[hex3]: https://golly.sourceforge.net/patterns/hex-3digit-7seg.mc.gz
[pi]: https://golly.sourceforge.io/patterns/pi.mc
[phi]: https://golly.sourceforge.io/patterns/phi.mc
[demonoid]: https://raw.githubusercontent.com/AlephAlpha/golly/2cf06330cab58dccec085724067e17ddd7a56905/Patterns/HashLife/Constructions/demonoid-c512-hashlife-friendly.mc.gz
[snark]: https://raw.githubusercontent.com/AlephAlpha/golly/2cf06330cab58dccec085724067e17ddd7a56905/Patterns/HashLife/Constructions/triple-Snark-wick-extruder.rle.gz
[caterloopillar]: https://raw.githubusercontent.com/simsim314/Caterloopilar/e5f6e44e56093aeb368936e5362a6a9ddce7d454/Caterloopillar_c17.rle
[caterloopillar-golly]: https://golly.sourceforge.net/patterns/caterloopillar-c17.rle.gz
[gemini]: https://golly.sourceforge.net/patterns/gemini.mc.gz
[caterpillar]: https://golly.sourceforge.net/patterns/caterpillar.mc.gz
[propagator]: https://raw.githubusercontent.com/AlephAlpha/golly/2cf06330cab58dccec085724067e17ddd7a56905/Patterns/HashLife/Constructions/linear-propagator-p237228340.mc.gz
[hex2]: https://raw.githubusercontent.com/AlephAlpha/golly/2cf06330cab58dccec085724067e17ddd7a56905/Patterns/HashLife/Metacell/hexadecimal.mc.gz
[hensel]: https://golly.sourceforge.io/hensel.html
[henselzip]: https://www.ibiblio.org/lifepatterns/lifep.zip
[p216]: https://raw.githubusercontent.com/AlephAlpha/golly/2cf06330cab58dccec085724067e17ddd7a56905/Patterns/HashLife/Metacell/metapixel-p216-gun.mc.gz
[parity]: https://raw.githubusercontent.com/AlephAlpha/golly/2cf06330cab58dccec085724067e17ddd7a56905/Patterns/HashLife/Metacell/metapixel-parity64.mc.gz
[deep]: https://raw.githubusercontent.com/AlephAlpha/golly/2cf06330cab58dccec085724067e17ddd7a56905/Patterns/Life/Signal-Circuitry/Unit-Life-Deep-Cell.rle
[ucc]: https://golly.sourceforge.net/patterns/spartan-ucc.zip
[formats]: https://github.com/AlephAlpha/golly/blob/2cf06330cab58dccec085724067e17ddd7a56905/Help/formats.html#L159
