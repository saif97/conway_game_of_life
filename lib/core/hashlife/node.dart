import 'dart:math';

import 'package:flutter/material.dart';

class Node {
  final Node? nw, ne, sw, se;
  final int depth;
  final bool isAlive;
  final int population;
  final int area;
  Node._({
    this.nw,
    this.ne,
    this.sw,
    this.se,
    required this.area,
    required this.depth,
    required this.isAlive,
    required this.population,
  })  : // make sure that all nodes share the same depth.
        assert((nw?.depth ?? 0) == (ne?.depth ?? 0) && (nw?.depth ?? 0) == (se?.depth ?? 0) && (nw?.depth ?? 0) == (sw?.depth ?? 0),
            "Check if all nodes have the same depth."),
        assert(pow(2, depth) * pow(2, depth) == area);

  //
  // used static methods instead of named constructors so that every node created goes through the same assertions.
  // and reduce redundant assertions.
  static Node fromQuads(Node nw, Node ne, Node sw, Node se) => Node._(
      nw: nw,
      ne: ne,
      sw: sw,
      se: se,
      depth: sw.depth + 1,
      isAlive: true,
      population: sw.population + se.population + nw.population + ne.population,
      area: sw.area + se.area + nw.area + ne.area);

  // ignore: prefer_constructors_over_static_methods
  static Node FromInt(int nw, int ne, int sw, int se) => Node._(
        nw: nw == 0 ? BinaryNode.OFF : BinaryNode.ON,
        ne: ne == 0 ? BinaryNode.OFF : BinaryNode.ON,
        sw: sw == 0 ? BinaryNode.OFF : BinaryNode.ON,
        se: se == 0 ? BinaryNode.OFF : BinaryNode.ON,
        isAlive: true,
        area: 4,
        depth: 1,
        population: (sw == 0 ? 0 : 1) + (se == 0 ? 0 : 1) + (nw == 0 ? 0 : 1) + (ne == 0 ? 0 : 1),
      );

  @override
  bool operator ==(Object other) {
    return other is Node && identical(nw, other.nw) && identical(ne, other.ne) && identical(sw, other.sw) && identical(se, other.se);
  }

  @override
  String toString() {
    if (depth == 0) return (isAlive ? 1 : 0).toString();
    // base case to print a 2x2 grid
    if (depth == 1) {
      return "${nw!.isAlive ? 1 : 0}\t${ne!.isAlive ? 1 : 0}\n\n${sw!.isAlive ? 1 : 0}\t${se!.isAlive ? 1 : 0}\n\n";
    } else {
      return "Cells: ${pow(2, depth)}x${pow(2, depth)} | population: $population ";
      // return "$nw\t$ne\n\n$sw\t$se\t";
    }
  }

  @override
  // TODO: implement hashCode
  int get hashCode => hashValues(identityHashCode(nw), identityHashCode(ne), identityHashCode(sw), identityHashCode(se));

  static final CANONICAL_NODES = [
    Node.FromInt(0, 0, 0, 0),
    Node.FromInt(0, 0, 0, 1),
    Node.FromInt(0, 0, 1, 0),
    Node.FromInt(0, 0, 1, 1),
    Node.FromInt(0, 1, 0, 0),
    Node.FromInt(0, 1, 0, 1),
    Node.FromInt(0, 1, 1, 0),
    Node.FromInt(0, 1, 1, 1),
    Node.FromInt(1, 0, 0, 0),
    Node.FromInt(1, 0, 0, 1),
    Node.FromInt(1, 0, 1, 0),
    Node.FromInt(1, 0, 1, 1),
    Node.FromInt(1, 1, 0, 0),
    Node.FromInt(1, 1, 0, 1),
    Node.FromInt(1, 1, 1, 0),
    Node.FromInt(1, 1, 1, 1),
  ];
}

class BinaryNode extends Node {
  static final ON = BinaryNode._(isAlive: true);
  static final OFF = BinaryNode._(isAlive: false);

  BinaryNode._({required bool isAlive})
      : super._(
          ne: null,
          nw: null,
          se: null,
          sw: null,
          depth: 0,
          isAlive: isAlive,
          population: isAlive ? 1 : 0,
          area: 1,
        );

  int isAliveAsInt() => isAlive ? 1 : 0;

  @override
  String toString() {
    // TODO: implement toString
    return (isAlive ? 1 : 0).toString();
  }
}
