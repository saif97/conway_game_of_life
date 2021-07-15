import 'package:conway_game_of_life/playground.dart';
import 'package:flutter/material.dart';

import 'ui/screen_home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScreenHome(),
      // home: ScreenPlayGround(),
    );
  }
}
