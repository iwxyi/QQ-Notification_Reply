import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

List<MsgBean> timedMsgs = []; // 需要显示的列表

class ChatsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new _ChatsPageState();
  }
}

class _ChatsPageState extends State<ChatsPage>
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
    return ListView.builder(
        shrinkWrap: true,
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
            ;
          } else {
            title = msg.nickname;
            subTitle = msg.displayMessage();
            headerUrl = "http://q1.qlogo.cn/g?b=qq&nk=" +
                msg.senderId.toString() +
                "&s=100&t=";
          }
          print("header: " + headerUrl);
          return ListTile(
            leading: Image.network(headerUrl),
            title: Text(title),
            subtitle: Text(subTitle),
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
