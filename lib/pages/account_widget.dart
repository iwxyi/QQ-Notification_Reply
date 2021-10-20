import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/pages/all_messages_page.dart';
import 'package:qqnotificationreply/pages/login_widget.dart';
import 'package:qqnotificationreply/pages/notification_widget.dart';

class AccountWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AccountWidgetState();
}

class _AccountWidgetState extends State<AccountWidget>
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
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
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
                  title: Text(G.ac.connectState > 0 ? G.ac.selfInfo() : '点击登录'),
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '列表',
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
                ListTile(
                  leading: Icon(
                    Icons.history,
                    color: Colors.blue,
                  ),
                  title: Text('消息记录：' + G.ac.allMessages.length.toString()),
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
                        body: NotificationWidget(),
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
        ],
      ),
    );
  }
}
