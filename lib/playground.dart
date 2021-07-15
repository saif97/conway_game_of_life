import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'core/models/cell.dart';

class ScreenPlayGround extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayGround'),
      ),
      body: Column(
        children: const [
          _Main(),
          RepaintBoundary(child: _WCellsPrinter()),
        ],
      ),
    );
  }
}

class _Main extends StatelessWidget {
  const _Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: Sky(),
      child: const Center(
        child: Text(
          'Once upon a time...',
          style: TextStyle(
            fontSize: 40.0,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}

class Sky extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    print('sky');
    final Rect rect = Offset.zero & size;
    const RadialGradient gradient = RadialGradient(
      center: Alignment(0.7, -0.6),
      radius: 0.2,
      colors: <Color>[Color(0xFFFFFF00), Color(0xFF0099FF)],
      stops: <double>[0.4, 1.0],
    );
    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
      // Annotate a rectangle containing the picture of the sun
      // with the label "Sun". When text to speech feature is enabled on the
      // device, a user will be able to locate the sun on this picture by
      // touch.
      Rect rect = Offset.zero & size;
      final double width = size.shortestSide * 0.4;
      rect = const Alignment(0.8, -0.9).inscribe(Size(width, width), rect);
      return <CustomPainterSemantics>[
        CustomPainterSemantics(
          rect: rect,
          properties: const SemanticsProperties(
            label: 'Sun',
            textDirection: TextDirection.ltr,
          ),
        ),
      ];
    };
  }

  // Since this Sky painter has no fields, it always paints
  // the same thing and semantics information is the same.
  // Therefore we return false here. If we had fields (set
  // from the constructor) then we would return true if any
  // of them differed from the same fields on the oldDelegate.
  @override
  bool shouldRepaint(Sky oldDelegate) => false;
  @override
  bool shouldRebuildSemantics(Sky oldDelegate) => false;
}

class TestW extends StatelessWidget {
  const TestW({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('logo updated');
    return Container(
      child: _WGridPainter(),
    );
  }
}

class _WGridPainter extends StatelessWidget {
  const _WGridPainter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final ModelBoard model = Provider.of(context, listen: false);
    return const CustomPaint(
      isComplex: true,
      painter: GridPainter(cols: 100, rows: 100),
    );
  }
}

//todo: rows X cols calls every frame isn't scalable
class GridPainter extends CustomPainter {
  final int cols, rows;

  const GridPainter({required this.cols, required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    print('grid');
    int i = 0;
    for (var eachCol = 0; eachCol < cols; eachCol++) {
      for (var eachRow = 0; eachRow < rows; eachRow++) {
        i++;
        canvas.drawRect(
          Cell.getRect(eachCol, eachRow),
          Paint()
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _WCellsPrinter extends StatefulWidget {
  const _WCellsPrinter({Key? key}) : super(key: key);

  @override
  __WCellsPrinterState createState() => __WCellsPrinterState();
}

class __WCellsPrinterState extends State<_WCellsPrinter> {
  final int _numOfColumns = 100;
  final int _numOfRows = 100;
  late Timer _timer;
  final int _speedMultiplier = 0;
  // final Queue<Cell> queueAliveCells = Queue();
  late List<List<Cell>> _currentMatrixUniverse;
  late List<List<Cell>> _initialMatrixUniverse;

  @override
  void initState() {
    initBoard();
    play();
    super.initState();
  }

  void initBoard({bool randomly = false}) {
    final randomNumberGenerator = Random();
    _initialMatrixUniverse = List.generate(
      _numOfColumns,
      (eachCol) => List.generate(
        _numOfRows,
        (eachRow) {
          final bool isAlive = randomly && randomNumberGenerator.nextBool();
          final newCell = Cell(isAlive, upperLeftX: eachCol, upperLeftY: eachRow);
          // if (isAlive) queueAliveCells.add(newCell);
          return newCell;
        },
      ),
    );
    _currentMatrixUniverse = _initialMatrixUniverse;
  }

  void play() {
    final updateRate = 50 + (_speedMultiplier * 10);
    _timer = Timer.periodic(Duration(milliseconds: updateRate), (timer) {
      updateCells();
    });
  }

  void updateCells() {
    final List<List<Cell>> updatedCells = List<List<Cell>>.of(_currentMatrixUniverse.map((e) => e
        .map<Cell>((e) => Cell(e.isAlive, upperLeftX: e.upperLeftX, upperLeftY: e.upperLeftY))
        .toList()));

    for (int col = 0; col < _numOfColumns; col++) {
      for (int row = 0; row < _numOfRows; row++) {
        final int aliveNeighbors = _getAliveNeighbors(col, row);
        final bool isCurrentCellAlive = _currentMatrixUniverse[col][row].isAlive;

        if (!isCurrentCellAlive && aliveNeighbors == 3) {
          updatedCells[col][row].revive();
        } else if (isCurrentCellAlive && aliveNeighbors != 2 && aliveNeighbors != 3) {
          updatedCells[col][row].die();
        }
      }
    }

    setState(() {
      _currentMatrixUniverse = updatedCells;
    });
  }

// todo: refactor this
  int _getAliveNeighbors(int col, int row) {
    int aliveNeighbours = 0;
    for (int rowSummand = -1; rowSummand <= 1; rowSummand++) {
      for (int colSummand = -1; colSummand <= 1; colSummand++) {
        final neighbourCellRow = row + rowSummand;
        final neighbourCellColumn = col + colSummand;
        final bool isOutOfRange = neighbourCellRow < 0 ||
            neighbourCellRow > (_numOfRows - 1) ||
            neighbourCellColumn < 0 ||
            neighbourCellColumn > (_numOfColumns - 1);
        final bool isNeighbourCell = rowSummand != 0 || colSummand != 0;

        if (!isOutOfRange &&
            isNeighbourCell &&
            _currentMatrixUniverse[neighbourCellColumn][neighbourCellRow].isAlive) {
          aliveNeighbours++;
        }
      }
    }

    return aliveNeighbours;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CellsPainter(_currentMatrixUniverse),
      isComplex: true,
      willChange: true,
    );
  }
}

class CellsPainter extends CustomPainter {
  final List<List<Cell>> matrix;

  const CellsPainter(this.matrix);

  @override
  void paint(Canvas canvas, Size size) {
    print('cell');
    for (final eachRow in matrix) {
      for (final eachCell in eachRow) {
        if (eachCell.isAlive) canvas.drawRect(eachCell.rect, Paint()..color = Colors.blueAccent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CellsPainter oldDelegate) {
    return true;
  }
}
