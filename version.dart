// ignore_for_file: avoid_print

import 'dart:io';

import 'package:yaml/yaml.dart';

void main() async {
  var document = loadYaml(File('pubspec.yaml').readAsStringSync());
  print(document['version'].replaceAll('+', '.'));
}
