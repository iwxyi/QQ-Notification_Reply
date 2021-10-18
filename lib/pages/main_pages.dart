import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/pages/account_widget.dart';
import 'package:qqnotificationreply/pages/notification_widget.dart';
import 'package:qqnotificationreply/services/cqhttpservice.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:qqnotificationreply/utils/file_util.dart';

// ignore: unused_import
import 'package:qqnotificationreply/widgets/app_retain_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/gallerybar.dart';
import 'chat_list_page.dart';
import 'chat_widget.dart';
import 'contacts_page.dart';

const Color _appBarColor1 = const Color(0xFF3B5F8F);
const Color _appBarColor2 = const Color(0xFF8266D4);
const Color _appBarColor3 = const Color(0xFFF95B57);
const Color _appBarColor4 = const Color(0xFFF3A646);

class MainPages extends StatefulWidget {
  MainPages() {
    // 自动登录
    if (G.st.host != null && G.st.host.isNotEmpty) {
      G.cs.connect(G.st.host, G.st.token);
    }
  }

  @override
  _MainPagesState createState() => _MainPagesState();
}

enum AppBarMenuItems { AllReaded }

class _MainPagesState extends State<MainPages> {
  int _selectedIndex = 0; // 导航栏当前项

  List<CardSection> allPages = <CardSection>[
    CardSection(
        title: '会话',
        leftColor: _appBarColor2,
        rightColor: _appBarColor1,
        contentWidget: G.st.enableSelfChats
            ? new ChatListPage()
            : new Center(
                child: new Text('会话已禁用'),
              )),
    CardSection(
        title: '联系人',
        leftColor: _appBarColor2,
        rightColor: _appBarColor1,
        contentWidget: new ContactsPage()),
    CardSection(
        title: '设置',
        leftColor: _appBarColor2,
        rightColor: _appBarColor1,
        contentWidget: new AccountWidget()),
    CardSection(
        title: '通知',
        leftColor: _appBarColor1,
        rightColor: _appBarColor4,
        contentWidget: new NotificationWidget()),
  ];

