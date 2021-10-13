import 'package:flutter/material.dart';
import 'package:qqnotificationreply/pages/main_pages.dart';

import 'global/g.dart';

void main() {
  G.init().then((e) {
    runApp(MyApp());
  });
  // runApp(MyApp());
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
        home: MainPages());
  }
}
