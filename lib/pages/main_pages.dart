import 'dart:io';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/pages/settings/account_widget.dart';
import 'package:qqnotificationreply/pages/settings/notification_widget.dart';
import 'package:qqnotificationreply/services/cqhttpservice.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:qqnotificationreply/utils/file_util.dart';

// ignore: unused_import
import 'package:qqnotificationreply/widgets/app_retain_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/gallerybar.dart';
import 'chat_list_page.dart';
import 'chat/chat_widget.dart';
import 'contact/contacts_page.dart';
import 'search_page.dart';
import '../widgets/slide_images_page.dart';
import 'settings/my_app_bar.dart';

const Color _appBarColor1 = const Color(0xFF3B5F8F);
const Color _appBarColor2 = const Color(0xFF8266D4);
const Color _appBarColor3 = const Color(0xFFF95B57);
const Color _appBarColor4 = const Color(0xFFF3A646);

class MainPages extends StatefulWidget {
  MainPages() {
    // 自动登录
    if (G.st.host != null && G.st.host.isNotEmpty && !G.cs.isConnected()) {
      G.cs.connect(G.st.host, G.st.token);
    }
  }

  @override
  _MainPagesState createState() => _MainPagesState();
}

enum AppBarMenuItems { AllReaded, Contacts, Settings, Search }

class _MainPagesState extends State<MainPages> with WidgetsBindingObserver {
  int _selectedIndex = 0; // 导航栏当前项
  AppLifecycleState _notification; // 前后台判断

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

  var eventBusFn; // 通知

  /// 判断前后台的状态
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _notification = state;
      print(_notification.index);
      if (_notification.index == 1) {
        G.rt.runOnForeground = true;
      } else if (_notification.index == 2) {
        G.rt.runOnForeground = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

    // 初始化通知
    _initNotifications();

    // 任意位置打开聊天页面
    G.rt.mainContext = context;
    G.rt.showChatPage = (MsgBean msg) {
      // 清除通知
      if (G.rt.enableNotification) {
        if (UserAccount.notificationIdMap.containsKey(msg.keyId())) {
          _cancelNotification(UserAccount.notificationIdMap[msg.keyId()]);
        }
      }

      // 当前页面直接替换
      if (G.rt.currentChatPage != null) {
        // 判断旧页面
        if (G.rt.horizontal != G.rt.currentChatPage.innerMode) {
          // 如果状态不一致，还是得先删除
          G.rt.currentChatPage = null;
        } else {
          setState(() {
            G.rt.currentChatPage.setObject(msg);
          });
          return;
        }
      }

      if (G.rt.horizontal) {
        // 横屏页面
        setState(() {
          G.rt.currentChatPage = new ChatWidget(msg, innerMode: true);
        });
      } else {
        // 重新创建页面
        Navigator.of(G.rt.mainContext).push(MaterialPageRoute(
          builder: (context) {
            G.rt.currentChatPage = new ChatWidget(msg);
            return G.rt.currentChatPage;
          },
        )).then((value) {
          G.rt.currentChatPage = null;
          setState(() {});
        });
      }
    };
  }

  Widget _buildChatObjView(BuildContext context) {
    if (G.rt.currentChatPage == null) {
      return new Center(
        child: new Text('没有聊天',
            style: TextStyle(fontSize: 20, color: Colors.grey)),
      );
    }

    // 构建聊天页面
    return G.rt.currentChatPage;
  }

