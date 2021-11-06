import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/pages/settings/all_messages_page.dart';
import 'package:qqnotificationreply/pages/settings/display_settings_widget.dart';
import 'package:qqnotificationreply/pages/settings/login_widget.dart';
import 'package:qqnotificationreply/pages/settings/notification_settings_widget.dart';

class MySettingsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MySettingsWidgetState();
}

class _MySettingsWidgetState extends State<MySettingsWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  var eventBusFn;

  @override
  void initState() {
    super.initState();

    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.loginInfo ||
          event.event == Event.friendList ||
          event.event == Event.groupList ||
          event.event == Event.messageRaw) {
        setState(() {});

        if (event.event == Event.loginInfo) {
          Fluttertoast.showToast(
            msg: "登录成功",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
          );
        }
      }
      // print(event.obj);
    });
  }

  @override
  void dispose() {
    super.dispose();
    //取消订阅
    eventBusFn.cancel();
  }

  @override
  // ignore: must_call_super
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '账号',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Card(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: Colors.red,
                  ),
                  title: Text(G.cs.isConnected() ? G.ac.selfInfo() : '点击登录'),
                  trailing: Icon(Icons.arrow_right),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return LoginWidget();
                    })).then((value) {
                      // 可能登录了，刷新一下界面
                      setState(() {});
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.contact_phone,
                    color: Colors.blue,
                  ),
                  title: Text('好友数量：' + G.ac.friendList.length.toString()),
                  onTap: () => G.cs.getFriendList(),
                ),
                ListTile(
                  leading: Icon(
                    Icons.group,
                    color: Colors.blue,
                  ),
                  title: Text('群组数量：' + G.ac.groupList.length.toString()),
                  onTap: () => G.cs.getGroupList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '设置',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Card(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: Colors.blue,
                  ),
                  title: Text('通知设置'),
                  trailing: Icon(Icons.arrow_right),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return Scaffold(
                        appBar: AppBar(
                          title: Text('通知设置'),
                        ),
                        body: NotificationSettingsWidget(),
                      );
                    })).then((value) {
                      // 可能登录了，刷新一下界面
                      setState(() {});
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings_display,
                    color: Colors.blue,
                  ),
                  title: Text('显示设置'),
                  trailing: Icon(Icons.arrow_right),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return Scaffold(
                        appBar: AppBar(
                          title: Text('显示设置'),
                        ),
                        body: DisplaySettingsWidget(),
                      );
                    })).then((value) {
                      // 可能登录了，刷新一下界面
                      setState(() {});
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '调试',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Card(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.sync,
                    color: Colors.red,
                  ),
                  title: Text(
                    '心跳时间：' +
                        (G.cs.lastHeartTime == 0
                            ? '无'
                            : ((DateTime.now().millisecondsSinceEpoch -
                                            G.cs.lastHeartTime) ~/
                                        1000)
                                    .toString() +
                                '秒前'),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.history,
                    color: Colors.blue,
                  ),
                  title: Text('日志记录：' + G.ac.allLogs.length.toString()),
                  trailing: Icon(Icons.arrow_right),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return AllMessageListWidget();
                    })).then((value) {
                      // 可能登录了，刷新一下界面
                      setState(() {});
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
