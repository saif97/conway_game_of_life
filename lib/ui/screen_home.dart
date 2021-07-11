import 'package:conway_game_of_life/core/view_model/home_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'subscreen_board.dart';

class ScreenHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Game of Life"),
      ),
      body: ChangeNotifierProvider(
        create: (_) => HomeModel(),
        child: const _Main(),
      ),
    );
  }
}

class _Main extends StatelessWidget {
  const _Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SubScreenBoard();
  }
}
