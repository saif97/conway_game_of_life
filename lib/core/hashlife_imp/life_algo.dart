import 'package:flutter/material.dart';

/// An interface for every life algorithm.
abstract class LifeAlgo {
  /// Set the current state to another LifeState.
  ///
  /// @param state the new state of the algorithm
  void setState(LifeState state);

  /// @return the current LifeState of the algorithm
  LifeState getState();

  /// @return a new LifeDrawer
  LifeDrawer getDrawer();

  /// Load the state of the algorithm from an array.
  ///
  /// @param array the int array to load
  void loadFromArray(List<List<int>> array);

  /// Save the current state to an array.
  /// @return an int array representing the current state
  List<List<int>> saveToArray();

  /// Get the state of the cell at given coordinates,
  /// starting at (0,0) in the top-left corner.<br />
  /// 0 = off<br />
  /// 1 = on<br />
  /// @param x the line of the cell
  /// @param y the column of the cell
  /// @return
  int getCellAt(int x, int y);

  /// Set the state of the cell at the given coordinates,
  /// starting at (0,0) in the top-left corner.
  ///
  /// @param x the line of the cell
  /// @param y the column of the cell
  /// @param status the new value of the cell
  void setCellAt(int x, int y, int status);

  /// Invert the state of the cell at the given coordinates,
  /// starting at (0,0) in the top-left corner.
  ///
  /// @param x the line of the cell
  /// @param y the column of the cell
  int toggleCellAt(int x, int y);

  /// Make the state evolves for a given number of steps.
  ///
  /// @param steps the number of steps to compute
  void evolve(int steps);
}

/// A generic interface to represent the state of a LifeAlgo.
abstract class LifeState {}

/// An interface for a drawer, capable to draw a LifeState.
abstract class LifeDrawer {
  /// Draw a LifeState at a given position, with a certain zoom,
  /// in a given BufferedImage.
  ///
  /// @param x x-coordinate of the origin of the drawing
  /// @param y y-coordinate of the origin of the drawing
  /// @param zoom size (in power of 2) of a single cell
  /// @param state the current state to be drawn
  /// @param b the image to draw onto
  void draw(int x, int y, int zoom, LifeState state,Canvas b, Size canvasSize);
}
