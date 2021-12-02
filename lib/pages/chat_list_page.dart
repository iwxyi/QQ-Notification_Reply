import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

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

  @override
  void initState() {
    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.messageRaw) {
        messageReceived(event.data);
      } else if (event.event == Event.refreshState) {
        if (mounted) {
          // 这里报错了，但实际上也是能用
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
          // 设置用户数据
          String title;
          String subTitle;
          String headerUrl;
          if (msg.isGroup()) {
            title = G.st.getLocalNickname(msg.keyId(), msg.groupName);
            subTitle =
                G.st.getLocalNickname(msg.senderKeyId(), msg.username()) +
                    ": " +
                    G.cs.getMessageDisplay(msg);
            headerUrl =
                "http://p.qlogo.cn/gh/${msg.groupId}/${msg.groupId}/100";
          } else {
            title = G.st.getLocalNickname(msg.keyId(), msg.username());
            subTitle = G.cs.getMessageDisplay(msg);
            headerUrl = "http://q1.qlogo.cn/g?b=qq&nk=${msg.friendId}&s=100&t=";
          }

          // 时间
          String timeStr;
          DateTime dt = DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
          int delta = currentTimestamp - msg.timestamp;
          if (delta > 3600 * 24 * 1000) {
            // 超过24小时
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
                ),
              ),
              title: Text(title),
              subtitle: Text(subTitle, maxLines: 3),
              trailing: gd,
              onTap: () {
                // 清除未读消息
                setState(() {
                  G.ac.clearUnread(msg);
                });

                // 打开会话
                G.rt.showChatPage(msg);
              },
              onLongPress: () {
                // 会话菜单
              }));

          // 显示快速回复框
          if (G.st.enableChatListReply &&
              G.ac.chatListShowReply.containsKey(msg.keyId())) {
            bodyWidgets.add(new Container(
              child: new TextField(
                onSubmitted: (String text) {
                  if (msg.isPrivate()) {
                    G.cs.sendPrivateMessage(msg.friendId, text);
                  } else if (msg.isGroup()) {
                    G.cs.sendGroupMessage(msg.groupId, text);
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

          // 单条消息的外部容器
          return new Dismissible(
            child: new Container(
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
              child: new Card(
                color: Color(0xFFEEEEEE),
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
                            color: Theme.of(context).primaryColor, width: 1)
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

    // 判断是否已经释放
    if (!mounted) {
      // 不判断的话，会报错：setState() called after dispose():
      return;
    }
    setState(() {});
  }

  /// 在聊天列表界面就显示回复框
  void showReplyInChatList(MsgBean msg) {
    setState(() {
      if (G.ac.chatListShowReply.containsKey(msg.keyId())) {
        G.ac.chatListShowReply.remove(msg.keyId());
      } else {
        G.ac.chatListShowReply[msg.keyId()] = true;
      }
    });
  }
}
