import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qqnotificationreply/global/api.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/pages/profile/user_profile_widget.dart';
import 'package:qqnotificationreply/pages/settings/my_settings_widget.dart';
import 'package:qqnotificationreply/pages/settings/notification_settings_widget.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

// ignore: unused_import
import 'package:qqnotificationreply/widgets/app_retain_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/gallerybar.dart';
import 'chat_list_page.dart';
import '../chat/chat_widget.dart';
import '../contact/contacts_page.dart';
import 'search_page.dart';
import '../settings/login_widget.dart';
import 'transparent_app_bar.dart';

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
        contentWidget: new MySettingsWidget()),
    CardSection(
        title: '通知',
        leftColor: _appBarColor1,
        rightColor: _appBarColor4,
        contentWidget: new NotificationSettingsWidget()),
  ];

  var eventBusFn; // 通知

  /// 判断前后台的状态
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _notification = state;
      print('应用状态：' + _notification.index.toString());
      if (_notification.index == 1 || _notification.index == 0) {
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
    // _selectedIndex = G.st.getInt('recent/navigation', 0);
    _selectedIndex = 0;

    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.messageRaw) {
        _messageReceived(event.data);
      } else if (event.event == Event.friendList ||
          event.event == Event.groupList) {
        if (mounted) {
          setState(() {});
        }
      } else if (event.event == Event.refreshState) {
        if (mounted) {
          setState(() {});
        }
      }
    });

    // 初始化通知
    _initNotifications();

    // 任意位置打开聊天页面
    G.rt.mainContext = context;
    G.rt.showChatPage = (MsgBean msg, {directlyClose: false}) {
      // 清除通知
      if (G.rt.enableNotification) {
        if (UserAccount.notificationIdMap.containsKey(msg.keyId())) {
          _cancelNotification(UserAccount.notificationIdMap[msg.keyId()]);
        }
      }

      if (G.st.groupSmartFocus && msg.isGroup()) {
        GroupInfo group = G.ac.groupList[msg.groupId];
        group.focusAsk = false;
        group.focusAt = null;
      }

      // 当前页面直接替换
      if (G.rt.currentChatPage != null) {
        // 判断旧页面
        if (G.rt.horizontal != G.rt.currentChatPage.innerMode) {
          // 如果状态不一致，得删除
          // MsgBean obj = G.rt.currentChatPage.chatObj;
          G.rt.currentChatPage = null;

          /* if (G.rt.horizontal == true) {
            // 如果是竖屏->横屏，则重新创建
            G.rt.showChatPage(obj);
          } else {
            // 如果是横屏->竖屏，则不进行处理
          } */
        } else {
          // 已有的页面，直接设置即可
          setState(() {
            G.rt.currentChatPage.setObject(msg);
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (Platform.isWindows) {
                G.rt.currentChatPage.setDirectlyClose(directlyClose);
                G.rt.currentChatPage.focusEditor();
              }
            });
          });
          return;
        }
      }

      if (G.rt.horizontal) {
        // 横屏页面
        setState(() {
          // 直接创建就行了，更新状态的时候会自动获取
          G.rt.currentChatPage = new ChatWidget(msg, innerMode: true);
        });
      } else {
        // 重新创建页面
        Navigator.of(G.rt.mainContext).push(MaterialPageRoute(
          builder: (context) {
            G.rt.currentChatPage =
                new ChatWidget(msg, directlyClose: directlyClose);
            return G.rt.currentChatPage;
          },
        )).then((value) {
          G.rt.currentChatPage = null;
          setState(() {});
        });
      }
    };

    G.rt.updateChatPageUnreadCount = () {
      if (G.rt.currentChatPage == null || G.rt.horizontal) {
        return;
      }
      int keyId = G.rt.currentChatPage.chatObj.keyId();
      int sum = 0;
      G.ac.unreadMessageCount.forEach((key, value) {
        // 不显示自己的消息
        if (key == keyId) {
          return;
        }
        // 不显示不通知群组的消息
        if (key < 0 && !G.st.enabledGroups.contains(-key)) {
          return;
        }
        sum += value;
      });
      if (G.rt.currentChatPage != null &&
          G.rt.currentChatPage.setUnreadCount != null) {
        G.rt.currentChatPage.setUnreadCount(sum);
      }
      // print('--------设置数量：' + sum.toString());
    };

    G.rt.showUserInfo = (json) {};

    G.rt.showGroupInfo = (json) {};
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
                constraints: BoxConstraints(
                    maxWidth: max(G.rt.chatListFixedWidth,
                        MediaQuery.of(context).size.width / 3)),
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
        value: AppBarMenuItems.Search,
        child: Text('搜索'),
      ));
      menus.add(const PopupMenuItem<AppBarMenuItems>(
        value: AppBarMenuItems.Contacts,
        child: Text('联系人'),
      ));
      menus.add(const PopupMenuItem<AppBarMenuItems>(
        value: AppBarMenuItems.Settings,
        child: Text('设置'),
      ));
    }

    return PopupMenuButton<AppBarMenuItems>(
        icon: Icon(Icons.more_vert,
            color: Theme.of(context).textTheme.bodyText2.color),
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
                  return createScaffoldPage(context, new ContactsPage(), '联系人');
                },
              ));
              break;
            case AppBarMenuItems.Settings:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return createScaffoldPage(
                      context, new MySettingsWidget(), '设置');
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
        });
  }

  // ignore: unused_element
  Widget _buildAppBar0(BuildContext context) {
    List<Widget> btnWidget = [];
    if (G.rt.horizontal) {
      // 横屏，分列
      btnWidget.add(IconButton(
        icon: Icon(
          Icons.search,
          color: Theme.of(context).textTheme.bodyText2.color,
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
        icon: Icon(
          Icons.search,
          color: Theme.of(context).textTheme.bodyText2.color,
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
        title: Text(
          'Message',
          style: TextStyle(color: Theme.of(context).textTheme.bodyText2.color),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: btnWidget);
  }

  TransparentAppBar _buildAppBar(BuildContext context) {
    List<Widget> widgets = [];
    bool isHoriz = G.rt.horizontal;

    // 标题
    widgets.add(Text(
      'Message',
      style: TextStyle(
          color: Theme.of(context).textTheme.bodyText2.color,
          fontSize: 20,
          fontWeight: FontWeight.w600),
    ));

    widgets.add(Expanded(child: new Text('')));

    if (!isHoriz) {
      // 搜索按钮
      widgets.add(IconButton(
        icon: Icon(
          Icons.search,
          color: Theme.of(context).textTheme.bodyText2.color,
        ),
        tooltip: '搜索',
        onPressed: () {
          openSearch();
        },
      ));

      // 菜单
      widgets.add(_buildMenu(context));
    }

    // 主标题的容器
    double statusBarHeight =
        MediaQueryData.fromWindow(window).padding.top; // 系统状态栏高度
    Widget mainContainer = Container(
      child: Row(
        children: widgets,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      padding: EdgeInsets.only(
        left: 0,
        right: 0,
        // top: statusBarHeight,
      ),
      constraints: BoxConstraints(
          maxWidth: isHoriz ? G.rt.chatListFixedWidth : double.infinity),
    );

    Widget child = mainContainer;

    // 横屏显示菜单
    if (isHoriz) {
      // 副标题的容器
      String title = G.rt.currentChatPage != null
          ? G.st.getLocalNickname(G.rt.currentChatPage.chatObj.keyId(),
              G.rt.currentChatPage.chatObj.title())
          : '';

      /* // 卡片标题
      Widget titleCard = Card(
        child: Container(
          child: Row(children: [
            new Text(
              title,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyText2.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            )
          ]),
          padding: EdgeInsets.only(left: 24, right: 24, top: 9, bottom: 9),
        ),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(20.0)), //设定 Card 的倒角大小,
        ),
      ); */

      Widget titleCard = new Text(
        title,
        style: TextStyle(
            color: Theme.of(context).textTheme.bodyText2.color,
            fontSize: 20,
            fontWeight: FontWeight.w500),
      );

      Widget subContainer = Expanded(
          child: Container(
              padding: EdgeInsets.only(left: 12, right: 12, top: 0),
              constraints: BoxConstraints(minHeight: kToolbarHeight),
              alignment: Alignment.center,
              child: G.rt.currentChatPage == null ? Text('') : titleCard));

      List<Widget> rowWidgets = [mainContainer, subContainer];

      if (G.rt.currentChatPage != null &&
          G.rt.currentChatPage.buildChatMenu != null) {
        Widget menu = G.rt.currentChatPage.buildChatMenu();
        rowWidgets.add(menu);
      }

      child = Row(
        children: rowWidgets,
      );
    }

    // 返回
    return TransparentAppBar(
        Container(
          child: child,
          height: kToolbarHeight, // 固定位状态栏高度
          /*decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Color(0xFFFAD956),
              Color(0xFF00D956),
            ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),*/
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

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Container(
            height: 170,
            child: UserAccountsDrawerHeader(
              //设置用户名
              accountName: new Text(
                  G.ac.myNickname != null && G.ac.myNickname.isNotEmpty
                      ? G.ac.myNickname
                      : '未登录'),
              //设置用户邮箱
              accountEmail:
                  new Text(G.ac.myId != 0 ? G.ac.myId.toString() : ''),
              //设置当前用户的头像
              currentAccountPicture: new CircleAvatar(
                backgroundImage: G.ac.isLogin()
                    ? NetworkImage(API.userHeader(G.ac.myId))
                    : AssetImage('icons/cat_chat.png'),
              ),
              //回调事件
              onDetailsPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return LoginWidget();
                })).then((value) {
                  // 可能登录了，刷新一下界面
                  setState(() {});
                });
              },
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              readOnly: true,
              onTap: () {
                Navigator.pop(context);
                openSearch();
              },
            ),
          ),
          SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.chat),
            title: new Text('会话'),
            onTap: () {
              setState(() {
                _selectedIndex = 0;
                Navigator.pop(context);
              });
            },
            selected: _selectedIndex == 0,
          ),
          ListTile(
            leading: Icon(Icons.contacts),
            title: new Text('联系人'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return createScaffoldPage(context, new ContactsPage(), '联系人');
                },
              ));
            },
            selected: _selectedIndex == 1,
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: new Text('设置'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) {
                  return createScaffoldPage(
                      context, new MySettingsWidget(), '设置');
                },
              ));
            },
            selected: _selectedIndex == 2,
          ),
        ],
      ),
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
      /* bottomNavigationBar:
          G.rt.horizontal ? null : _buildBottomNavigationBar(context), */
      drawer: _buildDrawer(),
      onDrawerChanged: (e) {
        if (G.rt.currentChatPage != null) {
          G.rt.currentChatPage.unfocusEditor();
        }
      },
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
      int keyId = int.parse(receivedNotification.payload['id']);
      print(
          'notification chatId: $keyId, keyButton: ${receivedNotification.buttonKeyPressed}, keyInput:${receivedNotification.buttonKeyInput}');
      if (receivedNotification.buttonKeyInput.isNotEmpty) {
        // 输入
        onNotificationReply(keyId, receivedNotification.buttonKeyInput);
      } else if (receivedNotification.buttonKeyPressed.isNotEmpty) {
        // 点击动作按钮（输入也会触发）
      } else {
        // 点击通知
        print('点击通知');
        onSelectNotification(keyId);
      }
    });
  }

  /// 取消通知
  /// @param id 通知的ID，不是聊天ID或者消息ID
  void _cancelNotification(int id) {
    if (!G.rt.enableNotification) {
      return;
    }
    AwesomeNotifications().cancel(id);
  }

  /// 显示通知栏通知
  /// 仅支持 Android、IOS、MacOS
  void _showNotification(MsgBean msg) async {
    // 该聊天对象的通知ID（每次启动都不一样）
    int id = UserAccount.getNotificationId(msg);

    // 判断自己的通知
    if (msg.senderId == G.ac.myId) {
      // 自己发的，一定不需要再通知了
      // 还需要消除掉该聊天对象的通知
      _cancelNotification(id);
      return;
    }

    // 判断通知类型和级别
    String channelKey = 'notice';
    bool isSmartFocus = false; // 是否是智能聚焦，添加关闭（理论上来说不需要，因为是一次性的）
    bool isDynamicImportance = false; // 是否是动态重要性，添加关闭
    if (msg.isPrivate()) {
      // 私聊消息
      channelKey = 'private_chats';
    } else if (msg.isGroup()) {
      if (msg.isPureMessage()) {
        // 群消息智能聚焦：有没有 @我 或者 回复我 的消息
        String text = msg.message ?? '';
        bool contains = false;
        if (text.contains('[CQ:at,qq=${G.ac.myId}]')) {
          // @自己、回复
          contains = true;
        } else if (G.st.notificationAtAll && text.contains('[CQ:at,qq=all]')) {
          // @全体
          contains = true;
        } else if (G.st.groupSmartFocus) {
          GroupInfo group = G.ac.groupList[msg.groupId];
          if (group != null) {
            if (group.focusAsk) {
              // 疑问聚焦
              contains = true;
              print('群消息.疑问聚焦');
            } else if (group.focusAt != null &&
                group.focusAt.contains(msg.senderId)) {
              contains = true;
              print('群消息.艾特聚焦');
            }
          }
        }
        if (contains) {
          channelKey = 'important_group_chats';
          isSmartFocus = true;
        } else {
          channelKey = 'normal_group_chats';
        }

        // 群消息动态重要性：判断自己发消息的时间
        if (G.st.groupDynamicImportance &&
            G.ac.messageMyTimes.containsKey(msg.keyId())) {
          contains = false;
          int delta = DateTime.now().millisecondsSinceEpoch -
              G.ac.messageMyTimes[msg.keyId()];
          delta = delta ~/ 1000; // 转换为秒
          int rCount = G.ac.receivedCountAfterMySent[msg.keyId()] ?? 0;
          rCount--; // 自己发送消息后的收到的别人的消息数量
          if (delta <= 60 || rCount <= 3) {
            // 一分钟内：重要
            channelKey = 'important_group_chats';
            isDynamicImportance = true;
            print('群消息.动态重要性.重要  $delta  $rCount');
          } else if (delta <= 180 || rCount <= 10) {
            // 一分钟内：普通通知，且忽视不通知
            if (channelKey != 'important_group_chats') {
              channelKey = 'normal_group_chats';
              print('群消息.动态重要性.普通  $delta  $rCount');
            }
            isDynamicImportance = true;
          }
        }
      } else {
        // 不是消息类通知
        channelKey = 'normal_group_chats';
      }

      // 重要群组消息，强制设置为重要
      if (G.st.importantGroups.contains(msg.groupId) ||
          G.st.specialGroupMember.contains(msg.senderId)) {
        channelKey = 'important_group_chats';
      }

      // 判断未启用的群组是否需要显示通知
      if (!G.st.enabledGroups.contains(msg.groupId) &&
          channelKey == 'normal_group_chats' &&
          !isDynamicImportance) {
        return;
      }
    }

    // 在前台
    if (G.rt.runOnForeground) {
      if (G.rt.currentChatPage != null && !G.rt.horizontal) {
        if (!msg.isObj(G.rt.currentChatPage.chatObj)) {
          // 显示在聊天界面顶层上面，并且能直接点进来
          if (G.rt.currentChatPage.showJumpMessage != null) {
            G.rt.currentChatPage.showJumpMessage(msg);
          } else {
            print('warning: G.rt.currentChatPage.showJumpMessage == null');
          }
        }
      }
      // 在前台的话，就不发送通知了
      return;
    }

    // 当前平台不支持该通知
    if (!G.rt.enableNotification) {
      return;
    }

    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: channelKey,
        groupKey: msg.keyId().toString(),
        summary: msg.isGroup()
            ? msg.groupName
            : msg.nickname ?? msg.username(),
        title: G.st.getLocalNickname(msg.senderKeyId(), msg.username()),
        body: G.cs.getMessageDisplay(msg),
        notificationLayout: NotificationLayout.Messaging,
        displayOnForeground: false,
        payload: {'id': msg.keyId().toString()},
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'reply',
          label: '回复',
          buttonType: ActionButtonType.InputField,
        )
      ],
    );
  }

  /// 通知点击回调
  Future<dynamic> onSelectNotification(int notificationId) async {
    int keyId = notificationId;
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
      // 后台通知打开的聊天界面，则在左上角显示一个叉，直接退出程序
      G.rt.showChatPage(msg, directlyClose: !G.rt.runOnForeground);
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

  void onNotificationReply(int keyId, String text) {
    MsgBean msg;
    if (G.ac.allMessages.containsKey(keyId))
      msg = G.ac.allMessages[keyId].last ?? null;
    if (msg == null) {
      print('未找到payload:$keyId');
      return;
    }

    G.cs.sendMsg(msg, text);
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

  Widget createScaffoldPage(BuildContext context, Widget widget, String title) {
    return Scaffold(
      appBar: AppBar(
        title: new Text(title),
        // backgroundColor: Colors.transparent,
        // elevation: 0,
      ),
      body: widget,
    );
  }

  void openSearch() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Container(
              constraints: BoxConstraints(minWidth: 350, maxHeight: 500),
              child: SearchPage(
                selectCallback: (msg) {
                  // 在聊天界面上显示
                  msg.timestamp = DateTime.now().millisecondsSinceEpoch;
                  G.ac.messageTimes[msg.keyId()] = msg.timestamp;
                  G.ac.eventBus.fire(EventFn(Event.newChat, msg));

                  // 打开聊天框
                  G.rt.showChatPage(msg);
                },
              ),
            ),
            contentPadding: EdgeInsets.all(5),
          );
        });
  }
}
