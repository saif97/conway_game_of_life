import 'package:conway_game_of_life/core/models/cell.dart';
import 'package:conway_game_of_life/core/view_model/model_board.dart';
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
      child: const _Main(),
    );
  }
}

class _Main extends StatelessWidget {
  const _Main({Key? key}) : super(key: key);

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        TextButton(
          onPressed: model.reset,
          child: const Text("Reset"),
        ),
        TextButton(
          onPressed: model.pause,
          child: const Text("Pause"),
        ),
        TextButton(
          onPressed: model.play,
          child: const Text("Play"),
        ),
        TextButton(
          onPressed: model.randomize,
          child: const Text("Randomize"),
        ),
        Slider(
          value: model.speedMultiplier.toDouble(),
          onChanged: (v) => model.speedMultiplier = v.toInt(),
          divisions: 6,
          max: 3,
          min: -3,
          label: '${model.speedMultiplier}X',
        ),
        const SetBoardSize(),
      ],
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
          Text('click to pan. Ctrl/Cmd click or hold to draw.'),
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

class _Board extends StatelessWidget {
  const _Board({Key? key}) : super(key: key);

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
              painter: GridPainter(cols: model.numOfColumns, rows: model.numOfRows),
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

class GridPainter extends CustomPainter {
  final int cols, rows;

  GridPainter({required this.cols, required this.rows});

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
    return false;
  }
}
