import 'dart:collection';

import 'package:conway_game_of_life/core/dart_extensions.dart';
import 'package:conway_game_of_life/core/models/cell.dart';
import 'package:conway_game_of_life/core/view_model/model_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

const double SQUARE_LENGTH = 15;

class SubScreenBoard extends StatelessWidget {
  const SubScreenBoard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const <Widget>[
          _Board(),
          _Settings(),
          _Instructions(),
        ],
      ),
    );
  }
}

class _Settings extends StatelessWidget {
  const _Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context, listen: false);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextButton(onPressed: model.saveState, child: const Text("Save State")),
          TextButton(onPressed: model.restoreState, child: const Text("Restore State")),
          TextButton(onPressed: model.pause, child: const Text("Pause")),
          TextButton(onPressed: model.play, child: const Text("Play")),
          TextButton(
              onPressed: () => model.initBoard(randomly: true), child: const Text("Randomize")),
          TextButton(onPressed: () => model.initBoard(), child: const Text("Clear")),
          Slider(
            value: model.speedMultiplier.toDouble(),
            onChanged: (v) => model.speedMultiplier = v.toInt(),
            divisions: 6,
            max: 3,
            min: -3,
            label: '${model.speedMultiplier}X',
          ),
          const SetBoardSize(),
          TextButton(onPressed: model.saveBlock, child: const Text("Save Block")),
        ],
      ),
    );
  }
}

class SetBoardSize extends StatefulWidget {
  const SetBoardSize({Key? key}) : super(key: key);

  @override
  _SetBoardSizeState createState() => _SetBoardSizeState();
}

class _SetBoardSizeState extends State<SetBoardSize> {
  final contrNumOfCols = TextEditingController();
  final contrNumOfRows = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context, listen: false);

    if (contrNumOfCols.text.isEmpty) contrNumOfCols.text = model.numOfColumns.toString();
    if (contrNumOfRows.text.isEmpty) contrNumOfRows.text = model.numOfRows.toString();

    return Row(
      children: [
        getTextField(contrNumOfCols, 'Columns'),
        Container(width: 15),
        getTextField(contrNumOfRows, "Rows"),
        Container(width: 15),
        TextButton(
          onPressed: () =>
              model.setBoardSize(int.parse(contrNumOfCols.text), int.parse(contrNumOfRows.text)),
          child: const Text('Set'),
        )
      ],
    );
  }

  Widget getTextField(TextEditingController cont, String label) {
    return SizedBox(
      width: 60,
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          // in the case that value is not an int
          return int.tryParse(value ?? '') != null ? null : value;
        },
        decoration:
            InputDecoration(labelText: label, labelStyle: Theme.of(context).textTheme.caption),
        maxLength: 6,
        keyboardType: TextInputType.number,
        controller: cont,
      ),
    );
  }

  @override
  void dispose() {
    contrNumOfCols.dispose();
    contrNumOfRows.dispose();
    super.dispose();
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        children: const <Widget>[
          Text(
              'click to pan. Ctrl/Cmd click or hold to draw or release block. | Only block of size 10 X 10 can be saved. | Esc to cancel.'),
        ],
      ),
    );
  }
}

class _KeyboardGestureControllers extends StatelessWidget {
  final Widget child;

  const _KeyboardGestureControllers({Key? key, required this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context);
    FocusScope.of(context).requestFocus();

    return InteractiveViewer(
      maxScale: 10,
      minScale: .1,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      constrained: false,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKey: (RawKeyEvent event) {
          model.isModKeyPressed = event.isControlPressed;
          if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
            model.disableBlockInsertionMode();
          }
        },
        child: MouseRegion(
          onEnter: (v) {},
          onExit: (v) {},
          onHover: (v) {
            if (model.isModeInsertBlock) {
              final int x = v.localPosition.dx ~/ SQUARE_LENGTH;
              final int y = v.localPosition.dy ~/ SQUARE_LENGTH;
              model.mousePosInBoard = OffsetInt.fromInt(x, y);
            }
          },
          child: model.isModKeyPressed
              ? GestureDetector(
                  onTapUp: (v) {
                    if (model.isModeInsertBlock) {
                      model.confirmBlockInsertion();
                    } else {
                      final int x = v.localPosition.dx ~/ SQUARE_LENGTH;
                      final int y = v.localPosition.dy ~/ SQUARE_LENGTH;
                      model.setDrawPos(OffsetInt.fromInt(x, y));
                    }
                  },
                  onPanUpdate: (v) {
                    final int x = v.localPosition.dx ~/ SQUARE_LENGTH;
                    final int y = v.localPosition.dy ~/ SQUARE_LENGTH;

                    model.setDrawPos(OffsetInt.fromInt(x, y));
                  },
                  onTapDown: (v) {},
                  child: child,
                )
              : child,
        ),
      ),
    );
  }

  void registerClick(int x, int y) {}
}

