import 'package:flutter/material.dart';

import 'src/board.dart';
import 'src/utils/size-config.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameOfLife(),
    );
  }
}

class GameOfLife extends StatelessWidget {
  static final _boardStateKey = GlobalKey<BoardState>();
  final Board _board = Board(key: _boardStateKey, rows: 50, columns: 50);

  _reset() {
    // reset if the state is present
    _boardStateKey.currentState?.resetCells();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Game of Life"),
      ),
      body: Column(
        children: <Widget>[
          this._board,
          TextButton(
            child: Text("Reset"),
            onPressed: this._reset,
          )
        ],
      ),
    );
  }
}
