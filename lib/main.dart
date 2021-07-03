import 'package:flutter/material.dart';
import 'package:qqnotificationreply/page/mainpages.dart';

import 'global/g.dart';

void main() {
  runApp(MyApp());
}
//  G.init().then((e) {
//    runApp(MyApp());
//  });
//}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPages(),
    );
  }
}