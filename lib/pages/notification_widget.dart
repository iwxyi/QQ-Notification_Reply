import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/pages/group_select_widget.dart';

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
              '群组',
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
                  title: Text('还没想好……'),
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
    /*List<String> lines = <String>[
      'Alex Faarborg  Check this out',
      'Jeff Chang    Launch Party'
    ];

    InboxStyleInformation inboxStyleInformation = InboxStyleInformation(lines,
        contentTitle: '2 messages', summaryText: 'janedoe@example.com');

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
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(channelId, channelName, channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await UserAccount.flutterLocalNotificationsPlugin.show(
        notificationId, title, body, platformChannelSpecifics,
        payload: payload);
  }
}
