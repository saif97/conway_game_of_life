import 'dart:io';

/**
 * An utility class to make the link between a RLE file
 * and an integers array.
 */
/**
     * Read a RLE file and convert it into an integers array.
     *
     * @param file the File to write into
     * @return the integers array produced from the file
     */
Future<List<List<bool>>> readRLE(String file) async {
  // read the file

  final File rle_file = File(file);

  if (!(await rle_file.exists())) throw ("File dosen't exsits");

  List<String> lines = await rle_file.readAsLines();

  for (var line in lines) {
    RegExp exp = RegExp("""^x = ([0-9]+), y = ([0-9]+), rule = (.+)\$""");
    Iterable<RegExpMatch> matches = exp.allMatches(line);

    if (matches.isEmpty) throw "No match found";

    print(matches.first);
  }

  return [];
}