  var eventBusFn;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    // 读取配置
    _selectedIndex = G.st.getInt('recent/navigation', 0);

    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.messageRaw) {
        _messageReceived(event.data);
      } else if (event.event == Event.friendList ||
          event.event == Event.groupList) {
        setState(() {});
      }
    });

    // 判断是否需要通知
    // Windows不支持通知
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      // 获取通知权限
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CatlikeQQ'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('等待开发')));
            },
          ),
          PopupMenuButton<AppBarMenuItems>(
            onSelected: (AppBarMenuItems result) {
              setState(() {});
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<AppBarMenuItems>>[
              const PopupMenuItem<AppBarMenuItems>(
                value: AppBarMenuItems.AllReaded,
                child: Text('全部标位已读'),
              ),
            ],
          )
        ],
      ),
      body: allPages[_selectedIndex].contentWidget,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '会话',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: '联系人',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
    /* // 自定义滑块视图
    return AppRetainWidget(
      child: AnimateTabNavigation(
        sectionList: allSections,
      ),
    ); */
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      G.st.setConfig('recent/navigation', index);
    });
  }

  /// 所有msg raw都会到这里来
  /// 进行数据的处理操作，例如准备头像的显示
  void _messageReceived(MsgBean msg) {
    // 准备显示的资源
    if (G.st.enableHeader) {
      /* if (!FileUtil.isFileExists(G.rt.userHeader(msg.senderId))) {
        CqhttpService.downloadUserHeader(msg.senderId);
      }
      if (msg.isGroup()) {
        CqhttpService.downloadGroupHeader(msg.groupId);
      } */
    }
    G.ac.eventBus.fire(EventFn(Event.messageReady, msg));

    // 显示通知（如果平台支持）
    _showNotification(msg);
  }

  /// 显示通知栏通知
  /// 仅支持 Android、IOS、MacOS
  void _showNotification(MsgBean msg) async {
    // 当前平台不支持该通知
    if (flutterLocalNotificationsPlugin == null) {
      return;
    }

    // 该聊天对象的通知ID（每次启动都不一样）
    int id = UserAccount.getNotificationId(msg);

    // 判断自己的通知
    if (msg.senderId == G.ac.qqId) {
      // 自己发的，一定不需要再通知了
      // 还需要消除掉该聊天对象的通知
      flutterLocalNotificationsPlugin.cancel(id);
      return;
    }

    // 显示通知
    String personUri =
        'mqqapi://card/show_pslcard?src_type=internal&source=sharecard&version=1&uin=${msg.senderId}';
    String displayMessage = G.cs.getMessageDisplay(msg);
    Person person = new Person(
        bot: false, important: false, name: msg.username(), uri: personUri);
    Message message = new Message(displayMessage, DateTime.now(), person);
    AndroidNotificationDetails androidPlatformChannelSpecifics;

    if (msg.isPrivate()) {
      // 私聊消息
      /*print('----id private:' + msg.friendId.toString() + ' ' + id.toString());*/
      if (!G.ac.unreadPrivateMessages.containsKey(msg.friendId)) {
        G.ac.unreadPrivateMessages[msg.friendId] = [];
      }
      G.ac.unreadPrivateMessages[msg.friendId].add(message);

      MessagingStyleInformation messagingStyleInformation =
          new MessagingStyleInformation(person,
              conversationTitle: msg.username(),
              messages: G.ac.unreadPrivateMessages[msg.friendId]);

      androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'private_message', '私聊消息', 'QQ好友消息/临时会话',
          styleInformation: messagingStyleInformation,
          groupKey: 'chat',
          priority: Priority.high,
          importance: Importance.high);
    } else if (msg.isGroup()) {
      // 群聊消息
      if (!G.ac.unreadGroupMessages.containsKey(msg.groupId)) {
        G.ac.unreadGroupMessages[msg.groupId] = [];
      }
      G.ac.unreadGroupMessages[msg.groupId].add(message);

      Person group = new Person(
          bot: true, important: true, name: msg.groupName, uri: personUri);

      MessagingStyleInformation messagingStyleInformation =
          new MessagingStyleInformation(group,
              conversationTitle: msg.groupName,
              messages: G.ac.unreadGroupMessages[msg.groupId]);

      androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'group_message', '群组消息', 'QQ群组消息',
          styleInformation: messagingStyleInformation,
          groupKey: 'chat',
          priority: Priority.high,
          importance: Importance.high);
    }
    if (androidPlatformChannelSpecifics == null) {
      return;
    }

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        id, msg.username(), displayMessage, platformChannelSpecifics,
        payload: msg.messageId.toString());
  }

  /// 通知点击回调
  Future<dynamic> onSelectNotification(String payload) async {
    print('通知.payload: $payload');
    MsgBean msg = G.ac.getMsgById(int.parse(payload));

    if (msg.isPrivate()) {
      G.ac.unreadPrivateMessages.remove(msg.friendId);
    } else if (msg.isGroup()) {
      G.ac.unreadGroupMessages.remove(msg.groupId);
    }
    
    if (!G.st.notificationLaunchQQ) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return ChatWidget(msg);
      })).then((value) {
        setState(() {});
      });
    } else {
      String url;
      // android 和 ios 的 QQ 启动 url scheme 是不同的
      if (msg.isPrivate()) {
        G.ac.unreadPrivateMessages[msg.friendId].clear();
        url = 'mqq://im/chat?chat_type=wpa&uin=' +
            msg.friendId.toString() +
            '&version=1&src_type=web';
        // &web_src=qq.com
      } else {
        G.ac.unreadGroupMessages[msg.groupId].clear();
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
      const forceTry = true;
      if (await canLaunch(url) || forceTry) {
        print('打开URL: ' + url);
        try {
          await launch(url); // 启动QQ
        } catch (e) {
          print('打开URL失败：' + e.toString());
          Fluttertoast.showToast(
            msg: "打开URL失败：" + url,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
          );
        }
      } else {
        // 自己封装的一个 Toast
        print('无法打开URL: ' + url);
        Fluttertoast.showToast(
          msg: "无法打开URL：" + url,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
        );
      }
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
