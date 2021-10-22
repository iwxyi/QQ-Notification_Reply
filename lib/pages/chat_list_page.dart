import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

import 'chat/chat_widget.dart';

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

  @override
  void initState() {
    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.messageRaw) {
        messageReceived(event.data);
      }
    });

    super.initState();
  }

  @override
  // ignore: must_call_super
  Widget build(BuildContext context) {
    DateTime currentDay = DateTime.now();
    int currentTimestamp = currentDay.millisecondsSinceEpoch;

    // 填充空白
    if (timedMsgs.length == 0) {
      return new Center(
        child: new Text('没有会话',
            style: TextStyle(fontSize: 20, color: Colors.grey)),
      );
    }

    return ListView.builder(
        shrinkWrap: false,
        itemCount: timedMsgs.length,
        itemBuilder: (context, index) {
          MsgBean msg = timedMsgs[index];
          // 设置用户数据
          String title;
          String subTitle;
          String headerUrl;
          if (msg.isGroup()) {
            title = msg.groupName;
            subTitle = msg.username() + ": " + G.cs.getMessageDisplay(msg);
            headerUrl =
                "http://p.qlogo.cn/gh/${msg.groupId}/${msg.groupId}/100";
          } else {
            title = msg.username();
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
            timeStr = formatDate(dt, ['HH', ':', 'mm']);
          } else {
            // 昨天
            timeStr = "昨天 " + formatDate(dt, ['HH', ':', 'nn']);
          }

          // 侧边
          List<Widget> tailWidgets = [Text(timeStr)];
          int unreadCount = 0;

          if (msg.isPrivate()) {
            if (G.ac.unreadPrivateCount.containsKey(msg.friendId)) {
              unreadCount = G.ac.unreadPrivateCount[msg.friendId];
            }
          } else if (msg.isGroup()) {
            if (G.ac.unreadGroupCount.containsKey(msg.groupId)) {
              unreadCount = G.ac.unreadGroupCount[msg.groupId];
            }
          }
          if (unreadCount > 0) {
            Color c = Colors.red; // 重要消息：红色
            if (msg.isGroup()) {
              if (G.st.importantGroups.contains(msg.groupId)) {
                // 重要群组，也是红色
                c = Colors.orange;
              } else if (G.st.enabledGroups.contains(msg.groupId)) {
                // 通知群组，橙色
                c = Colors.blue;
              } else {
                // 不通知的群组，淡蓝色
                c = Colors.grey;
              }
            }

            // 添加未读消息计数
            tailWidgets.add(
              new Container(
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
              ),
            );
          }

          // 构造控件
          return new Container(
            padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0.0),
            child: new Card(
              color: Color(0xFFEEEEEE), // 背景颜色
              elevation: 0.0, // 投影
              child: ListTile(
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
                trailing: Column(
                    children: tailWidgets,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end),
                onTap: () {
                  // 清除未读消息
                  setState(() {
                    G.ac.clearUnread(msg);
                  });

                  // 打开会话
                  G.rt.showChatPage(msg);
                },
                onLongPress: () {},
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(10.0)), //设定 Card 的倒角大小
                /* borderRadius: BorderRadius.only(
                  //设定 Card 的每个角的倒角大小
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.zero,
                  bottomLeft: Radius.zero,
                  bottomRight: Radius.circular(20.0)),*/
              ),
              clipBehavior:
                  Clip.antiAlias, //对Widget截取的行为，比如这里 Clip.antiAlias 指抗锯齿
            ),
          );
        });
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
}
