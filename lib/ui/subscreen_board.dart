import 'package:conway_game_of_life/core/view_model/board_model.dart';
import 'package:conway_game_of_life/src/cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

const double SQUARE_LENGTH = 15;

class SubScreenBoard extends StatelessWidget {
  const SubScreenBoard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BoardModel(randomly: true)..play(),
      child: _Main(),
    );
  }
}

class _Main extends StatelessWidget {
  const _Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(child: Center(child: _Board2())),
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
    final BoardModel model = Provider.of(context);
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextButton(
            child: Text("Reset"),
            onPressed: model.reset,
          ),
          TextButton(
            child: Text("Pause"),
            onPressed: model.pause,
          ),
          TextButton(
            child: Text("Play"),
            onPressed: model.play,
          ),
          TextButton(
            child: Text("Randomize"),
            onPressed: model.randomize,
          ),
          Slider(
            value: model.speedMultiplier.toDouble(),
            onChanged: (v) => model.speedMultiplier = v.toInt(),
            divisions: 6,
            max: 3,
            min: -3,
            label: model.speedMultiplier.toString() + 'X',
          ),
        ],
      ),
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        children: <Widget>[
          Text('Ctrl/Cmd click hold to draw.'),
        ],
      ),
    );
  }
}

class _Keyboard_Gesture extends StatelessWidget {
  final Widget child;

  const _Keyboard_Gesture({Key? key, required this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final BoardModel model = Provider.of(context);
    FocusScope.of(context).requestFocus();
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (RawKeyEvent event) async {
        model.isModKeyPressed = event.isControlPressed;
      },
      child: InteractiveViewer(
        child: GestureDetector(
          onPanUpdate: (v) {
            if (model.isModKeyPressed) {
              final int x = v.localPosition.dx ~/ SQUARE_LENGTH;
              final int y = v.localPosition.dy ~/ SQUARE_LENGTH;

              model.setDrawPos(x, y);
            }
          },
          onTapDown: (v) {},
          child: child,
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BoardModel model = Provider.of(context);

    return Container(
      // width: SQUARE_LENGTH * model.numOfColumns,
      width: MediaQuery.of(context).size.width,
      // height: SQUARE_LENGTH * model.numOfRows,
      child: Center(
        child: _Keyboard_Gesture(
          child: Column(
            children: [
              // Container(height: 15), // padding above.
              ...List.generate(
                  model.numOfColumns,
                  (col) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            model.numOfRows,
                            (row) =>
                                this._buildCell(context, model.currentMatrixUniverse[col][row])),
                      ))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, Cell cell) {
    return Container(
      width: SQUARE_LENGTH,
      height: SQUARE_LENGTH,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 0.5),
        color: cell.isAlive ? Colors.blue : Colors.white,
      ),
    );
  }
}

class _Board2 extends StatelessWidget {
  const _Board2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CustomPaint(
        painter: CPainter(),
      ),
    );
  }
}

class CPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    for (var eachCol = 0; eachCol < 50; eachCol++) {
      for (var eachRow = 0; eachRow < 50; eachRow++) {
        final upperLeft = Offset(eachCol.toDouble(), eachRow.toDouble()) * SQUARE_LENGTH;
        final lowerRight = Offset(eachCol.toDouble() + 1, eachRow.toDouble() + 1) * SQUARE_LENGTH;
        canvas.drawRect(
          Rect.fromPoints(upperLeft, lowerRight),
          Paint()
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    throw UnimplementedError();
  }
}
