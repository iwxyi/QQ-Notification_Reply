import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/pages/accountwidget.dart';
import 'package:qqnotificationreply/pages/notification_widget.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

import '../widgets/gallerybar.dart';

const Color _mariner = const Color(0xFF3B5F8F);
const Color _mediumPurple = const Color(0xFF8266D4);
const Color _tomato = const Color(0xFFF95B57);
const Color _mySin = const Color(0xFFF3A646);

List<CardSection> allSections;

class MainPages extends StatefulWidget {
  MainPages() {
    allSections = <CardSection>[
      CardSection(
        title: '账号信息',
        leftColor: _mediumPurple,
        rightColor: _mariner,
        contentWidget: AccountWidget(),
      ),
      CardSection(
          title: '通知设置',
          leftColor: _mariner,
          rightColor: _mySin,
          contentWidget: NotificationWidget()),
      CardSection(
          title: '数据记录',
          leftColor: _mySin,
          rightColor: _tomato,
          contentWidget: Center(child: Text('Page Three'))),
      CardSection(
          title: '辅助功能',
          leftColor: _tomato,
          rightColor: Colors.blue,
          contentWidget: Center(child: Text('Page Four'))),
      CardSection(
          title: '关于程序',
          leftColor: Colors.blue,
          rightColor: _mediumPurple,
          contentWidget: Center(child: Text('Page Five'))),
    ];
  }

  @override
  _MainPagesState createState() => _MainPagesState();
}

class _MainPagesState extends State<MainPages> {
  var eventBusFn;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.message) {
        messageReceived(event.data);
      }
    });

    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings();
    var initSettings = new InitializationSettings(android, iOS);
    flutterLocalNotificationsPlugin.initialize(initSettings,
        onSelectNotification: onSelectNotification);
  }

  @override
  Widget build(BuildContext context) {
    return AnimateTabNavigation(
      sectionList: allSections,
    );
  }

  /// 所有msg都会到这里来
  void messageReceived(MsgBean msg) {
    // 保存msg
    G.ac.allMessages.add(msg);
    
    // 显示通知
    if (msg.isPrivate()) {
      if (!msg.isFile()) {
        // 私聊消息
      } else {
        // 私聊文件
      }
    } else if (msg.isGroup()) {
      if (!msg.isFile()) {
        // 群聊消息
        showPlatNotification(msg.groupName + "-" + msg.nickname, msg.message, msg.messageId.toString());
      } else {
        // 群聊文件
      }
    }
  }

  void showPlatNotification(
      String title, String content, String payload) async {
    var android = new AndroidNotificationDetails(
        'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
        priority: Priority.High, importance: Importance.Max);
    var iOS = new IOSNotificationDetails();
    var platform = new NotificationDetails(android, iOS);
    await flutterLocalNotificationsPlugin.show(0, title, content, platform,
        payload: payload);
  }

  /// 菜单点击回调
  Future onSelectNotification(String payload) {
    print('通知.payload: $payload');
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text('Notification'),
              content: new Text('$payload'),
            ));
  }
}
