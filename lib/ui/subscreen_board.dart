import 'dart:collection';

import 'package:conway_game_of_life/core/dart_extensions.dart';
import 'package:conway_game_of_life/core/models/cell.dart';
import 'package:conway_game_of_life/core/utils.dart';
import 'package:conway_game_of_life/core/view_model/model_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
          TextButton(onPressed: () => model.initBoard(randomly: true), child: const Text("Randomize")),
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
          // TextButton(onPressed: model.saveBlock, child: const Text("Save Block")),
          Container(width: 20),
          const CheckboxSuperSpeed(),
          Container(width: 20),
          // const _Stats(),
        ],
      ),
    );
  }
}

class CheckboxSuperSpeed extends StatelessWidget {
  const CheckboxSuperSpeed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context, listen: true);
    return SizedBox(
      width: 150,
      child: CheckboxListTile(
        title: const Text("Toggle Super Speed"),
        value: model.isSuperSpeed,
        onChanged: (value) => model.toggleSuperSpeed = value!,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context, listen: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text("Population:      ${model.stats[0]}"),
        Text("GoL rules calls: ${model.stats[1]}"),
        Text("Node hash size:     ${model.stats[2]}"),
        Text("result hash size:     ${model.stats[3]}"),
      ],
    );
  }
}

class SetBoardSize extends StatelessWidget {
  const SetBoardSize({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context, listen: true);

    return Column(
      children: [
        Row(
          children: [
            OutlinedButton(
              onPressed: () => model.setUniverseSizeExponent(model.universeExponent - 1),
              child: const Text('-'),
            ),
            Container(width: 15),
            Text(model.universeExponent.toString()),
            Container(width: 15),
            OutlinedButton(
              onPressed: () => model.setUniverseSizeExponent(model.universeExponent + 1),
              child: const Text('+'),
            ),
          ],
        ),
        Text("${model.universeLength} x ${model.universeLength}"),
      ],
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: const <Widget>[
            Text('Click to pan | Esc to exit block insertion mode.'),
          ],
        ),
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
          model.isModKeyPressed = event.isAltPressed;
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
                // const RepaintBoundary(child: WidUniverse()),
                const Align(
                  alignment: Alignment(150, 150),
                  child: _WCellsPrinter(),
                ),
                const _WGridPainter(),
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
    // todo: clean it up!!!!

    return RepaintBoundary(
      child: Selector<ModelBoard, Queue<Rect>>(
        selector: (_, model) => model.queueHashlifeCells,
        // keep simulating even if there's a Repletion. otherwise in case of queue having the same values selector won't trigger.
        shouldRebuild: (previous, next) => true,
        builder: (context, value, child) {
          return CustomPaint(
            size: Size(model.universeLength * SQUARE_LENGTH, model.universeLength * SQUARE_LENGTH),
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
  final Queue<Rect> queueAliveRects;

  const CellsPainter(this.queueAliveRects);

  @override
  void paint(Canvas canvas, Size size) {
    Offset offsetCell;
    for (final rectAlive in queueAliveRects) {
      canvas.drawRect(rectAlive, Paint()..color = Colors.blueAccent);
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
          size: Size(model.universeLength * SQUARE_LENGTH, model.universeLength * SQUARE_LENGTH),
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
          canvas.drawRect(Cell.getRect(eachCol + mousePos.dxInt, eachRow + mousePos.dyInt), Paint()..color = Colors.greenAccent);
        else
          canvas.drawRect(Cell.getRect(eachCol + mousePos.dxInt, eachRow + mousePos.dyInt), Paint()..color = Colors.redAccent);
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
      child: Selector<ModelBoard, int>(
        builder: (context, universeLength, child) => CustomPaint(
          size: Size(model.universeLength * SQUARE_LENGTH, model.universeLength * SQUARE_LENGTH),
          isComplex: true,
          painter: GridPainter(universeLength: universeLength),
        ),
        selector: (_, model) => model.universeLength,
      ),
    );
  }
}

// todo: selector recreates Custom Paint Object instead of custompainter deciding to do so.

class GridPainter extends CustomPainter {
  final int universeLength;

  GridPainter({required this.universeLength});

  @override
  void paint(Canvas canvas, Size size) {
    if (universeLength < (1 << 6)) {
      for (var eachCol = 0; eachCol < universeLength; eachCol++) {
        for (var eachRow = 0; eachRow < universeLength; eachRow++) {
          canvas.drawRect(
            getRect(eachCol, eachRow),
            Paint()
              ..strokeWidth = 1
              ..style = PaintingStyle.stroke,
          );
        }
      }
    } else {
      canvas.drawRect(
        Rect.fromPoints(Offset.zero, OffsetInt.fromInt(universeLength * SQUARE_LENGTH.toInt(), universeLength * SQUARE_LENGTH.toInt())),
        Paint()
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
