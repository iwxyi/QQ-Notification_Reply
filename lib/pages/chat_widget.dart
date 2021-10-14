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

class _ChatWidgetState extends State<ChatWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  var eventBusFn;
  TextEditingController _textController;
  FocusNode _editorFocus;
  ScrollController _scrollController;

  List<MsgBean> _messages = [];

  @override
  void initState() {
    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.messageRaw) {
        _messageReceived(event.data);
      }
    });

    // 获取历史消息
    MsgBean msg = widget.chatObj;
    if (msg.isPrivate()) {
      _messages = G.ac.allPrivateMessages[msg.friendId];
    } else if (msg.isGroup()) {
      _messages = G.ac.allGroupMessages[msg.groupId];
    }

    if (_messages == null) {
      _messages = [];
    }

    // 初始化控件
    _textController = new TextEditingController();
    _editorFocus = FocusNode();
    _scrollController =
        new ScrollController(initialScrollOffset: 0.0, keepScrollOffset: true);

    super.initState();

    // 默认获取焦点
    // FocusScope.of(context).requestFocus(_editorFocus);

    // 默认滚动到底部
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _scrollController,
            ),
          ),
          new Divider(height: 1.0),
          new Container(
            decoration: new BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextEditor(),
          )
        ],
      ),
    );
  }

  /// 构造输入框
  Widget _buildTextEditor() {
    return new Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(children: <Widget>[
          new Flexible(
              child: new TextField( // 输入框
            controller: _textController,
            onSubmitted: _sendMessage,
            decoration: new InputDecoration.collapsed(hintText: '发送消息'),
            focusNode: _editorFocus,
          )),
          new Container(
            margin: new EdgeInsets.symmetric(horizontal: 4.0),
            child: new IconButton(
                icon: new Icon(
                  Icons.send,
                  color: Colors.blue,
                ),
                onPressed: () => _sendMessage(_textController.text)),
          )
        ]));
  }

  /// 收到消息
  void _messageReceived(MsgBean msg) {
    // 判断是否已经释放
    if (!mounted) {
      // 不判断的话，会报错：setState() called after dispose():
      return;
    }
    if (msg.isObj(widget.chatObj)) {
      setState(() {});
    }
  }

  ///发送信息
  void _sendMessage(String text) {
    _textController.clear(); //清空文本框
    FocusScope.of(context).requestFocus(_editorFocus); // 继续保持焦点
    
    print('发送消息：' + text);
    if (widget.chatObj.isPrivate()) {
      // 发送私聊消息
      G.cs.sendPrivateMessage(widget.chatObj.friendId, text);
    } else if (widget.chatObj.isGroup()) {
      // 发送群组消息
      G.cs.sendGroupMessage(widget.chatObj.groupId, text);
    }
    
  }
}

/// 构造发送的信息
/// 每一条消息显示的复杂对象
class EntryItem extends StatelessWidget {
  MsgBean message;

  EntryItem(this.message);

  Widget _buildMessageLine() {
    String headerUrl = "http://q1.qlogo.cn/g?b=qq&nk=" +
        message.senderId.toString() +
        "&s=100&t=";

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
                      G.cs.getMessageDisplay(message),
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
              backgroundImage: NetworkImage(headerUrl),
              radius: 24.0,
              backgroundColor: Colors.transparent,
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
              backgroundImage: NetworkImage(headerUrl), // 头像
              radius: 24.0,
              backgroundColor: Colors.transparent,
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
                      G.cs.getMessageDisplay(message), // 消息
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
