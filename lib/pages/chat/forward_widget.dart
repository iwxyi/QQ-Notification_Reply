import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

import 'message_view.dart';

class ForwardWidget extends StatefulWidget {
  final forwardId;

  const ForwardWidget({Key key, this.forwardId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ForwardWidgetState();
}

class _ForwardWidgetState extends State<ForwardWidget> {
  var eventBusFn;
  List<MsgBean> msgs = [];

  @override
  void initState() {
    G.cs.getForwardMessages(widget.forwardId);
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.forwardMessages) {
        if (event.data['forward_id'] != widget.forwardId) {
          return;
        }
        _parseMessageJson(event.data['messages']);
        print('加载转发消息完成：${msgs.length}条');
        if (mounted) {
          setState(() {});
        }
      }
    });
    super.initState();
  }

  void _parseMessageJson(var list) {
    for (var i = 0; i < list.length; i++) {
      var obj = list[i];
      String message = obj['content'];
      String nickname = obj['sender']['nickname'];
      int userId = obj['sender']['user_id'];
      int time = obj['time']; // 秒
      MsgBean msg = new MsgBean(
          message: message,
          nickname: nickname,
          senderId: userId,
          timestamp: time * 1000);
      print(message);
      msgs.add(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    int count = msgs.length;
    return ListView.separated(
        itemBuilder: (context, int index) {
          // 跳过第一个索引
          if (index == 0) {
            return Divider(color: Colors.transparent, height: 0.0);
          }
          index--;

          // index从0开始
          return MessageView(
              msgs[index], false, ValueKey(msgs[index].messageId));
        },
        separatorBuilder: (BuildContext context, int index) {
          if (false && index < count - 1) {
            int ts0 = msgs[index].timestamp;
            int ts1 = 0;
            if (index < count - 1) {
              ts1 = msgs[index + 1].timestamp;
            }
            int delta = ts0 - ts1;
            int maxDelta = 120 * 1000;
            // int maxDelta = 0;
            if (delta > maxDelta) {
              // 超过一分钟，显示时间
              DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts0);
              String str = formatDate(dt, ['HH', ':', 'nn']);
              return new Row(
                children: [new Text(str, style: TextStyle(color: Colors.grey))],
                mainAxisAlignment: MainAxisAlignment.center,
              );
            }
          }

          return Divider(
            color: Colors.transparent,
            height: 0.0,
            indent: 0,
          );
        },
        itemCount: count + 1);
  }

  @override
  void dispose() {
    eventBusFn.cancel();
    super.dispose();
  }
}
