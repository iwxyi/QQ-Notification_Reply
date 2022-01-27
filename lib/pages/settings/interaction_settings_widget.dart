import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';

class InteractionSettingsWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InteractionSettingsWidgetState();
}

class _InteractionSettingsWidgetState extends State<InteractionSettingsWidget> {
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
              '补充',
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
                    Icons.remove_red_eye,
                    color: Colors.blue,
                  ),
                  title: Text('胡说八道模式'),
                  subtitle: Text('自由编辑消息文字、发送假消息（后果自负）'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableNonsenseMode = !G.st.enableNonsenseMode;
                        G.st.setConfig('function/enableNonsenseMode',
                            G.st.enableNonsenseMode);
                      });
                    },
                    value: G.st.enableNonsenseMode,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableNonsenseMode = !G.st.enableNonsenseMode;
                      G.st.setConfig('function/enableNonsenseMode',
                          G.st.enableNonsenseMode);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.reply_all,
                    color: Colors.blue,
                  ),
                  title: Text('发送群表情包'),
                  subtitle: Text('群聊中的表情包使用网络图片的形式发送（账号被风控发不了群表情包）'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableEmojiToImage = !G.st.enableEmojiToImage;
                        G.st.setConfig('function/enableEmojiToImage',
                            G.st.enableEmojiToImage);
                      });
                    },
                    value: G.st.enableEmojiToImage,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableEmojiToImage = !G.st.enableEmojiToImage;
                      G.st.setConfig('function/enableEmojiToImage',
                          G.st.enableEmojiToImage);
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
                    Icons.bug_report,
                    color: Colors.blue,
                  ),
                  title: Text('调试模式'),
                  subtitle: Text('输出一些调试信息'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.debugMode = !G.st.debugMode;
                        G.st.setConfig('function/debugMode', G.st.debugMode);
                        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                      });
                    },
                    value: G.st.debugMode,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.debugMode = !G.st.debugMode;
                      G.st.setConfig('function/debugMode', G.st.debugMode);
                      G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
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
