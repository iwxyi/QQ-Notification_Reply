import 'package:flutter/material.dart';
import 'package:qqnotificationreply/pages/main_pages.dart';

import 'global/g.dart';
import 'widgets/app_retain_widget.dart';

void main() {
  // Unhandled Exception: Null check operator used on a null value
  WidgetsFlutterBinding.ensureInitialized(); // 解决加载json错误

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
        home: AppRetainWidget(child: MainPages()));
  }
}
