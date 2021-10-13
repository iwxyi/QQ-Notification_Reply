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
  Widget build(BuildContext context) {
    DateTime currentDay = DateTime.now();
    int currentTimestamp = currentDay.millisecondsSinceEpoch;

    // 填充空白
    if (timedMsgs.length == 0) {
      return new Center(
        child: new Text('没有会话'),
      );
    }

    return ListView.builder(
        shrinkWrap: false,
        itemCount: timedMsgs.length,
        itemBuilder: (context, index) {
          MsgBean msg = timedMsgs[index];
          String title;
          String subTitle;
          String headerUrl;
          if (msg.isGroup()) {
            title = msg.groupName;
            subTitle = msg.nickname + ": " + msg.displayMessage();
            headerUrl = "http://p.qlogo.cn/gh/" +
                msg.groupId.toString() +
                "/" +
                msg.groupId.toString() +
                "/100";
          } else {
            title = msg.username();
            subTitle = msg.displayMessage();
            headerUrl = "http://q1.qlogo.cn/g?b=qq&nk=" +
                msg.senderId.toString() +
                "&s=100&t=";
          }

          // 时间
          String timeStr;
          DateTime dt = DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
          int delta = currentTimestamp - msg.timestamp;
          if (delta > 3600 * 24 * 1000) {
            // 超过一天
            timeStr = (delta / 3600 / 24 / 1000).toString();
          } else if (delta < 15000) {
            timeStr = '刚刚';
          } else if (dt.day == currentDay.day) {
            timeStr = dt.hour.toString() + ":" + dt.minute.toString();
          } else {
            timeStr = "昨天 " + dt.hour.toString() + ":" + dt.minute.toString();
          }

          return ListTile(
            leading: new ClipOval(
              // 圆形头像
              child: new FadeInImage.assetNetwork(
                placeholder: "assets/icons/default_header.png", //预览图
                fit: BoxFit.contain,
                image: headerUrl,
                width: 40.0,
                height: 40.0,
              ),
            ),
            title: Text(title),
            subtitle: Text(subTitle),
            trailing: Text(timeStr),
            onTap: () {},
          );
        });
  }

  /// 收到消息
  void messageReceived(MsgBean msg) {
    // 判断是否已经释放
    if (!mounted) {
      // 不判断的话，会报错：setState() called after dispose():
      return;
    }
    setState(() {
      for (int i = 0; i < timedMsgs.length; i++) {
        if (timedMsgs[i].isObj(msg)) {
          timedMsgs.removeAt(i);
          break;
        }
      }
      timedMsgs.insert(0, msg);
    });
  }
}
