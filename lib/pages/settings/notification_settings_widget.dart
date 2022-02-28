import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/pages/settings/group_select_widget.dart';

class NotificationSettingsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends State<NotificationSettingsWidget> {
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
                    Icons.group,
                    color: Colors.blue,
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
                ListTile(
                  leading: Icon(
                    Icons.chat,
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
                    Icons.center_focus_strong,
                    color: Colors.blue,
                  ),
                  title: Text('群消息智能聚焦'),
                  subtitle: Text('发送疑问句或者@别人的消息后，提升群组至“重要”，直到下一次进入会话'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.groupSmartFocus = !G.st.groupSmartFocus;
                        G.st.setConfig('notification/groupSmartFocus',
                            G.st.groupSmartFocus);
                      });
                    },
                    value: G.st.groupSmartFocus,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.groupSmartFocus = !G.st.groupSmartFocus;
                      G.st.setConfig(
                          'notification/groupSmartFocus', G.st.groupSmartFocus);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.notification_important,
                    color: Colors.blue,
                  ),
                  title: Text('群消息动态重要性'),
                  subtitle: Text('自己在低通知级别的群里发消息，一分钟内提升至重要，三分钟内显示通知'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.groupDynamicImportance =
                            !G.st.groupDynamicImportance;
                        G.st.setConfig('notification/groupDynamicImportance',
                            G.st.groupDynamicImportance);
                      });
                    },
                    value: G.st.groupDynamicImportance,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.groupDynamicImportance =
                          !G.st.groupDynamicImportance;
                      G.st.setConfig('notification/groupDynamicImportance',
                          G.st.groupDynamicImportance);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.select_all,
                    color: Colors.blue,
                  ),
                  title: Text('显示“@全体成员”通知'),
                  subtitle: Text('将“@全体成员”视作和“@我”相同重要性，关闭则忽视'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.notificationAtAll = !G.st.notificationAtAll;
                        G.st.setConfig(
                            'notification/atAll', G.st.notificationAtAll);
                      });
                    },
                    value: G.st.notificationAtAll,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.notificationAtAll = !G.st.notificationAtAll;
                      G.st.setConfig(
                          'notification/atAll', G.st.notificationAtAll);
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
                    Icons.remove_circle,
                    color: Colors.blue,
                  ),
                  title: Text('通知同步'),
                  subtitle: Text('通知被移除时标记为已读'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.removeUnreadOnDismissNotification =
                            !G.st.removeUnreadOnDismissNotification;
                        G.st.setConfig(
                            'notification/removeUnreadOnDismissNotification',
                            G.st.removeUnreadOnDismissNotification);
                      });
                    },
                    value: G.st.removeUnreadOnDismissNotification,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.removeUnreadOnDismissNotification =
                          !G.st.removeUnreadOnDismissNotification;
                      G.st.setConfig(
                          'notification/removeUnreadOnDismissNotification',
                          G.st.removeUnreadOnDismissNotification);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.golf_course,
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
                    Icons.no_cell,
                    color: Colors.blue,
                  ),
                  title: Text('暂停通知'),
                  subtitle: Text('通过其他设备发送消息后暂停本设备的通知，直至下次打开本程序'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableNotificationSleep =
                            !G.st.enableNotificationSleep;
                        G.st.setConfig('notification/enableNotificationSleep',
                            G.st.enableNotificationSleep);
                      });
                    },
                    value: G.st.enableNotificationSleep,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableNotificationSleep =
                          !G.st.enableNotificationSleep;
                      G.st.setConfig('notification/enableNotificationSleep',
                          G.st.enableNotificationSleep);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.text_fields_sharp,
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
    simulateChatConversation(groupKey: 'jhonny_group');
  }

  int createUniqueID(int maxValue) {
    Random random = new Random();
    return random.nextInt(maxValue);
  }

  Future<void> createMessagingNotification(
      {@required String channelKey,
      @required String groupKey,
      @required String chatName,
      @required String username,
      @required String message,
      String largeIcon,
      bool checkPermission = true}) async {
    /* await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: createUniqueID(AwesomeNotifications.maxID),
            groupKey: groupKey,
            channelKey: channelKey,
            summary: chatName,
            title: username,
            body: message,
            largeIcon: largeIcon,
            notificationLayout: NotificationLayout.Messaging),
        actionButtons: [
          NotificationActionButton(
            key: 'REPLY',
            label: 'Reply',
            // buttonType: ActionButtonType.InputField,
          ),
          NotificationActionButton(
            key: 'READ',
            label: 'Mark as Read',
            // buttonType: ActionButtonType.InputField,
          )
        ]); */
  }

  int _messageIncrement = 0;

  Future<void> simulateChatConversation({@required String groupKey}) async {
    _messageIncrement++ % 4 < 2
        ? createMessagingNotification(
            channelKey: 'important_group_chats',
            groupKey: groupKey,
            chatName: 'Jhonny\'s Group',
            username: 'Jhonny',
            largeIcon: 'asset://assets/images/80s-disc.jpg',
            message: 'Jhonny\'s message $_messageIncrement',
          )
        : createMessagingNotification(
            channelKey: 'important_group_chats',
            groupKey: 'jhonny_group',
            chatName: 'Michael\'s Group',
            username: 'Michael',
            largeIcon: 'asset://assets/images/dj-disc.jpg',
            message: 'Michael\'s message $_messageIncrement',
          );
  }
}
