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
      create: (_) => ModelBoard(randomly: true)..play(),
      child: _Main(),
    );
  }
}

class _Main extends StatelessWidget {
  const _Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          _Board2(),
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
    final ModelBoard model = Provider.of(context);
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

class _Keyboard_Gesture_InteractiveView extends StatelessWidget {
  final Widget child;

  const _Keyboard_Gesture_InteractiveView({Key? key, required this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context);
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
    final ModelBoard model = Provider.of(context);

    return Container(
      // width: SQUARE_LENGTH * model.numOfColumns,
      width: MediaQuery.of(context).size.width,
      // height: SQUARE_LENGTH * model.numOfRows,
      child: Center(
        child: _Keyboard_Gesture_InteractiveView(
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
    final ModelBoard model = Provider.of(context, listen: false);
    return Expanded(
      child: _Keyboard_Gesture_InteractiveView(
        child: Center(
          child: Container(
            width: model.numOfColumns * SQUARE_LENGTH,
            height: model.numOfRows * SQUARE_LENGTH,
            child: CustomPaint(
              painter: CPainter(context),
            ),
          ),
        ),
      ),
    );
  }
}

class CPainter extends CustomPainter {
  final BuildContext context;

  CPainter(this.context);
  @override
  void paint(Canvas canvas, Size size) {
    final ModelBoard model = Provider.of(context, listen: false);
    for (var eachCol = 0; eachCol < model.numOfColumns; eachCol++) {
      for (var eachRow = 0; eachRow < model.numOfRows; eachRow++) {
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
    // TODO: implement shouldRepaint
    return false;
  }
}
