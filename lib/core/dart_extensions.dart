import 'package:flutter/material.dart';

extension OffsetInt on Offset {
  static Offset fromInt(int x, int y) => Offset(x.toDouble(), y.toDouble());

  int get dxInt => dx.toInt();
  int get dyInt => dy.toInt();
}
