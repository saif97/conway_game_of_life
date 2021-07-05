import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


Widget makeTestableWidget({child}) {
  return MaterialApp(home: Builder(builder: (BuildContext context) {
    return Container(child: child);
  }));
}
