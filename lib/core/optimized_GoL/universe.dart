import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:conway_game_of_life/core/utils.dart';
import 'package:conway_game_of_life/ui/subscreen_board.dart';
import 'package:flutter/material.dart';

class WidUniverse extends StatefulWidget {
  const WidUniverse({Key? key}) : super(key: key);

  @override
  _WidUniverseState createState() => _WidUniverseState();
}

class _WidUniverseState extends State<WidUniverse> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(100 * SQUARE_LENGTH, 100 * SQUARE_LENGTH),
      isComplex: true,
      willChange: true,
      // painter: Universe(cols: 100, rows: 100)..randomizeUniverse(),
    );
  }
}

class CellsPainter extends CustomPainter {
  final Queue<int> queueAliveCells;

  const CellsPainter(this.queueAliveCells);

  @override
  void paint(Canvas canvas, Size size) {
    for (final cell in queueAliveCells) {
      // canvas.drawRect(getRect(col, row), Paint()..color = Colors.blueAccent);
    }
  }

  @override
  bool shouldRepaint(covariant CellsPainter oldDelegate) {
    return true;
  }
}

class Universe {
  List<Uint8List> universe;
  late List<Uint8List> tempUniverse;
  final int rows, cols;

  Universe({required this.rows, required this.cols})
      : universe = List.generate(rows, (_) => Uint8List(cols)),
        tempUniverse = List.generate(rows, (_) => Uint8List(cols));

  @override
  void paint(Canvas canvas, Size size) {
    // todo: make it non blocking call.
    drawNextGen(canvas);

    // for (var eachRow = 0; eachRow < rows; eachRow++) {
    // for (var eachCol = 0; eachCol < cols; eachCol++) {
    // if (_isCellAlive(col: eachCol, row: eachRow)) _drawCell(canvas, eachCol, eachRow);
    // }
    // }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }

  void randomizeUniverse() {
    final randomNumberGenerator = Random();
    for (var eachRow = 0; eachRow < rows; eachRow++) {
      for (var eachCol = 0; eachCol < cols; eachCol++) {
        if (randomNumberGenerator.nextBool()) _setCellAlive(x: eachCol, y: eachRow);
      }
    }
  }

  void drawNextGen(Canvas canvas) {
    // print('hola');
    // deep copy universe.
    for (var eachRow = 0; eachRow < rows; eachRow++) {
      for (var eachCol = 0; eachCol < cols; eachCol++) {
        tempUniverse[eachRow][eachCol] = universe[eachRow][eachCol];
      }
    }
    for (var eachRow = 0; eachRow < rows; eachRow++) {
      for (var eachCol = 0; eachCol < cols; eachCol++) {
        final cell = tempUniverse[eachRow][eachCol];
        // if 0 then that means the cell is dead & has no alive Neighbors.
        if (cell == 0) continue;

        // shift 1 bit to right to get rid of the bit that is reserved for life status of the cell.
        final numAliveNeighbours = cell >> 1;
        // check if cell is alive
        if (cell & 0x01 == 0x01) {
          // if the cell alive a has less than 2 alive cells then kill it.
          if ((numAliveNeighbours != 2) && (numAliveNeighbours != 3))
            _setCellDied(x: eachCol, y: eachRow);
          else
            // the cell will stay alive in the next generation.
            _drawCell(canvas, eachCol, eachRow);
        } else {
          // cell is not alive but has 3 neighbour thus will be alive in the next generation.
          if (numAliveNeighbours == 3) {
            _setCellAlive(x: eachCol, y: eachRow);
            _drawCell(canvas, eachCol, eachRow);
          }
        }
      }
    }
  }

  void _drawCell(Canvas canvas, int col, int row) {
    canvas.drawRect(getRect(col, row), Paint()..color = Colors.blueAccent);
  }

  // todo: migrate from x,y to row, col
  void _setCellAlive({required final int x, required final int y}) {
    late final int xLeft, xRight, yAbove, yBelow;
    // todo:if what we want to set it to is same as the actual value, ignore it.

    if (_isCellAlive(col: x, row: y)) return;

    // to make the cell alive, or it w/ 0000,0001 since the first bit indicates is the cell alive or not.
    universe[y][x] |= 0x01;

    // Calculate the number of alive cells surrounding this cell.
    //
    // This method uses packman like borders. where if a cell is at the edge, it'll look up the Neighbors on the other side of the edge.
    // check if we're at the edges so we don't get index out of  bound errors.
    // NOTE: those are relative (offset) they're not the Absolute location in the universe.
    if (x == 0) {
      xLeft = cols - 1;
    } else {
      xLeft = -1;
    }

    // if x is at the very right edge of the universe, use the cells on the left start of the universe.
    if (x == (cols - 1))
      xRight = -(cols - 1);
    else
      xRight = 1;

    if (y == 0)
      yAbove = rows - 1;
    else
      yAbove = -1;

    if (y == (cols - 1))
      yBelow = -(rows - 1);
    else
      yBelow = 1;

    universe[x + xLeft][y + yAbove] += 0x02; //  upper left
    universe[x][y + yAbove] += 0x02; //          up
    universe[x + xRight][y + yAbove] += 0x02; // up right
    universe[x + xLeft][y] += 0x02; //           left mid
    universe[x + xRight][y] += 0x02; //          right mid
    universe[x + xLeft][y + yBelow] += 0x02; //  down left
    universe[x][y + yBelow] += 0x02; //          down mid
    universe[x + xRight][y + yBelow] += 0x02; // down right
  }

  // todo: migrate from x,y to row, col
  void _setCellDied({required final int x, required final int y}) {
    late final int xLeft, xRight, yAbove, yBelow;
    // todo:if what we want to set it to is same as the actual value, ignore it.
    int cell = universe[y][x];

    if (!_isCellAlive(col: x, row: y)) return;

    // to make the cell alive, or it w/ 0000,0001 since the first bit indicates is the cell alive or not.
    cell &= ~0x01;

    // Calculate the number of alive cells surrounding this cell.
    //
    // This method uses packman like borders. where if a cell is at the edge, it'll look up the Neighbors on the other side of the edge.
    // check if we're at the edges so we don't get index out of  bound errors.
    // NOTE: those are relative (offset) they're not the Absolute location in the universe.
    if (x == 0) {
      xLeft = cols - 1;
    } else {
      xLeft = -1;
    }

    // if x is at the very right edge of the universe, use the cells on the left start of the universe.
    if (x == (cols - 1))
      xRight = -(cols - 1);
    else
      xRight = 1;

    if (y == 0)
      yAbove = rows - 1;
    else
      yAbove = -1;

    if (y == (cols - 1))
      yBelow = -(rows - 1);
    else
      yBelow = 1;

    universe[x + xLeft][y + yAbove] -= 0x02; //  upper left
    universe[x][y + yAbove] -= 0x02; //          up
    universe[x + xRight][y + yAbove] -= 0x02; // up right
    universe[x + xLeft][y] -= 0x02; //           left mid
    universe[x + xRight][y] -= 0x02; //          right mid
    universe[x + xLeft][y + yBelow] -= 0x02; //  down left
    universe[x][y + yBelow] -= 0x02; //          down mid
    universe[x + xRight][y + yBelow] -= 0x02; // down right
  }

  bool _isCellAlive({required final int col, required final int row}) => universe[row][col] & 0x01 == 0x01;
}
