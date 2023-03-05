import 'package:flutter/material.dart';

class SubBlock {
  late int x;
  late int y;
  late Color color;
  SubBlock(this.x, this.y, [Color color = Colors.transparent]) {
    // ignore: prefer_initializing_formals
    this.color = color;
  }
}
