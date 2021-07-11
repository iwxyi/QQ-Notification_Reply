import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/pages/group_list_widget.dart';

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
                      return GroupListWidget();
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
    Person person = new Person(
        bot: false, important: true, name: 'name', uri: 'http://baidu.com');
    Person person2 = new Person(
        bot: false, important: true, name: 'suyu', uri: 'http://baidu.com');
    List<Message> messages = [
      new Message('textextextext', DateTime.now(), person),
      new Message('hhhhhhhhhhhhh', DateTime.now(), person),
      new Message('aaaaaaaaaaaaaaaa', DateTime.now(), person2),
      new Message('qweqweqweqwe', DateTime.now(), person2)
    ];

    MessagingStyleInformation messagingStyleInformation =
        new MessagingStyleInformation(person,
            conversationTitle: 'Title', messages: messages);

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'groupChannelId', 'groupChannelName', 'groupChannelDescription',
            styleInformation: messagingStyleInformation,
            groupKey: 'groupKey',
            priority: Priority.high,
            setAsGroupSummary: true,
            importance: Importance.max);

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await UserAccount.flutterLocalNotificationsPlugin
        .show(0, 'Attention', 'Two messages', platformChannelSpecifics);
  }
}
