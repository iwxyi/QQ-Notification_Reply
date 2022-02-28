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
                    Icons.architecture,
                    color: Colors.blue,
                  ),
                  title: Text('回复包含@'),
                  subtitle: Text('回复消息时@该用户'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableReplyWithAt = !G.st.enableReplyWithAt;
                        G.st.setConfig('function/enableReplyWithAt',
                            G.st.enableReplyWithAt);
                      });
                    },
                    value: G.st.enableReplyWithAt,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableReplyWithAt = !G.st.enableReplyWithAt;
                      G.st.setConfig(
                          'function/enableReplyWithAt', G.st.enableReplyWithAt);
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '手势',
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
                    Icons.horizontal_rule,
                    color: Colors.blue,
                  ),
                  title: Text('左右滑动'),
                  subtitle: Text('聊天页面横向滑动的手势更改为切换聊天对象'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableHorizontalSwitch =
                            !G.st.enableHorizontalSwitch;
                        G.st.setConfig('function/enableHorizontalSwitch',
                            G.st.enableHorizontalSwitch);
                      });
                    },
                    value: G.st.enableHorizontalSwitch,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableHorizontalSwitch =
                          !G.st.enableHorizontalSwitch;
                      G.st.setConfig('function/enableHorizontalSwitch',
                          G.st.enableHorizontalSwitch);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.keyboard,
                    color: Colors.blue,
                  ),
                  title: Text('滑动隐藏键盘'),
                  subtitle: Text('聊天页面下拉时隐藏输入法键盘'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.hideKeyboardOnSlide = !G.st.hideKeyboardOnSlide;
                        G.st.setConfig('function/hideKeyboardOnSlide',
                            G.st.hideKeyboardOnSlide);
                      });
                    },
                    value: G.st.hideKeyboardOnSlide,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.hideKeyboardOnSlide = !G.st.hideKeyboardOnSlide;
                      G.st.setConfig('function/hideKeyboardOnSlide',
                          G.st.hideKeyboardOnSlide);
                    });
                  },
                ),
              ],
            ),
          ),
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
                ListTile(
                  leading: Icon(
                    Icons.bug_report,
                    color: Colors.blue,
                  ),
                  title: Text('禁止风险操作'),
                  subtitle: Text('禁止一些产生bug、不稳定的操作，如可能会导致账号被冻结的发送非好友消息'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.disableDangerousAction =
                            !G.st.disableDangerousAction;
                        G.st.setConfig('function/disableDangerousAction',
                            G.st.disableDangerousAction);
                        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                      });
                    },
                    value: G.st.disableDangerousAction,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.disableDangerousAction =
                          !G.st.disableDangerousAction;
                      G.st.setConfig('function/disableDangerousAction',
                          G.st.disableDangerousAction);
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
