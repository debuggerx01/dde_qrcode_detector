import 'dart:io';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zbar_scan_plugin/zbar_scan_plugin.dart' as ZBar;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    center: true,
    skipTaskbar: true,
    fullScreen: true,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    backgroundColor: Colors.transparent,
    alwaysOnTop: true,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await Window.initialize();
    Window.setEffect(
      effect: WindowEffect.transparent,
      color: Colors.transparent,
    );
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum Status {
  standBy,
  scan,
  found,
  notFound,
}

class _MyHomePageState extends State<MyHomePage> {
  Offset currentWindowPos = Offset.zero;
  Status status = Status.standBy;
  List<ZBar.CodeInfo> codes = [];

  @override
  void initState() {
    HardwareKeyboard.instance.addHandler((event) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        exit(0);
      }
      return false;
    });
    WindowManager.instance.getPosition().then((pos) {
      currentWindowPos = pos;
    });
    WindowManager.instance.focus();
    WindowManager.instance.grabKeyboard();
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        status = Status.scan;
      });
      compute(scan, null).then((codes) {
        setState(() {
          codes = codes;
          status = codes.isEmpty ? Status.notFound : Status.found;
        });
      });
    });
    super.initState();
  }

  static Future<List<ZBar.CodeInfo>> scan(dynamic _) async {
    var imagePath = '/tmp/${DateTime.now().toIso8601String()}.png';
    Process.runSync('scrot', [imagePath]);
    return ZBar.scan(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    late Rect rect;
    if (pos != null) {
      rect = Rect.fromPoints(
        Offset(pos!.bottomLeft.x, pos!.bottomLeft.y),
        Offset(pos!.topRight.x, pos!.topRight.y),
      );
      rect = rect.translate(-currentWindowPos.dx, -currentWindowPos.dy);
    }
    return GestureDetector(
      onTap: () {
        if ([Status.found, Status.notFound].contains(status)) {
          exit(0);
        }
      },
      child: Scaffold(
        backgroundColor: status == Status.standBy
            ? Colors.transparent
            : Colors.black12.withOpacity(
                status == Status.scan ? 0.4 : 0.2,
              ),
        body: Stack(
          children: [
            if (status == Status.scan)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.grey.shade700.withOpacity(0.9),
                  ),
                  child: RepaintBoundary(
                    child: Image.asset(
                      'assets/doubt.gif',
                      width: 200,
                      height: 200,
                    ),
                  ),
                ),
              ),
            if (status == Status.found)
              Positioned(
                left: rect.left - rect.width / 2,
                top: rect.top - rect.height / 2,
                child: Container(
                  width: rect.width * 2,
                  height: rect.height * 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      max(rect.width, rect.height),
                    ),
                    color: Colors.black38.withOpacity(.6),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          '二维码内容：',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                        AutoSizeText(
                          content?.text ?? '',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                          ),
                          minFontSize: 16,
                          maxFontSize: 46,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            FilledButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: content?.text),
                                );
                              },
                              child: const Text(
                                '复制',
                                style: TextStyle(fontSize: 28),
                              ),
                            ),
                            FilledButton(
                              onPressed: () async {
                                var url = content?.text ?? '';
                                if (await canLaunchUrlString(url)) {
                                  launchUrlString(url).then((value) {
                                    exit(0);
                                  });
                                }
                              },
                              child: const Text(
                                '打开',
                                style: TextStyle(fontSize: 28),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
