import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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

setSentryScope(Scope scope) {
  var infoLines = File('/etc/os-release').readAsStringSync().split('\n').where((line) => line.contains('='));
  Map<String, dynamic> data = {};
  for (var info in infoLines) {
    var parts = info.split('=');
    data['OS_${parts.first}'] = parts.sublist(1).join('=');
  }
  return scope.setUser(
    SentryUser(
      id: File('/etc/machine-id').readAsStringSync(),
      username: Platform.environment['USER'],
      data: data,
    ),
  );
}
