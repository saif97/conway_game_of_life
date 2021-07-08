import 'package:conway_game_of_life/core/view_model/model_board.dart';
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
    final ModelBoard model = Provider.of(context, listen: false);
    print('yooo updated');
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
          SetBoardSize(),
        ],
      ),
    );
  }
}

class SetBoardSize extends StatefulWidget {
  SetBoardSize({Key? key}) : super(key: key);

  @override
  _SetBoardSizeState createState() => _SetBoardSizeState();
}

class _SetBoardSizeState extends State<SetBoardSize> {
  final contNumOfCols = TextEditingController();
  final contNumOfRows = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final maxLength = 6;
    final ModelBoard model = Provider.of(context, listen: false);

    if (contNumOfCols.text.isEmpty) contNumOfCols.text = model.numOfColumns.toString();
    if (contNumOfRows.text.isEmpty) contNumOfRows.text = model.numOfRows.toString();

    return Container(
      child: Row(
        children: [
          getTextField(contNumOfCols, 'Columns'),
          Container(width: 15),
          getTextField(contNumOfRows, "Rows"),
          Container(width: 15),
          TextButton(
            child: Text('Set'),
            onPressed: () {
              model.setBoardSize(int.parse(contNumOfCols.text), int.parse(contNumOfRows.text));
            },
          )
        ],
      ),
    );
  }

  Widget getTextField(TextEditingController cont, String label) {
    return Container(
      width: 70,
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
        maxLines: 1,
        keyboardType: TextInputType.number,
        expands: false,
        controller: cont,
      ),
    );
  }

  @override
  void dispose() {
    contNumOfCols.dispose();
    contNumOfRows.dispose();

    super.dispose();
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

class _KeyboardGestureControllers extends StatelessWidget {
  final Widget child;

  const _KeyboardGestureControllers({Key? key, required this.child}) : super(key: key);
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
      child: GestureDetector(
        onPanUpdate: (v) {
          if (model.isModKeyPressed) {
            final int x = v.localPosition.dx ~/ SQUARE_LENGTH;
            final int y = v.localPosition.dy ~/ SQUARE_LENGTH;

            model.setDrawPos(y, x);
          }
        },
        onTapDown: (v) {},
        child: child,
      ),
    );
  }
}

class _Board2 extends StatelessWidget {
  const _Board2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ModelBoard model = Provider.of(context, listen: true);
    return Expanded(
      child: InteractiveViewer(
        maxScale: 10,
        minScale: .1,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        constrained: false,
        child: Center(
          child: _KeyboardGestureControllers(
            child: CustomPaint(
              size: Size(model.numOfColumns * SQUARE_LENGTH, model.numOfRows * SQUARE_LENGTH),
              painter: GridPainter(context),
              foregroundPainter: CellsPainter(model.currentMatrixUniverse),
            ),
          ),
        ),
      ),
    );
  }
}

class CellsPainter extends CustomPainter {
  final List<List<Cell>> matrix;

  CellsPainter(this.matrix);

  @override
  void paint(Canvas canvas, Size size) {
    for (var eachRow in matrix) {
      for (var eachCell in eachRow) {
        if (eachCell.isAlive) canvas.drawRect(eachCell.rect, Paint()..color = Colors.blueAccent);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CellsPainter oldDelegate) {
    return true;
  }
}

class GridPainter extends CustomPainter {
  final BuildContext context;

  GridPainter(this.context);
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
    return false;
  }
}
