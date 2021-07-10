import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';

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
                  onTap: selectEnabledGroup,
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

  /// 选择开启通知的群组
  void selectEnabledGroup() {
    // TODO: 多选对话框
  }

  void testOperator() async {
    const List<String> lines = <String>[
      'Alex Faarborg  Check this out',
      'Jeff Chang    Launch Party'
    ];

    const InboxStyleInformation inboxStyleInformation = InboxStyleInformation(
        lines,
        contentTitle: '2 messages',
        summaryText: 'janedoe@example.com');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'groupChannelId', 'groupChannelName', 'groupChannelDescription',
            styleInformation: inboxStyleInformation,
            groupKey: 'groupKey',
            priority: Priority.high,
            setAsGroupSummary: true,
            importance: Importance.max);

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await UserAccount.flutterLocalNotificationsPlugin
        .show(0, 'Attention', 'Two messages', platformChannelSpecifics);
  }
}
