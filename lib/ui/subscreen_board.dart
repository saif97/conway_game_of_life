import 'package:conway_game_of_life/core/view_model/board_model.dart';
import 'package:conway_game_of_life/src/cell.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubScreenBoard extends StatelessWidget {
  const SubScreenBoard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BoardModel(rows: 50, columns: 50)
        ..initBoardRandomly()
        ..play(),
      child: _Main(),
    );
  }
}

class _Main extends StatelessWidget {
  const _Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BoardModel model = Provider.of(context);
    return Container(
      child: Column(
        children: <Widget>[
          _Board(),
          Row(
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
                onPressed: model.initBoardRandomly,
              ),
              Slider(
                value: model.speedMultiplier.toDouble(),
                onChanged: (v) {
                  model.speedMultiplier = v.toInt();
                },
                divisions: 6,
                max: 3,
                min: -3,
                label: model.speedMultiplier.toString() + 'X',
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BoardModel model = Provider.of(context);
    return Column(
        children: List.generate(
            model.columns,
            (col) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(model.rows,
                      (row) => this._buildCell(context, model.currentMatrixUniverse[col][row])),
                )));
  }

  Widget _buildCell(BuildContext context, Cell cell) {
    final double squareLength = 15;
    return Container(
      width: squareLength,
      height: squareLength,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 0.5),
        color: cell.isAlive ? Colors.blue : Colors.white,
      ),
    );
  }
}