class _Board extends StatelessWidget {
  const _Board({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _KeyboardGestureControllers(
        child: Center(
          child: Selector<ModelBoard, bool>(
            selector: (_, model) => model.isModeInsertBlock,
            builder: (context, value, child) => Stack(
              children: [
                const _WGridPainter(),
                const _WCellsPrinter(),
                if (value) const _WInsertedBlockPainter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// todo: selector recreates Custom Paint Object instead of custompainter deciding to do so.

class _WCellsPrinter extends StatelessWidget {
  const _WCellsPrinter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context, listen: false);
    return RepaintBoundary(
      child: Selector<ModelBoard, Queue<Cell>>(
        selector: (_, model) => model.queueAliveCells,
        // keep simulating even if there's a Repletion. otherwise in case of queue having the same values selector won't trigger.
        shouldRebuild: (previous, next) => true,
        builder: (context, value, child) {
          return CustomPaint(
            size: Size(model.numOfColumns * SQUARE_LENGTH, model.numOfRows * SQUARE_LENGTH),
            painter: CellsPainter(value),
            isComplex: true,
            willChange: true,
          );
        },
      ),
    );
  }
}

class CellsPainter extends CustomPainter {
  final Queue<Cell> queueAliveCells;

  const CellsPainter(this.queueAliveCells);

  @override
  void paint(Canvas canvas, Size size) {
    for (final cell in queueAliveCells) {
      if (cell.isAlive) canvas.drawRect(cell.rect, Paint()..color = Colors.blueAccent);
    }
  }

  @override
  bool shouldRepaint(covariant CellsPainter oldDelegate) {
    return true;
  }
}

// todo: selector recreates Custom Paint Object instead of custompainter deciding to do so.

class _WInsertedBlockPainter extends StatelessWidget {
  const _WInsertedBlockPainter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context, listen: false);
    return RepaintBoundary(
      child: Selector<ModelBoard, Offset>(
        selector: (_, model) => model.mousePosInBoard,
        builder: (context, value, child) => CustomPaint(
          size: Size(model.numOfColumns * SQUARE_LENGTH, model.numOfRows * SQUARE_LENGTH),
          painter: InsertedBlockPainter(context),
          isComplex: true,
          willChange: true,
        ),
      ),
    );
  }
}

class InsertedBlockPainter extends CustomPainter {
  final BuildContext context;

  const InsertedBlockPainter(this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final ModelBoard model = Provider.of(context, listen: false);
    final block = model.insertedBlock;
    final mousePos = model.mousePosInBoard;

    for (var eachCol = 0; eachCol < block.cols; eachCol++) {
      for (var eachRow = 0; eachRow < block.rows; eachRow++) {
        final eachCellState = block.matrixBlock[eachCol][eachRow];
        if (eachCellState)
          canvas.drawRect(Cell.getRect(eachCol + mousePos.dxInt, eachRow + mousePos.dyInt),
              Paint()..color = Colors.greenAccent);
        else
          canvas.drawRect(Cell.getRect(eachCol + mousePos.dxInt, eachRow + mousePos.dyInt),
              Paint()..color = Colors.redAccent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant InsertedBlockPainter oldDelegate) {
    return true;
  }
}

class _WGridPainter extends StatelessWidget {
  const _WGridPainter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context, listen: false);
    return RepaintBoundary(
      child: Selector<ModelBoard, Tuple2<int, int>>(
        builder: (context, tuple, child) => CustomPaint(
          size: Size(model.numOfColumns * SQUARE_LENGTH, model.numOfRows * SQUARE_LENGTH),
          isComplex: true,
          painter: GridPainter(cols: tuple.item1, rows: tuple.item2),
        ),
        selector: (_, model) => Tuple2(model.numOfColumns, model.numOfRows),
      ),
    );
  }
}

// todo: selector recreates Custom Paint Object instead of custompainter deciding to do so.

class GridPainter extends CustomPainter {
  final int cols, rows;

  const GridPainter({required this.cols, required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    for (var eachCol = 0; eachCol < cols; eachCol++) {
      for (var eachRow = 0; eachRow < rows; eachRow++) {
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
    return true;
  }
}
