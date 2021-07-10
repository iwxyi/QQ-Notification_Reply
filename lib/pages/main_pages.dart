import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/pages/accountwidget.dart';
import 'package:qqnotificationreply/pages/notification_widget.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:url_launcher/url_launcher.dart';

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
        showPlatNotification('private_message', '私聊消息', 'QQ私聊消息',
            msg.username(), msg.message, msg.messageId.toString());
      } else {
        // 私聊文件
      }
    } else if (msg.isGroup()) {
      if (!msg.isFile()) {
        // 群聊消息
        showPlatNotification('group_message', '群组消息', 'QQ群组消息', msg.groupName,
            msg.nickname + ' : ' + msg.message, msg.messageId.toString());
      } else {
        // 群聊文件
      }
    }
  }

  /// 显示通知根方法
  /// @param channelId: 是通知分类ID，相同ID会导致覆盖
  /// @param channelName: 是分类名字
  /// @param channelDescription: 是分类点进设置后的底部说明
  /// @param title: 通知标题
  /// @param content: 通知内容
  /// @param payload: 回调的字符串
  void showPlatNotification(
      String channelId,
      String channelName,
      String channelDescription,
      String title,
      String content,
      String payload) async {
    var android = new AndroidNotificationDetails(
        channelId, channelName, channelDescription,
        priority: Priority.High, importance: Importance.Max);
    var iOS = new IOSNotificationDetails();
    var platform = new NotificationDetails(android, iOS);
    await flutterLocalNotificationsPlugin.show(0, title, content, platform,
        payload: payload);
  }

  /// 菜单点击回调
  // ignore: missing_return
  Future onSelectNotification(String payload) async {
    print('通知.payload: $payload');
    MsgBean msg = G.ac.getMsgById(int.parse(payload));

    String url;
    // android 和 ios 的 QQ 启动 url scheme 是不同的
    if (msg.isPrivate()) {
      url = 'mqq://im/chat?chat_type=wpa&uin=' +
          msg.friendId.toString() +
          '&version=1&src_type=web';
      // &web_src=qq.com
    } else {
      url =
          'mqqapi://card/show_pslcard?src_type=internal&version=1&card_type=group&source=qrcode&uin=' +
              msg.groupId.toString();
    }

    // 打开我的资料卡：mqqapi://card/show_pslcard?src_type=internal&source=sharecard&version=1&uin=1600631528

    if (url == null || url.isEmpty) {
      print('没有可打开URL');
      return;
    }

    // 确认一下url是否可启动
    if (await canLaunch(url)) {
      print('打开URL: ' + url);
      await launch(url); // 启动QQ
    } else {
      // 自己封装的一个 Toast
      print('无法启动QQ: ' + url);
      Fluttertoast.showToast(
          msg: "无法启动QQ",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }

    /*showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text(msg.groupName),
              content: new Text(msg.nickname + ' : ' + msg.message),
            ));*/
  }
}
