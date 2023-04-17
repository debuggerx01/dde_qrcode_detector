import 'package:flutter/material.dart';
import 'package:zbar_scan_plugin/zbar_scan_plugin.dart';
import 'package:collection/collection.dart';
import 'dart:math';

class CenterAndSize {
  final Offset center;
  final double size;

  CenterAndSize({
    required this.center,
    required this.size,
  });
}

CenterAndSize getCenterAndSizeOfPoints(List<PointInfo> points) {
  if (points.isEmpty) {
    return CenterAndSize(
      center: Offset.zero,
      size: 0,
    );
  }
  var center = Offset(
    points.map((p) => p.x).average,
    points.map((p) => p.y).average,
  );

  var size = sqrt(
    pow(points.first.x - center.dx, 2) + pow(points.first.y - center.dy, 2),
  );
  return CenterAndSize(
    center: center,
    size: size * 1.2,
  );

}
