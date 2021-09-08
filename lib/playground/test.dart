import 'dart:isolate';

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Isolate isolate;

  late ReceivePort receivePort;

  @override
  void initState() {
    super.initState();

    spawnNewIsolate();
  }

  Future spawnNewIsolate() async {
    receivePort = ReceivePort();

    try {
      isolate = await Isolate.spawn(sayHello, receivePort.sendPort);

      print("Isolate: $isolate");

      receivePort.listen((dynamic message) {
        print('New message from Isolate: $message');
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  //spawn accepts only static methods or top-level functions

  static void sayHello(SendPort sendPort) {
    sendPort.send("Hello from Isolate");
  }

  @override
  void dispose() {
    super.dispose();

    receivePort.close();

    isolate.kill();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Isolate Demo"),
      ),
      body: Center(),
    );
  }
}
