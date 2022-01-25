import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/api.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:qqnotificationreply/utils/color_util.dart';

List<MsgBean> timedMsgs = []; // 需要显示的列表

class ChatListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _ChatListPageState();
  }
}

class _ChatListPageState extends State<ChatListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  var eventBusFn;
  FocusNode fastReplyFocusNode;
  Map<int, TextEditingController> replyControllers = {};

  @override
  void initState() {
    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.messageRaw) {
        messageReceived(event.data);
      } else if (event.event == Event.refreshState) {
        if (mounted) {
          setState(() {});
        }
      } else if (event.event == Event.groupMember) {
        if (mounted) {
          setState(() {});
        }
      } else if (event.event == Event.newChat) {
        if (mounted) {
          messageReceived(event.data);
        }
      }
    });

    G.rt.chatObjList = timedMsgs; // 这个应该是传引用吧

    fastReplyFocusNode = new FocusNode();

    super.initState();
  }

  Widget _buildChatListView(BuildContext context) {
    DateTime currentDay = DateTime.now();
    int currentTimestamp = currentDay.millisecondsSinceEpoch;

    // 填充空白
    if (timedMsgs.length == 0) {
      return new Center(
        child: new Text('没有会话',
            style: TextStyle(fontSize: 20, color: Colors.grey)),
      );
    }

    // 构建消息列表
    return ListView.builder(
        shrinkWrap: true,
        itemCount: timedMsgs.length,
        itemBuilder: (context, index) {
          MsgBean msg = timedMsgs[index];
          // 设置消息主体
          String titleStr;
          String subTitleStr;
          String headerUrl;
          if (msg.isGroup()) {
            titleStr = G.st.getLocalNickname(msg.keyId(), msg.groupName);
            String name;
            if (msg.action == MessageType.Message) {
              name = msg.senderId == null
                  ? ''
                  : G.st.getLocalNickname(
                          msg.senderKeyId(), msg.usernameSimplify() ?? '') +
                      ": ";
            }
            subTitleStr = (name ?? '') + G.cs.getMessageDisplay(msg);
            headerUrl = API.groupHeader(msg.groupId);
          } else {
            titleStr = G.st.getLocalNickname(msg.keyId(), msg.username());
            subTitleStr = G.cs.getMessageDisplay(msg);
            headerUrl = API.userHeader(msg.friendId);
          }

          Widget subTitleWidget;
          if (!G.st.enableChatListHistories) {
            // 只显示最近一条消息
          } else {
            // 显示多条未读消息
            List<MsgBean> msgs = G.ac.allMessages[msg.keyId()];
            // 如果最后一条是自己发的，那么只显示自己的
            if (msgs != null &&
                msgs.length > 0 &&
                msgs.last.senderId != G.ac.myId) {
              List<Widget> widgets = [];
              int maxCount = G.st.chatListHistoriesCount; // 最大显示几条消息
              int count = 0;
              for (int i = msgs.length - 1;
                  i >= 0 && count < maxCount;
                  i--, count++) {
                MsgBean msg = msgs[i];
                if (msg.senderId == G.ac.myId) {
                  break;
                }

                // 显示消息
                String text;
                if (msg.isPrivate()) {
                  // 私聊消息，只显示消息
                  text = G.cs.getMessageDisplay(msg);
                } else if (msg.isGroup()) {
                  if (msg.action == MessageType.Message) {
                    // 群聊还是需要显示昵称的
                    if (msg.senderId != null) {
                      String nickname =
                          G.st.getLocalNickname(msg.senderKeyId(), null) ??
                              msg.usernameSimplify();
                      if (nickname != null) {
                        text = nickname + ": " + G.cs.getMessageDisplay(msg);
                      }
                    }
                  } else {
                    text = G.cs.getMessageDisplay(msg);
                  }
                } else {
                  print('未知的消息类型');
                }
                if (text != null) {
                  if (widgets.length > 0) {
                    widgets.insert(0, SizedBox(height: 6));
                  }
                  widgets.insert(0, Text(text, maxLines: 3));
                }
              }
              widgets.insert(0, SizedBox(height: 3));
              subTitleWidget = Column(
                  children: widgets,
                  crossAxisAlignment: CrossAxisAlignment.start);
            }
          }
          if (subTitleWidget == null) {
            // 不需要多条消息，直接显示最后一条
            subTitleWidget = Text(subTitleStr, maxLines: 3);
          }

          // 时间
          String timeStr;
          DateTime dt = DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
          int delta = currentTimestamp - msg.timestamp;
          if (delta > 3600 * 24 * 1000) {
            // 超过24小时，显示日月
            timeStr = formatDate(dt, ['mm', '-', 'dd', ' ', 'HH', ':', 'nn']);
          } else if (delta < 15000) {
            // 15秒内
            timeStr = '刚刚';
          } else if (dt.day == currentDay.day) {
            // 今天
            timeStr = formatDate(dt, ['HH', ':', 'nn']);
          } else {
            // 昨天
            timeStr = "昨天 " + formatDate(dt, ['HH', ':', 'nn']);
          }

          // 侧边
          List<Widget> tailWidgets = [
            Text(timeStr, key: ValueKey(msg.timestamp))
          ];
          int unreadCount = 0;
          if (G.ac.unreadMessageCount.containsKey(msg.keyId())) {
            unreadCount = G.ac.unreadMessageCount[msg.keyId()];
          }
          if (unreadCount > 0) {
            Color c = Colors.blue; // 重要消息：红色
            bool showNum = true;
            if (msg.isGroup()) {
              if (G.st.importantGroups.contains(msg.groupId)) {
                // 重要群组，也是红色
                c = Colors.blue;
              } else if (G.st.enabledGroups.contains(msg.groupId)) {
                // 通知群组，橙色
                c = Colors.grey;
              } else {
                // 不通知的群组，淡蓝色
                c = Colors.grey;
                showNum = false;
              }
            }

            // 添加未读消息计数
            Widget container;
            if (showNum) {
              container = new Container(
                padding: EdgeInsets.all(2),
                decoration: new BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: new Text(
                  unreadCount.toString(), //通知数量
                  style: new TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              // 只添加一个点
              container = new Container(
                  padding: EdgeInsets.all(2),
                  margin: EdgeInsets.all(6),
                  decoration: new BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 8,
                    minHeight: 8,
                  ),
                  child: SizedBox());
            }

            tailWidgets.add(container);
          }

          Widget gd = InkWell(
              radius: 5,
              child: Column(
                  children: tailWidgets,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end),
              onTap: G.st.enableChatListReply
                  ? () {
                      showReplyInChatList(msg);
                    }
                  : null);

          // 消息内容
          List<Widget> bodyWidgets = [];
          bodyWidgets.add(ListTile(
            leading: new ClipOval(
              // 圆形头像
              child: new FadeInImage.assetNetwork(
                placeholder: "assets/icons/default_header.png",
                //预览图
                fit: BoxFit.contain,
                image: headerUrl,
                width: 40.0,
                height: 40.0,
                placeholderErrorBuilder: (context, error, stackTrace) {
                  return Text('Null');
                },
              ),
            ),
            title: Text(titleStr ?? "Error Title"),
            subtitle: subTitleWidget,
            trailing: gd,
            onTap: () {
              // 清除未读消息
              setState(() {
                G.ac.clearUnread(msg);
              });

              // 打开会话
              G.rt.showChatPage(msg, directlyClose: false);
            },
          ));

          // 显示快速回复框
          if (G.st.enableChatListReply &&
              G.ac.chatListShowReply.containsKey(msg.keyId())) {
            if (!replyControllers.containsKey(msg.keyId())) {
              print('create reply controller when null');
              replyControllers[msg.keyId()] = TextEditingController();
            }
            TextEditingController controller = replyControllers[msg.keyId()];
            print('initinitnitnit:' + controller.text);
            bodyWidgets.add(new Container(
              child: new TextField(
                autofocus: true, // 不加的话每次setState都会失去焦点
                // focusNode: fastReplyFocusNode,
                controller: controller,
                key: ValueKey(msg.keyId().toString() + "_reply"),
                onSubmitted: (String text) {
                  if (text.isEmpty) {
                    return;
                  }

                  // 发送
                  G.cs.sendMsg(msg, text);
                  controller.text = '';

                  if (G.st.chatListReplySendHide) {
                    // 自动隐藏
                    showReplyInChatList(msg);
                  } else {
                    // 继续聚焦（onSubmit会导致失去焦点）
                    // FocusScope.of(context).requestFocus(fastReplyFocusNode);
                  }
                },
                decoration: new InputDecoration.collapsed(hintText: '快速回复'),
              ),
              margin: EdgeInsets.only(left: 32, right: 32, bottom: 10),
            ));
          }

          // 显示状态
          bool showingChat = G.rt.horizontal &&
              G.rt.currentChatPage != null &&
              G.rt.currentChatPage.chatObj.isObj(msg);

          Color cardBg = Color(0xFFEEEEEE);
          if (G.st.enableColorfulChatList) {
            if (G.ac.chatObjColor.containsKey(msg.keyId())) {
              cardBg = ColorUtil.fixedLight(
                  G.ac.chatObjColor[msg.keyId()], G.st.colorfulChatListBg);
            } else if (!G.ac.gettingChatObjColor.contains(msg.keyId())) {
              _getChatObjColor(msg);
            }
          }

          // 单条消息的外部容器
          return new Dismissible(
            child: new Container(
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
              child: new Card(
                color: cardBg,
                // 背景颜色
                elevation: 0.0,
                // 投影
                child: Column(children: bodyWidgets),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    //设定 Card 的倒角大小
                    /* borderRadius: BorderRadius.only(
                  //设定 Card 的每个角的倒角大小
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.zero,
                  bottomLeft: Radius.zero,
                  bottomRight: Radius.circular(20.0)),*/
                    side: showingChat
                        ? BorderSide(
                            color: G.st.enableColorfulChatList &&
                                    G.ac.chatObjColor.containsKey(msg.keyId())
                                ? ColorUtil.fixedLight(
                                    G.ac.chatObjColor[msg.keyId()],
                                    G.st.colorfulChatListSelecting)
                                : Theme.of(context).primaryColor,
                            width: 1)
                        : BorderSide.none),
                // 设置边框
                clipBehavior:
                    Clip.antiAlias, //对Widget截取的行为，比如这里 Clip.antiAlias 指抗锯齿
              ),
            ),
            onDismissed: (_) {
              // 左右滑动删除
              setState(() {
                timedMsgs.removeAt(index);
              });
            },
            key: Key(msg.keyId().toString()),
          );
        });
  }

  @override
  // ignore: must_call_super
  Widget build(BuildContext context) {
    return _buildChatListView(context);
  }

  /// 收到消息
  void messageReceived(MsgBean msg) {
    // 时间队列置顶
    for (int i = 0; i < timedMsgs.length; i++) {
      if (timedMsgs[i].isObj(msg)) {
        timedMsgs.removeAt(i);
        break;
      }
    }
    timedMsgs.insert(0, msg);

    // 设置未读数量
    if (G.rt.updateChatPageUnreadCount != null) {
      G.rt.updateChatPageUnreadCount();
    } else {
      print('warning: G.rt.updateChatPageUnreadCount == null');
    }

    // 设置主题色
    /* if (G.st.enableColorfulChatList &&
        !G.ac.chatObjColor.containsKey(msg.keyId()) &&
        !G.ac.gettingChatObjColor.contains(msg.keyId())) {
      _getChatObjColor(msg);
    } */

    // 判断是否已经释放
    if (!mounted) {
      // 不判断的话，会报错：setState() called after dispose():
      return;
    }

    setState(() {});
  }

  void _getChatObjColor(MsgBean msg) {
    G.ac.gettingChatObjColor.add(msg.keyId());
    String url = API.chatObjHeader(msg);
    getColorFromUrl(url).then((v) {
      print('主题色：' + msg.title() + ": " + v.toString());
      G.ac.gettingChatObjColor.remove(msg.keyId());
      setState(() {
        Color c = Color.fromARGB(255, v[0], v[1], v[2]);
        G.ac.chatObjColor[msg.keyId()] = c;
      });
    });
  }

  /// 在聊天列表界面就显示回复框
  void showReplyInChatList(MsgBean msg) {
    setState(() {
      if (G.ac.chatListShowReply.containsKey(msg.keyId())) {
        G.ac.chatListShowReply.remove(msg.keyId());
        replyControllers.remove(msg.keyId());
      } else {
        replyControllers[msg.keyId()] = TextEditingController();
        G.ac.chatListShowReply[msg.keyId()] = true;
      }
    });
  }
}
