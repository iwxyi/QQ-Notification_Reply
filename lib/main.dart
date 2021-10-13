import 'package:flutter/material.dart';
import 'package:qqnotificationreply/pages/main_pages.dart';

import 'global/g.dart';

void main() {
  /*G.init().then((e) {
    runApp(MyApp());
  });*/
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
