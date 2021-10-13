import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/pages/main_pages.dart';

import 'global/g.dart';

void main() {
  /*G.init().then((e) {
    runApp(MyApp());
  });*/
  _setTargetPlatformForDesktop();
  runApp(MyApp());
}

void _setTargetPlatformForDesktop() {
  TargetPlatform targetPlatform;
  if (Platform.isMacOS) {
    targetPlatform = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    targetPlatform = TargetPlatform.android;
  }
  if (targetPlatform != null) {
    debugDefaultTargetPlatformOverride = targetPlatform;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QQ通知',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder(
        future: G.init(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.data == null) {
            return Center(
              child: Text("加载中"),
            );
          }
          return MainPages();
        },
      ),
    );
  }
}
