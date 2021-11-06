import 'dart:io';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qqnotificationreply/pages/main_pages.dart';

import 'global/g.dart';
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
    AwesomeNotifications().initialize(
        // set the icon to null if you want to use the default app icon
        'resource://drawable/notification_icon',
        [
          NotificationChannel(
              channelKey: 'app_notification',
              channelName: '程序通知',
              channelDescription: '程序通知',
              defaultColor: Color(0xFF9D50DD),
              ledColor: Colors.white),
          NotificationChannel(
              channelKey: 'notices',
              channelName: '交互通知',
              channelDescription: '交互通知',
              defaultColor: Color(0xFF9D50DD),
              ledColor: Colors.white),
          NotificationChannel(
              channelKey: 'private_chats',
              channelName: '私聊通知',
              channelDescription: '好友私聊通知',
              defaultColor: Color(0xFF9D50DD),
              ledColor: Colors.white),
          NotificationChannel(
              channelKey: 'normal_group_chats',
              channelName: '普通群组通知',
              channelDescription: '普通群组通知',
              defaultColor: Color(0xFF9D50DD),
              ledColor: Colors.white),
          NotificationChannel(
              channelKey: 'important_group_chats',
              channelName: '重要群组通知',
              channelDescription: '重要群组通知',
              defaultColor: Color(0xFF9D50DD),
              ledColor: Colors.white),
        ]);

    // 开始运行
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QQ通知',
      theme: ThemeData(
        primaryColor: Colors.blue, // 图标颜色
        primarySwatch: Colors.blue, // 标题栏颜色
        visualDensity: VisualDensity.adaptivePlatformDensity, // 设置视觉密度：适应平台密度
        platform: TargetPlatform.iOS, // 页面滑动切换效果
      ),
      home: AppRetainWidget(child: MainPages()),
      scrollBehavior: const MaterialScrollBehavior()
          .copyWith(scrollbars: true, dragDevices: _kTouchLikeDeviceTypes),
    );
  }
}
