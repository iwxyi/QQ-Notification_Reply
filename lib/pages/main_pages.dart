import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/pages/accountwidget.dart';
import 'package:qqnotificationreply/pages/notification_widget.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/gallerybar.dart';

const Color _mariner = const Color(0xFF3B5F8F);
const Color _mediumPurple = const Color(0xFF8266D4);
const Color _tomato = const Color(0xFFF95B57);
const Color _mySin = const Color(0xFFF3A646);

List<CardSection> allSections = <CardSection>[
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

class MainPages extends StatefulWidget {
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

    requireNotificationPermission();

    // 初始化通知
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/appicon');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
            onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    final MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
    UserAccount.flutterLocalNotificationsPlugin =
        flutterLocalNotificationsPlugin;
  }

  @override
  Widget build(BuildContext context) {
    return AnimateTabNavigation(
      sectionList: allSections,
    );
  }

  /// 所有msg都会到这里来
  void messageReceived(MsgBean msg) async {
    G.ac.allMessages.add(msg); // 保存所有 msg 记录
    int id = UserAccount.notificationId(msg); // 该聊天对象的通知ID（每次启动都不一样）
    String displayMessage = _getMessageDisplay(msg);

    // 判断是否需要通知
    if (msg.senderId == G.ac.qqId) {
      // 自己发的，一定不需要再通知了
      // 甚至还需要消除掉自己的通知
      flutterLocalNotificationsPlugin.cancel(id);
      return;
    }
    // TODO: 判断群组通知白名单

    // 显示通知
    if (msg.isPrivate()) {
      /*print('-----------------id private:' +
          msg.friendId.toString() +
          '  ' +
          id.toString());*/

      String uri = 'mqq://im/chat?chat_type=wpa&uin=' +
          msg.friendId.toString() +
          '&version=1&src_type=web';

      Person person = new Person(
          bot: false, important: true, name: msg.username(), uri: uri);

      Message message = new Message(displayMessage, DateTime.now(), person);

      if (!G.ac.privateMessages.containsKey(msg.friendId)) {
        G.ac.privateMessages[msg.friendId] = [];
      }
      G.ac.privateMessages[msg.friendId].add(message);

      if (!msg.isFile()) {
        // 私聊消息
      } else {
        // TODO: 私聊文件
        return;
      }

      MessagingStyleInformation messagingStyleInformation =
          new MessagingStyleInformation(person,
              conversationTitle: msg.username(),
              messages: G.ac.privateMessages[msg.friendId]);

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails('private_message', '私聊消息', 'QQ好友消息/临时会话',
              styleInformation: messagingStyleInformation,
              groupKey: 'chat',
              priority: Priority.high,
              setAsGroupSummary: true,
              importance: Importance.high);

      NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
          id, msg.username(), displayMessage, platformChannelSpecifics,
          payload: msg.messageId.toString());
    } else if (msg.isGroup()) {
      /*print('-----------------id group:' +
          msg.groupId.toString() +
          '  ' +
          id.toString());*/

      String uri = 'mqq://im/chat?chat_type=group&uin=' +
          msg.groupId.toString() +
          '&version=1&src_type=web';

      Person person = new Person(
          bot: false, important: false, name: msg.username(), uri: uri);

      Message message = new Message(displayMessage, DateTime.now(), person);

      if (!G.ac.groupMessages.containsKey(msg.groupId)) {
        G.ac.groupMessages[msg.groupId] = [];
      }
      G.ac.groupMessages[msg.groupId].add(message);

      Person group =
          new Person(bot: true, important: true, name: msg.groupName, uri: uri);

      if (!msg.isFile()) {
        // 群聊消息
      } else {
        // TODO: 群聊文件
        return;
      }

      MessagingStyleInformation messagingStyleInformation =
          new MessagingStyleInformation(group,
              conversationTitle: msg.groupName,
              messages: G.ac.groupMessages[msg.groupId]);

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails('group_message', '群组消息', 'QQ群组消息',
              styleInformation: messagingStyleInformation,
              groupKey: 'chat',
              priority: Priority.high,
              setAsGroupSummary: true,
              importance: Importance.high);

      NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
          id, msg.username(), displayMessage, platformChannelSpecifics,
          payload: msg.messageId.toString());
    }
  }

  /// msg.message CQ文本，转换为显示的内容
  String _getMessageDisplay(MsgBean msg) {
    String text = msg.message;

    text = text.replaceAll(RegExp(r"\[CQ:face,id=(\d+)\]"), '[表情]');
    text = text.replaceAll(RegExp(r"\[CQ:image,type=flash,.+?\]"), '[闪照]');
    text = text.replaceAll(RegExp(r"\[CQ:image,.+?\]"), '[图片]');
    text = text.replaceAll(RegExp(r"\[CQ:reply,.+?\]"), '[回复]');
    text = text.replaceAllMapped(
        RegExp(r"\[CQ:at,qq=(\d+)\]"), (match) => '@${match[1]}');
    text = text.replaceAllMapped(
        RegExp(r'\[CQ:json,data=.+"prompt":"(.+?)".*\]'), (match) => '${match[1]}');
    text = text.replaceAll(RegExp(r"\[CQ:json,.+?\]"), '[卡片]');
    text = text.replaceAll(RegExp(r"\[CQ:video,.+?\]"), '[视频]');
    text = text.replaceAllMapped(
        RegExp(r"\[CQ:([^,]+),.+?\]"), (match) => '@${match[1]}');
    text = text.replaceAll('&#91;', '[').replaceAll('&#93;', ']');

    return text;
  }

  /// 通知点击回调
  // ignore: missing_return
  Future onSelectNotification(String payload) async {
    print('通知.payload: $payload');
    MsgBean msg = G.ac.getMsgById(int.parse(payload));

    String url;
    // android 和 ios 的 QQ 启动 url scheme 是不同的
    if (msg.isPrivate()) {
      G.ac.privateMessages[msg.friendId].clear();
      url = 'mqq://im/chat?chat_type=wpa&uin=' +
          msg.friendId.toString() +
          '&version=1&src_type=web';
      // &web_src=qq.com
    } else {
      G.ac.groupMessages[msg.groupId].clear();
      url = 'mqq://im/chat?chat_type=group&uin=' +
          msg.groupId.toString() +
          '&version=1&src_type=web';
    }

    // 打开我的资料卡：mqqapi://card/show_pslcard?src_type=internal&source=sharecard&version=1&uin=1600631528
    // QQ群资料卡：mqqapi://card/show_pslcard?src_type=internal&version=1&card_type=group&source=qrcode&uin=123456

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
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    }
  }

  /// 这个是 iOS 的通知回调
  // ignore: missing_return
  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) {}

  /// 对于 iOS 和 MacOS，需要获取通知权限
  void requireNotificationPermission() async {
    bool result = true;
    if (Platform.isIOS) {
      result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isMacOS) {
      result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    if (!result) {
      Fluttertoast.showToast(
        msg: "请授权通知权限，否则本程序无法正常使用",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
      );
    }
  }
}
