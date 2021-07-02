import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'size-config.dart';

Widget makeTestableWidget({child}) {
  return MaterialApp(home: Builder(builder: (BuildContext context) {
    SizeConfig.init(context);
    return Container(child: child);
  }));
}