  Widget _buildBody(BuildContext context) {
    // 横屏特判
    if (_selectedIndex == 0 && G.rt.horizontal) {
      return Row(
          children: [
            Container(
                constraints: BoxConstraints(maxWidth: G.rt.chatListFixedWidth),
                child: allPages[_selectedIndex].contentWidget),
            Expanded(child: _buildChatObjView(context))
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start);
    }

    // 默认状态
    return allPages[_selectedIndex].contentWidget;
  }

  Widget _buildMenu(BuildContext context) {
    List<PopupMenuEntry<AppBarMenuItems>> menus = [];

    menus.add(const PopupMenuItem<AppBarMenuItems>(
      value: AppBarMenuItems.AllReaded,
      child: Text('全部标为已读'),
    ));

    if (G.rt.horizontal) {
      menus.add(const PopupMenuItem<AppBarMenuItems>(
        value: AppBarMenuItems.Contacts,
        child: Text('联系人'),
      ));
      menus.add(const PopupMenuItem<AppBarMenuItems>(
        value: AppBarMenuItems.Search,
        child: Text('搜索'),
      ));
      menus.add(const PopupMenuItem<AppBarMenuItems>(
        value: AppBarMenuItems.Settings,
        child: Text('设置'),
      ));
    }

    return PopupMenuButton<AppBarMenuItems>(
      icon: Icon(Icons.more_vert, color: Colors.black),
      tooltip: '菜单',
      itemBuilder: (BuildContext context) => menus,
      onSelected: (AppBarMenuItems result) {
        switch (result) {
          case AppBarMenuItems.AllReaded:
            setState(() {
              _markAllReaded();
            });
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('全部已读')));
            G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
            break;
          case AppBarMenuItems.Contacts:
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) {
                return createScafoldPage(context, new ContactsPage(), '联系人');
              },
            ));
            break;
          case AppBarMenuItems.Settings:
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) {
                return createScafoldPage(context, new AccountWidget(), '设置');
              },
            ));
            break;
          case AppBarMenuItems.Search:
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) {
                return SearchPage();
              },
            ));
            break;
        }
      },
    );
  }

  // ignore: unused_element
  Widget _buildAppBar0(BuildContext context) {
    List<Widget> btnWidget = [];
    if (G.rt.horizontal) {
      // 横屏，分列
      btnWidget.add(IconButton(
        icon: const Icon(
          Icons.search,
          color: Colors.black,
        ),
        tooltip: '搜索',
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return new SearchPage();
            },
          ));
        },
      ));
    } else {
      // 竖屏，默认
      btnWidget.add(IconButton(
        icon: const Icon(
          Icons.search,
          color: Colors.black,
        ),
        tooltip: '搜索',
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return new SearchPage();
            },
          ));
        },
      ));
      btnWidget.add(_buildMenu(context));
    }

    return AppBar(
        brightness: Brightness.light,
        title: const Text(
          'Message',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: btnWidget);
  }

  MyAppBar _buildAppBar(BuildContext context) {
    List<Widget> widgets = [];
    bool isHoriz = G.rt.horizontal;

    // 标题
    widgets.add(const Text(
      'Message',
      style: TextStyle(
          color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
    ));

    widgets.add(Expanded(child: new Text('')));

    if (!isHoriz) {
      // 搜索按钮
      widgets.add(IconButton(
        icon: const Icon(
          Icons.search,
          color: Colors.black,
        ),
        tooltip: '搜索',
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) {
              return new SearchPage();
            },
          ));
        },
      ));
    }

    // 菜单
    widgets.add(_buildMenu(context));

    // 主标题的容器
    double statusBarHeight =
        MediaQueryData.fromWindow(window).padding.top; // 系统状态栏高度
    Widget mainContainer = Container(
      child: Row(
        children: widgets,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      padding: EdgeInsets.only(left: 18, right: 18, top: statusBarHeight),
      constraints: BoxConstraints(
          maxWidth: isHoriz ? G.rt.chatListFixedWidth : double.infinity),
    );

    Widget child = mainContainer;

    if (isHoriz) {
      // 副标题的容器
      String title = G.rt.currentChatPage != null
          ? G.rt.currentChatPage.chatObj.title()
          : '';
      Widget subContainer = Expanded(
          child: Container(
              padding: EdgeInsets.only(left: 12, right: 12, top: 0),
              child: G.rt.currentChatPage == null
                  ? Text('')
                  : Card(
                      child: Container(
                        child: Row(children: [
                          new Text(
                            title,
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          )
                        ]),
                        padding: EdgeInsets.only(
                            left: 24, right: 24, top: 9, bottom: 9),
                      ),
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(20.0)), //设定 Card 的倒角大小,
                      ),
                    )));
      child = Row(
        children: [mainContainer, subContainer],
      );
    }

    // 返回
    return MyAppBar(
        Container(
          child: child,
          /* decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Color(0xFFFAD956),
              Colors.white,
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ), */
        ),
        ValueKey(G.rt.currentChatPage == null
            ? 0
            : G.rt.currentChatPage.chatObj.keyId()));
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    G.rt.mainContext = context;
    // 判断横屏还是竖屏
    bool hori = MediaQuery.of(context).size.width >
            MediaQuery.of(context).size.height * 1.2 &&
        MediaQuery.of(context).size.width > G.rt.chatListFixedWidth * 1.5;
    G.rt.horizontal = hori;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar:
          G.rt.horizontal ? null : _buildBottomNavigationBar(context),
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
    if (msg.action == ActionType.SystemLog) {
      return;
    }

    // 判断是否需要显示通知
    if (msg.isGroup()) {
      if (!G.st.enabledGroups.contains(msg.groupId)) {
        return;
      }
    }

    // 显示通知（如果平台支持）
    _showNotification(msg);
  }

  /// 初始化通知
  void _initNotifications() {
    // 判断是否需要通知（Windows不支持通知）
    G.rt.enableNotification =
        (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    if (!G.rt.enableNotification) {
      return;
    }
    // 获取通知权限
    requireNotificationPermission();

    // 监听tap
    AwesomeNotifications().actionStream.listen((receivedNotification) {
      // receivedNotification.id
      print('-------------notification.tap----------------');
      print(receivedNotification.id.toString());
    });
  }

  /// 取消通知
  /// @param id 通知的ID，不是聊天ID或者消息ID
  void _cancelNotification(int id) {
    AwesomeNotifications().cancel(id);
  }

  /// 显示通知栏通知
  /// 仅支持 Android、IOS、MacOS
  void _showNotification(MsgBean msg) async {
    // 当前平台不支持该通知
    if (!G.rt.enableNotification) {
      return;
    }

    // 该聊天对象的通知ID（每次启动都不一样）
    int id = UserAccount.getNotificationId(msg);

    // 判断自己的通知
    if (msg.senderId == G.ac.qqId) {
      // 自己发的，一定不需要再通知了
      // 还需要消除掉该聊天对象的通知
      _cancelNotification(id);
      return;
    }

    // 前台不显示通知
    if (G.rt.runOnForeground) {
      //      return;
    }

    // 显示通知
    String personUri =
        'mqqapi://card/show_pslcard?src_type=internal&source=sharecard&version=1&uin=${msg.senderId}';
    String displayMessage = G.cs.getMessageDisplay(msg);
    AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: 10,
            channelKey: 'basic_channel',
            summary: 'chatName',
            title: 'username',
            body: 'message',
            notificationLayout: NotificationLayout.MessagingGroup),
        actionButtons: [
          NotificationActionButton(
              key: 'test',
              label: 'label',
              autoDismissable: true,
              buttonType: ActionButtonType.InputField)
        ]);

    /*Person person = new Person(
        bot: false, important: true, name: msg.username(), uri: personUri);
    Message message = new Message(displayMessage, DateTime.now(), person);
    AndroidNotificationDetails androidPlatformChannelSpecifics;

    if (!G.ac.unreadMessages.containsKey(msg.keyId())) {
      G.ac.unreadMessages[msg.keyId()] = [];
    }
    G.ac.unreadMessages[msg.keyId()].add(message);
    if (msg.isPrivate()) {
      // 私聊消息
      */ /*print('----id private:' + msg.friendId.toString() + ' ' + id.toString());*/ /*

      MessagingStyleInformation messagingStyleInformation =
          new MessagingStyleInformation(person,
              conversationTitle: msg.username(),
              messages: G.ac.unreadMessages[msg.keyId()]);

      androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'private_message', '私聊消息', 'QQ好友消息/临时会话',
          styleInformation: messagingStyleInformation,
          groupKey: 'chat',
          priority: Priority.high,
          importance: Importance.high);
    } else if (msg.isGroup()) {
      // 群聊消息
      Person group = new Person(
          bot: false, important: true, name: msg.groupName, uri: personUri);

      MessagingStyleInformation messagingStyleInformation =
          new MessagingStyleInformation(group,
              conversationTitle: msg.groupName,
              messages: G.ac.unreadMessages[msg.keyId()]);

      String channelId, channelName;
      Priority priority;
      Importance importance;
      if (G.st.importantGroups.contains(msg.groupId)) {
        channelId = "important_group_message";
        channelName = "重要群组消息";
        priority = Priority.high;
        importance = Importance.high;
      } else {
        channelId = "group_message";
        channelName = "普通群组消息";
        priority = Priority.defaultPriority;
        importance = Importance.defaultImportance;
      }

      androidPlatformChannelSpecifics = AndroidNotificationDetails(
          channelId, channelName, 'QQ群组消息',
          styleInformation: messagingStyleInformation,
          groupKey: 'chat',
          priority: priority,
          importance: importance);
    }
    if (androidPlatformChannelSpecifics == null) {
      return;
    }

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        id, msg.username(), displayMessage, platformChannelSpecifics,
        payload: msg.keyId().toString());*/
  }

  /// 通知点击回调
  Future<dynamic> onSelectNotification(String payload) async {
    print('通知.payload: $payload');
    int keyId = int.parse(payload);
    MsgBean msg;
    if (G.ac.allMessages.containsKey(keyId))
      msg = G.ac.allMessages[keyId].last ?? null;
    if (msg == null) {
      print('未找到payload:$keyId');
      return;
    }

    G.ac.clearUnread(msg);

    // 打开会话
    if (!G.st.notificationLaunchQQ) {
      G.rt.showChatPage(msg);
    } else {
      String url;
      // android 和 ios 的 QQ 启动 url scheme 是不同的
      if (msg.isPrivate()) {
        url = 'mqq://im/chat?chat_type=wpa&uin=' +
            msg.friendId.toString() +
            '&version=1&src_type=web';
        // &web_src=qq.com
      } else {
        url = 'mqq://im/chat?chat_type=group&uin=' +
            msg.groupId.toString() +
            '&version=1&src_type=web';
      }
      //      G.ac.unreadMessages[msg.keyId()].clear();

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
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // Insert here your friendly dialog box before call the request method
        // This is very important to not harm the user experience
        AwesomeNotifications()
            .requestPermissionToSendNotifications()
            .then((result) {
          if (!result) {
            Fluttertoast.showToast(
              msg: "请授权通知权限，否则本程序无法正常使用",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
            );
          }
        });
      }
    });
  }

  void _markAllReaded() {
    //    G.ac.unreadMessages.clear();
    G.ac.unreadMessageCount.clear();
  }

  @override
  void dispose() {
    // 释放资源
    if (G.cs.channel != null && G.cs.channel.innerWebSocket != null) {
      G.cs.channel.innerWebSocket.close();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Widget createScafoldPage(BuildContext context, Widget widget, String title) {
    return Scaffold(
      appBar: AppBar(
        title: new Text(title),
        // backgroundColor: Colors.transparent,
        // elevation: 0,
      ),
      body: widget,
    );
  }
}
