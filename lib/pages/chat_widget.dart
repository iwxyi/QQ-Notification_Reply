import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

class ChatWidget extends StatefulWidget {
  final MsgBean chatObj;

  ChatWidget(this.chatObj);

  @override
  State<StatefulWidget> createState() {
    return new _ChatWidgetState();
  }
}

class _ChatWidgetState extends State<ChatWidget> {
  TextEditingController _textController;
  var eventBusFn;
  List<MsgBean> _messages = [];

  @override
  void initState() {
    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.messageRaw) {
        messageReceived(event.data);
      }
    });

    // 获取历史消息
    int index = G.ac.allMessages.length;
    int count = 0, maxCount = 20; // 最多加载几条消息
    for (int i = index - 1; i >= 0; i--) {
      if (G.ac.allMessages[i].isObj(widget.chatObj)) {
        _messages.insert(0, G.ac.allMessages[i]);
        count++;
        if (count > maxCount) {
          break;
        }
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 默认滚动到底部
    ScrollController _controller = ScrollController();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _controller.jumpTo(_controller.position.maxScrollExtent);
    });

    // 分割线
    Widget divider = Divider(
      color: Colors.transparent,
      height: 18.0,
      indent: 18,
    );

    return Scaffold(
      appBar: AppBar(
        title: new Text(widget.chatObj.title()),
      ),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: new ListView.separated(
              separatorBuilder: (BuildContext context, int index) {
                return divider;
              },
              padding: new EdgeInsets.all(8.0),
              itemBuilder: (context, int index) => EntryItem(_messages[index]),
              itemCount: _messages.length,
              controller: _controller,
            ),
          ),
          new Divider(height: 1.0),
          new Container(
            decoration: new BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          )
        ],
      ),
    );
  }

  ///发送信息
  void _handleSubmitted(String text) {
    _textController.clear(); //清空文本框
    setState(() {
      // 收到消息要更新
    });
  }

  /// 构造输入框
  Widget _buildTextComposer() {
    return new Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(children: <Widget>[
          new Flexible(
              child: new TextField(
            controller: _textController,
            onSubmitted: _handleSubmitted,
            decoration: new InputDecoration.collapsed(hintText: '发送消息'),
          )),
          new Container(
            margin: new EdgeInsets.symmetric(horizontal: 4.0),
            child: new IconButton(
                icon: new Icon(
                  Icons.send,
                  color: Colors.blue,
                ),
                onPressed: () => _handleSubmitted(_textController.text)),
          )
        ]));
  }

  /// 收到消息
  void messageReceived(MsgBean msg) {
    // 判断是否已经释放
    if (!mounted) {
      // 不判断的话，会报错：setState() called after dispose():
      return;
    }
    if (msg.isObj(widget.chatObj)) {
      setState(() {
        _messages.add(msg);
      });
    }
  }
}

///构造发送的信息
class EntryItem extends StatelessWidget {
  MsgBean message;

  EntryItem(this.message);

  Widget _buildMessageLine() {
    ///由自己发送，在右边显示
    if (message.senderId == G.ac.qqId) {
      return new Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Flexible(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: new Text(
                      message.displayMessage(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  )
                ]),
          ),
          new Container(
            margin: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: new CircleAvatar(
              backgroundImage: AssetImage("http://q1.qlogo.cn/g?b=qq&nk=" +
                  G.ac.qqId.toString() +
                  "&s=100&t="),
              radius: 24.0,
            ),
          ),
        ],
      );
    } else {
      ///对方发送，左边显示
      return new Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: new CircleAvatar(
              backgroundImage: NetworkImage("http://q1.qlogo.cn/g?b=qq&nk=" +
                  message.senderId.toString() +
                  "&s=100&t="),
              radius: 24.0,
            ),
          ),
          Flexible(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: new Text(
                      message.username() + ":", // 用户昵称
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  new Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: new Text(
                      message.displayMessage(), // 消息
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  )
                ]),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: _buildMessageLine(),
    );
  }
}
