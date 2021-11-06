import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/pages/settings/group_select_widget.dart';

class DisplaySettingsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DisplaySettingsWidgetState();
}

class _DisplaySettingsWidgetState extends State<DisplaySettingsWidget> {
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
                  title: Text('多重回复'),
                  subtitle: Text('回复中再显示回复的内容'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.showRecursionReply = !G.st.showRecursionReply;
                        G.st.setConfig(
                            'display/showRecursionReply', G.st.showRecursionReply);
                      });
                    },
                    value: G.st.showRecursionReply,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.showRecursionReply = !G.st.showRecursionReply;
                      G.st.setConfig(
                          'display/showRecursionReply', G.st.showRecursionReply);
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
        ],
      ),
    );
  }

}
