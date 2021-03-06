import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/pages/main/main_pages.dart';

import 'global/g.dart';
import 'services/notification_controller.dart';
import 'widgets/app_retain_widget.dart';

const Set<PointerDeviceKind> _kTouchLikeDeviceTypes = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown
};

void main() {
  // Unhandled Exception: Null check operator used on a null value
  WidgetsFlutterBinding.ensureInitialized(); // 解决加载json错误

  G.init().then((e) {
    // 初始化通知
    NotificationController.initializeNotificationsPlugin();

    // 开始运行
//    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    runApp(MyApp());

    /*if (Platform.isAndroid) {
      //设置Android头部的导航栏透明
      SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, //全局设置透明
          statusBarIconBrightness: Brightness.dark //light:黑色图标 dark：白色图标
          );
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }*/
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QQ通知',
      theme: ThemeData(
        primaryColor: Colors.blue,
        // 图标颜色
        primarySwatch: Colors.blue,
        // 标题栏颜色
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // 设置视觉密度：适应平台密度
        platform: TargetPlatform.iOS, // 左侧右滑返回效果
      ),
      home: AppRetainWidget(child: MainPages()),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
        dragDevices: _kTouchLikeDeviceTypes, // 支持鼠标手势
      ),
    );
  }
}
