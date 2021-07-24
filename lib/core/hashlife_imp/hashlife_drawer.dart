// This is a rewrite from java implementation by Cyprien Mangin & Corentim Wallez. Source:  https://github.com/Kangz/java-conway.
import 'package:conway_game_of_life/core/models/cell.dart';
import 'package:flutter/material.dart';

import 'hash_life_state.dart';
import 'life_algo.dart';
import 'macrocell.dart';

/// An implementation of the interface LifeDrawer for the Hashlife algorithm.
class HashlifeDrawer implements LifeDrawer {
  @override
  void draw(int x, int y, int zoom, LifeState state, Canvas b, Size canvasSize) {
    MacroCell cell = (state as HashlifeState).state;
    int realSize = cell.size;
    if (zoom < 0)
      realSize >>= -zoom;
    else
      realSize <<= zoom;

    x -= realSize / 2;
    y -= realSize / 2;

    // Graphics g = b.getGraphics();
    _recDraw(b, canvasSize, x, y, zoom, cell);
  }

  /// Draws a MacroCell recursively quadrant by quadrant
  ///
  /// @param image      the image to draw onto
  /// @param g          a Graphics object associated with the image
  /// @param x          x coordinate of the drawn posiion of the origin
  /// @param y          x coordinate of the drawn posiion of the origin
  /// @param zoom       the zoom of the current view
  /// @param cellToDraw the cell to draw
  void _recDraw(Canvas canvas, Size canvasSize, int x, int y, int zoom, MacroCell cellToDraw) {
    // Compute the screenspace size of the cell
    int size = cellToDraw.size;
    int realSize = size;
    if (zoom < 0) {
      realSize >>= -zoom;
    } else {
      realSize <<= zoom;
    }

    // do not draw cells outside of the screen
    int w = canvasSize.width, h = canvasSize.height;
    if (x + realSize <= 0 || x >= w || y + realSize <= 0 || y >= h) {
      return;
    }

    if (cellToDraw.off) {
      return;
    }

    // fill a rectangle for BooleanCells
    if (cellToDraw.dim == 0) {
      // g.setColor(Colors.white);
      // g.fillRect(x, y, 1 << zoom, 1 << zoom);
      return;
    }

    // do draw a pixel for non-empty 1-pixel large cells
    if (cellToDraw.dim <= -zoom) {
      canvas.drawRect(Cell.getRect(x, y), Paint()..color = Colors.blueAccent);
      return;
    }

    // Make the recursive call
    int offset = realSize / 2;
    _recDraw(canvas, canvasSize, x, y, zoom, cellToDraw.getQuad(0));
    _recDraw(canvas, canvasSize, x + offset, y, zoom, cellToDraw.getQuad(1));
    _recDraw(canvas, canvasSize, x, y + offset, zoom, cellToDraw.getQuad(2));
    _recDraw(canvas, canvasSize, x + offset, y + offset, zoom, cellToDraw.getQuad(3));
  }
}
