import 'rle_pattern.dart';

// Small synchronous starter set for the default world and engine benchmarks.
// The browsable library is declared in assets/patterns/catalog.json.
final listBlocks = [
  parseRlePattern(r'''x = 5, y = 5, rule = B3/S23
2o$2o!''', name: 'Block'),
  parseRlePattern(r'''x = 5, y = 5, rule = B3/S23
$b3o$bo$2bo!''', name: 'Glider'),
  parseRlePattern(r'''x = 7, y = 6, rule = B3/S23
$2bo2bo$bo$bo3bo$b4o!''', name: 'Lightweight spaceship'),
  parseRlePattern(r'''x = 5, y = 5, rule = B3/S23
$2b2o$b2o$2bo!''', name: 'R-pentomino'),
  parseRlePattern(
    r'''x = 32, y = 48, rule = B3/S23
$$$$$$$$$13b3ob3o$12bo2bobo2bo$11bo3bobo3bo$11bo9bo$13bo5bo$10bobo7bobo$9b2obob2ob2obob2o$8bobobob2ob2obobobo$7b2obobobobobobobob2o$6bobobobo7bobobobo$5b2obobo2bo5bo2bobob2o$4bo3bobo11bobo3bo$4bo6bo9bo6bo$6b2obobo9bobob2o$9bo13bo$7bo3bo4bo4bo3bo$11b2ob2ob2ob2o$9b4o7b4o$8b2o3bobobobo3b2o$7bo4bo2bobo2bo4bo$10b3o7b3o$7b2o3bob2ob2obo3b2o$12bo7bo$11bo2b5o2bo$11bobo5bobo$13bo5bo$16bo$11bo4bo4bo$10b2o3bobo3b2o$9bo4bo3bo4bo$15b3o$9b2o3b2ob2o3b2o$8bo15bo$9bo13bo$11b11o$12b9o$11b2o2b3o2b2o$15b3o$15b3o!''',
    name: 'Puffer train',
  ),
  parseRlePattern(
    r'''x = 13, y = 38, rule = B3/S23
$5b2o$5b2o$$$$$$6bo$5b3o$5b3o$$3b2o3b2o$3b2o3b2o$$$5b2o$5bobo$4bo2b2o$6b2o$6b2o$7bo$$bo5bo$bo5bo$2bo3bo$3b3o$$$$$$$$$3b2o$3b2o!''',
    name: 'Glider Gun',
  ),
];
