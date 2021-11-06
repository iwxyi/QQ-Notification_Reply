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
              '会话列表',
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
                    Icons.reply_all,
                    color: Colors.blue,
                  ),
                  title: Text('快速回复'),
                  subtitle: Text('会话列表中点击右边的时间显示快速回复框'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableChatListReply = !G.st.enableChatListReply;
                        G.st.setConfig('display/chatListReply',
                            G.st.enableChatListReply);
                      });
                    },
                    value: G.st.enableChatListReply,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableChatListReply = !G.st.enableChatListReply;
                      G.st.setConfig('display/chatListReply',
                          G.st.enableChatListReply);
                    });
                  },
                ),],
            ),
          ),
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
                        G.st.setConfig('display/showRecursionReply',
                            G.st.showRecursionReply);
                      });
                    },
                    value: G.st.showRecursionReply,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.showRecursionReply = !G.st.showRecursionReply;
                      G.st.setConfig('display/showRecursionReply',
                          G.st.showRecursionReply);
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
