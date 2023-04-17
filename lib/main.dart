import 'dart:io';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dde_qrcode_detector/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zbar_scan_plugin/zbar_scan_plugin.dart' as zbar;

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
  finish,
}

class _MyHomePageState extends State<MyHomePage> {
  Offset currentWindowPos = Offset.zero;
  Status status = Status.standBy;
  List<zbar.CodeInfo> codes = [];

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
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        setState(() {
          status = Status.scan;
        });
      }
      compute(scan, null).then((result) {
        if (context.mounted) {
          setState(() {
            codes = result;
            status = codes.isEmpty ? Status.notFound : Status.found;
          });
        }
        Future.delayed(const Duration(seconds: 3), () {
          if (status == Status.notFound) {
            exit(0);
          }
          if (context.mounted) {
            setState(() {
              status = Status.finish;
            });
          }
        });
      });
    });
    super.initState();
  }

  static Future<List<zbar.CodeInfo>> scan(dynamic _) async {
    var imagePath = '/tmp/${DateTime.now().toIso8601String()}.png';
    Process.runSync('scrot', [imagePath]);
    var result = zbar.scan(imagePath);
    File(imagePath).delete();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if ([
          Status.found,
          Status.notFound,
          Status.finish,
        ].contains(status)) {
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
          fit: StackFit.expand,
          children: [
            if (![Status.standBy, Status.finish].contains(status))
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.grey.shade700.withOpacity(0.9),
                  ),
                  width: 460,
                  height: 360,
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RepaintBoundary(
                          child: Image.asset(
                            {
                              Status.scan: 'assets/doubt.gif',
                              Status.found: 'assets/ok.gif',
                              Status.notFound: 'assets/no.gif',
                            }[status]!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                        Text(
                          {
                            Status.scan: '小浣熊正在努力寻找二维码~',
                            Status.found: '小浣熊成功找到${codes.length}个二维码！',
                            Status.notFound: '小浣熊找了一圈，啥也没发现……',
                          }[status]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ...codes.map(
              (code) {
                var centerAndSize = getCenterAndSizeOfPoints(code.points);
                var center = centerAndSize.center - currentWindowPos;
                var size = max(centerAndSize.size, 300);
                return Positioned(
                  left: center.dx - size / 2,
                  top: center.dy - size / 2,
                  child: Container(
                    width: size.toDouble(),
                    height: size.toDouble(),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size / 2),
                      color: Colors.black38.withOpacity(.6),
                    ),
                    padding: EdgeInsets.all(size / 6),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Flexible(
                            child: AutoSizeText(
                              code.content.split('').join('\u{200B}'),
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                              ),
                              minFontSize: 16,
                              maxFontSize: 46,
                            ),
                          ),
                          SizedBox(height: size / 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              FilledButton(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: code.content),
                                  ).then((_) {
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      exit(0);
                                    });
                                  });
                                },
                                child: const Text(
                                  '复制',
                                  style: TextStyle(fontSize: 28),
                                ),
                              ),
                              SizedBox(width: size / 20),
                              FilledButton(
                                onPressed: () async {
                                  var url = code.content;
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
