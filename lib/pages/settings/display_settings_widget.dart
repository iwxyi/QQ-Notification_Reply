import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';

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
                        G.st.setConfig(
                            'function/chatListReply', G.st.enableChatListReply);
                        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                      });
                    },
                    value: G.st.enableChatListReply,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableChatListReply = !G.st.enableChatListReply;
                      G.st.setConfig(
                          'function/chatListReply', G.st.enableChatListReply);
                      G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.hide_source,
                    color: Colors.blue,
                  ),
                  title: Text('发送后隐藏'),
                  subtitle: Text('通过快速回复发送消息后自动隐藏'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.chatListReplySendHide =
                            !G.st.chatListReplySendHide;
                        G.st.setConfig('function/chatListReplySendHide',
                            G.st.chatListReplySendHide);
                        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                      });
                    },
                    value: G.st.chatListReplySendHide,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.chatListReplySendHide = !G.st.chatListReplySendHide;
                      G.st.setConfig('function/chatListReplySendHide',
                          G.st.chatListReplySendHide);
                      G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.multiline_chart,
                    color: Colors.blue,
                  ),
                  title: Text('多条历史'),
                  subtitle: Text('会话列表显示多条未读记录'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableChatListHistories =
                            !G.st.enableChatListHistories;
                        G.st.setConfig('function/chatListHistories',
                            G.st.enableChatListHistories);
                        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                      });
                    },
                    value: G.st.enableChatListHistories,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableChatListHistories =
                          !G.st.enableChatListHistories;
                      G.st.setConfig('function/chatListHistories',
                          G.st.enableChatListHistories);
                      G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.multiline_chart,
                    color: Colors.blue,
                  ),
                  title: Text('卡片列表'),
                  subtitle: Text('每条记录使用圆角矩形包裹'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableChatListRoundedRect =
                            !G.st.enableChatListRoundedRect;
                        G.st.setConfig('display/enableChatListRoundedRect',
                            G.st.enableChatListRoundedRect);
                        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                      });
                    },
                    value: G.st.enableChatListRoundedRect,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableChatListRoundedRect =
                          !G.st.enableChatListRoundedRect;
                      G.st.setConfig('display/enableChatListRoundedRect',
                          G.st.enableChatListRoundedRect);
                      G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.multiline_chart,
                    color: Colors.blue,
                  ),
                  title: Text('宽松列表'),
                  subtitle: Text('增加卡片留空，一般和上一项同时开启'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableChatListLoose = !G.st.enableChatListLoose;
                        G.st.setConfig('display/enableChatListLoose',
                            G.st.enableChatListLoose);
                        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                      });
                    },
                    value: G.st.enableChatListLoose,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableChatListLoose = !G.st.enableChatListLoose;
                      G.st.setConfig('display/enableChatListLoose',
                          G.st.enableChatListLoose);
                      G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.multiline_chart,
                    color: Colors.blue,
                  ),
                  title: Text('单行消息'),
                  subtitle: Text('预览的消息只显示一行（默认最多3行）'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableMessagePreviewSingleLine =
                            !G.st.enableMessagePreviewSingleLine;
                        G.st.setConfig('display/enableMessagePreviewSingleLine',
                            G.st.enableMessagePreviewSingleLine);
                        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                      });
                    },
                    value: G.st.enableMessagePreviewSingleLine,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableMessagePreviewSingleLine =
                          !G.st.enableMessagePreviewSingleLine;
                      G.st.setConfig('display/enableMessagePreviewSingleLine',
                          G.st.enableMessagePreviewSingleLine);
                      G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                    });
                  },
                ),
              ],
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
                ListTile(
                  leading: Icon(
                    Icons.keyboard_return,
                    color: Colors.blue,
                  ),
                  title: Text('回车发送'),
                  subtitle: Text('横屏模式中使用单行回车还是多行Ctrl+回车发送'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.inputEnterSend = !G.st.inputEnterSend;
                        G.st.setConfig(
                            'display/inputEnterSend', G.st.inputEnterSend);
                      });
                    },
                    value: G.st.inputEnterSend,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.inputEnterSend = !G.st.inputEnterSend;
                      G.st.setConfig(
                          'display/inputEnterSend', G.st.inputEnterSend);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.switch_account,
                    color: Colors.blue,
                  ),
                  title: Text('快速切换'),
                  subtitle: Text('聊天页面中显示所有会话头像，点击切换'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableQuickSwitcher = !G.st.enableQuickSwitcher;
                        G.st.setConfig('function/enableQuickSwitcher',
                            G.st.enableQuickSwitcher);
                      });
                    },
                    value: G.st.enableQuickSwitcher,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableQuickSwitcher = !G.st.enableQuickSwitcher;
                      G.st.setConfig('function/enableQuickSwitcher',
                          G.st.enableQuickSwitcher);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.multiline_chart,
                    color: Colors.blue,
                  ),
                  title: Text('宽松列表'),
                  subtitle: Text('留白更大的聊天界面'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableChatBubbleLoose =
                            !G.st.enableChatBubbleLoose;
                        G.st.setConfig('display/enableChatBubbleLoose',
                            G.st.enableChatBubbleLoose);
                        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                      });
                    },
                    value: G.st.enableChatBubbleLoose,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableChatBubbleLoose = !G.st.enableChatBubbleLoose;
                      G.st.setConfig('display/enableChatBubbleLoose',
                          G.st.enableChatBubbleLoose);
                      G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.multiline_chart,
                    color: Colors.blue,
                  ),
                  title: Text('卡片背景'),
                  subtitle: Text('使用大圆角矩形包括聊天区域'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableChatWidgetRoundedRect =
                            !G.st.enableChatWidgetRoundedRect;
                        G.st.setConfig('display/enableChatWidgetRoundedRect',
                            G.st.enableChatWidgetRoundedRect);
                        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                      });
                    },
                    value: G.st.enableChatWidgetRoundedRect,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableChatWidgetRoundedRect =
                          !G.st.enableChatWidgetRoundedRect;
                      G.st.setConfig('display/enableChatWidgetRoundedRect',
                          G.st.enableChatWidgetRoundedRect);
                      G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '彩色',
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
                    Icons.list,
                    color: Colors.blue,
                  ),
                  title: Text('会话列表'),
                  subtitle: Text('会话列表使用头像主题色作为背景颜色'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableColorfulChatList =
                            !G.st.enableColorfulChatList;
                        G.st.setConfig('display/enableColorfulChatList',
                            G.st.enableColorfulChatList);
                      });
                    },
                    value: G.st.enableColorfulChatList,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableColorfulChatList =
                          !G.st.enableColorfulChatList;
                      G.st.setConfig('display/enableColorfulChatList',
                          G.st.enableColorfulChatList);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.card_membership,
                    color: Colors.blue,
                  ),
                  title: Text('聊天昵称'),
                  subtitle: Text('聊天昵称使用头像主题色作为字体颜色'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableColorfulChatName =
                            !G.st.enableColorfulChatName;
                        G.st.setConfig('display/enableColorfulChatName',
                            G.st.enableColorfulChatName);
                      });
                    },
                    value: G.st.enableColorfulChatName,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableColorfulChatName =
                          !G.st.enableColorfulChatName;
                      G.st.setConfig('display/enableColorfulChatName',
                          G.st.enableColorfulChatName);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.chat_bubble,
                    color: Colors.blue,
                  ),
                  title: Text('聊天气泡'),
                  subtitle: Text('聊天气泡使用头像主题色作为背景颜色'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableColorfulChatBubble =
                            !G.st.enableColorfulChatBubble;
                        G.st.setConfig('display/enableColorfulChatBubble',
                            G.st.enableColorfulChatBubble);
                      });
                    },
                    value: G.st.enableColorfulChatBubble,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableColorfulChatBubble =
                          !G.st.enableColorfulChatBubble;
                      G.st.setConfig('display/enableColorfulChatBubble',
                          G.st.enableColorfulChatBubble);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.reply,
                    color: Colors.blue,
                  ),
                  title: Text('回复气泡'),
                  subtitle: Text('回复的背景使用聊天气泡颜色'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableColorfulReplyBubble =
                            !G.st.enableColorfulReplyBubble;
                        G.st.setConfig('display/enableColorfulReplyBubble',
                            G.st.enableColorfulReplyBubble);
                      });
                    },
                    value: G.st.enableColorfulReplyBubble,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableColorfulReplyBubble =
                          !G.st.enableColorfulReplyBubble;
                      G.st.setConfig('display/enableColorfulReplyBubble',
                          G.st.enableColorfulReplyBubble);
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.tv,
                    color: Colors.blue,
                  ),
                  title: Text('窗口背景'),
                  subtitle: Text('窗口背景使用头像主题色作为背景颜色（不好看）'),
                  trailing: Checkbox(
                    onChanged: (bool val) {
                      setState(() {
                        G.st.enableColorfulBackground =
                            !G.st.enableColorfulBackground;
                        G.st.setConfig('display/enableColorfulBackground',
                            G.st.enableColorfulBackground);
                      });
                    },
                    value: G.st.enableColorfulBackground,
                  ),
                  onTap: () {
                    setState(() {
                      G.st.enableColorfulBackground =
                          !G.st.enableColorfulBackground;
                      G.st.setConfig('display/enableColorfulBackground',
                          G.st.enableColorfulBackground);
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
