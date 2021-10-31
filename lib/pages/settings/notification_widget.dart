import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/pages/settings/group_select_widget.dart';

class NotificationWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
              '聊天',
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
                    Icons.all_inclusive,
                    color: Colors.blue,
                  ),
                  title: Text('禁用会话功能'),
                  subtitle: Text('开启后仅剩下通知栏消息，可能轻微减少耗电(重启生效)'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableSelfChats = !G.st.enableSelfChats;
                        G.st.setConfig(
                            'function/selfChats', G.st.enableSelfChats);
                      });
                    },
                    value: !G.st.enableSelfChats,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableSelfChats = !G.st.enableSelfChats;
                      G.st.setConfig(
                          'function/selfChats', G.st.enableSelfChats);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.group,
                    color: Colors.red,
                  ),
                  title: Text('开启通知的群组'),
                  trailing: Icon(Icons.arrow_right),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return GroupSelectWidget();
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
              '回调',
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
                    Icons.all_inclusive,
                    color: Colors.blue,
                  ),
                  title: Text('点击通知跳转QQ'),
                  subtitle: Text('进入QQ会话还是本程序的会话'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.notificationLaunchQQ = !G.st.notificationLaunchQQ;
                        G.st.setConfig(
                            'notification/launchQQ', G.st.notificationLaunchQQ);
                      });
                    },
                    value: G.st.notificationLaunchQQ,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.notificationLaunchQQ = !G.st.notificationLaunchQQ;
                      G.st.setConfig(
                          'notification/launchQQ', G.st.notificationLaunchQQ);
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '其他',
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
                    Icons.all_inclusive,
                    color: Colors.blue,
                  ),
                  title: Text('测试通知'),
                  onTap: testOperator,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void testOperator() async {
    List<String> lines = <String>[
      'Alex Faarborg  Check this out',
      'Jeff Chang    Launch Party'
    ];

    /*InboxStyleInformation inboxStyleInformation = InboxStyleInformation(lines,
        contentTitle: '2 messages', summaryText: 'janedoe@example.com');

    // ignore: unused_local_variable
    AndroidNotificationDetails androidPlatformChannelSpecifics0 =
        AndroidNotificationDetails(
            'channelId', 'channelName', 'channelDescription',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'groupChannelId', 'groupChannelName', 'groupChannelDescription',
            styleInformation: inboxStyleInformation,
            groupKey: 'groupKey',
            priority: Priority.high,
            setAsGroupSummary: true,
            importance: Importance.max);

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await UserAccount.flutterLocalNotificationsPlugin
        .show(0, 'Attention', 'Two messages', platformChannelSpecifics);*/
  }

  /// 显示通知根方法
  /// @param channelId: 是通知分类ID，相同ID会导致覆盖
  /// @param channelName: 是分类名字
  /// @param channelDescription: 是分类点进设置后的底部说明
  /// @param title: 通知标题
  /// @param content: 通知内容
  /// @param payload: 回调的字符串
  void showPlatNotification(
      int notificationId,
      String channelId,
      String channelName,
      String channelDescription,
      String title,
      String body,
      String payload) async {
    // 添加新的通知
    /*AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(channelId, channelName, channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await UserAccount.flutterLocalNotificationsPlugin.show(
        notificationId, title, body, platformChannelSpecifics,
        payload: payload);*/
  }
}
