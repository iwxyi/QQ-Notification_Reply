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

          List<Widget> titleWidgets = [Text(titleStr ?? "Error Title")];
          if (msg.isGroup()) {
            double spacing = 8;
            if (G.ac.atMeGroups.contains(msg.groupId)) {
              titleWidgets.add(SizedBox(width: spacing));
              titleWidgets
                  .add(Text('[@我]', style: TextStyle(color: Colors.orange)));
            }
            if (G.ac.replyMeGroups.contains(msg.groupId)) {
              titleWidgets.add(SizedBox(width: spacing));
              titleWidgets
                  .add(Text('[回复]', style: TextStyle(color: Colors.orange)));
            }
          }

          Widget subTitleWidget;
          if (!G.st.enableChatListHistories) {
            // 只显示最近一条消息
          } else {
            // 显示多条未读消息
            // 如果最后一条是自己发的，则显示0条消息，即返回值为null
            subTitleWidget = _buildItemMultipleSubtitleWidget(msg);
          }
          if (subTitleWidget == null) {
            // 只显示一条消息
            subTitleWidget = Text(subTitleStr,
                maxLines: G.st.enableMessagePreviewSingleLine ? 1 : 3);
          }

          // 时间
          DateTime dt = DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
          String timeStr = getTimeDeltaString(dt);

          // 侧边
          List<Widget> tailWidgets = [
            Text(timeStr, key: ValueKey(msg.timestamp))
          ];
          int unreadCount = 0;
          if (G.ac.unreadMessageCount.containsKey(msg.keyId())) {
            unreadCount = G.ac.unreadMessageCount[msg.keyId()];
          }
          if (unreadCount > 0) {
            tailWidgets.add(_buildItemUnreadCountPoint(msg, unreadCount));
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
            visualDensity: G.st.enableChatListLoose
                ? VisualDensity.standard
                : VisualDensity(horizontal: -4.0, vertical: -4.0),
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
            title: Row(children: titleWidgets),
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
            bodyWidgets.add(new Container(
              child: new TextField(
                autofocus: true,
                // 不加的话每次setState都会失去焦点
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

          Color cardBg;
          if (G.st.enableChatListRoundedRect || showingChat) {
            cardBg = Color(0xFFEEEEEE);
            if (G.st.enableColorfulChatList) {
              if (G.ac.chatObjColor.containsKey(msg.keyId())) {
                cardBg = ColorUtil.fixedLight(
                    G.ac.chatObjColor[msg.keyId()], G.st.colorfulChatListBg);
              } else if (!G.ac.gettingChatObjColor.contains(msg.keyId())) {
                _getChatObjColor(msg);
              }
            }
          } else {
            cardBg = Colors.transparent;
          }

          RoundedRectangleBorder border = RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(G.st.cardRadiusM)),
              side: showingChat && G.st.enableChatListRoundedRect
                  ? BorderSide(
                      color: G.st.enableColorfulChatList &&
                              G.ac.chatObjColor.containsKey(msg.keyId())
                          ? ColorUtil.fixedLight(G.ac.chatObjColor[msg.keyId()],
                              G.st.colorfulChatListSelecting)
                          : Theme.of(context).primaryColor,
                      width: 1)
                  : BorderSide.none);

          EdgeInsets margin;
          if (G.st.enableChatListRoundedRect) {
            // 显示卡片，需要多一些上下间距
            margin = EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0);
          } else {
            margin = EdgeInsets.only(left: 8, right: 8);
          }

          // 单条消息的外部容器
          return new Dismissible(
            child: new Container(
              padding: margin,
              child: new Card(
                color: cardBg,
                // 背景颜色
                elevation: 0.0,
                // 投影
                child: Column(children: bodyWidgets),
                shape: border,
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

  /// 每个item的多条消息
  Widget _buildItemMultipleSubtitleWidget(MsgBean msg) {
    List<MsgBean> msgs = G.ac.allMessages[msg.keyId()];
    // 如果最后一条是自己发的，那么只显示自己的
    if (msgs == null || msgs.length == 0) {
      return null;
    }
    if (msgs.last.isSelf) {
      return null;
    }
    List<Widget> widgets = [];
    int maxCount = G.st.chatListHistoriesCount; // 最大显示几条消息
    int count = 0;
    for (int i = msgs.length - 1; i >= 0 && count < maxCount; i--, count++) {
      MsgBean msg = msgs[i];
      if (msg.isSelf) {
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
            String nickname = G.st.getLocalNickname(msg.senderKeyId(), null) ??
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
        widgets.insert(0,
            Text(text, maxLines: G.st.enableMessagePreviewSingleLine ? 1 : 3));
      }
    }
    widgets.insert(0, SizedBox(height: 3));
    return Column(
        children: widgets, crossAxisAlignment: CrossAxisAlignment.start);
  }

  /// 获取未读消息的圆形控件
  /// 不重要的消息只有圆点，其他消息有不同颜色的数字
  Widget _buildItemUnreadCountPoint(MsgBean msg, int unreadCount) {
    Color c = Colors.blue;
    MessageImportance imp = G.cs.getMsgImportance(msg);
    bool showNum = true;
    if (msg.isGroup()) {
      if (imp == MessageImportance.Very) {
        c = Colors.red;
      } else if (imp == MessageImportance.Little) {
        // 重要群组
        c = Colors.blue;
      } else if (imp == MessageImportance.Normal) {
        // 通知群组
        c = Colors.grey;
      } else {
        // 不通知的群组，淡蓝色
        c = Colors.grey;
        showNum = false;
      }
    } else {
      // 好友
      c = Colors.blue;
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
    return container;
  }

  /// 获取目标时间与当前时间的差的字符串
  String getTimeDeltaString(DateTime comp) {
    DateTime curr = DateTime.now();
    int delta = curr.millisecondsSinceEpoch - comp.millisecondsSinceEpoch;
    if (delta > 3600 * 24 * 1000) {
      // 超过24小时，显示日月
      return formatDate(comp, ['mm', '-', 'dd', ' ', 'HH', ':', 'nn']);
    } else if (delta < 15000) {
      // 15秒内
      return '刚刚';
    } else if (comp.day == curr.day) {
      // 今天
      return formatDate(comp, ['HH', ':', 'nn']);
    } else {
      // 昨天
      return "昨天 " + formatDate(comp, ['HH', ':', 'nn']);
    }
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
