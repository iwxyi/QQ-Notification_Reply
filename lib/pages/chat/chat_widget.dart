import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:qqnotificationreply/widgets/customfloatingactionbuttonlocation.dart';

import 'message_view.dart';

// ignore: must_be_immutable
class ChatWidget extends StatefulWidget {
  MsgBean chatObj;
  var setObject;
  bool innerMode;

  ChatWidget(this.chatObj, {this.innerMode = false});

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
  bool _keepScrollBottom = true; // 修改内容时是否滚动到末尾
  bool _blankHistory = false; // 是否已经将加载完历史记录
  bool _showGoToBottomButton = false; // 是否显示返回底部按钮
  num _hasNewMsg = 0; // 是否有新消息

  List<MsgBean> _messages = [];
  Map<int, bool> hasToBottom = {};

  @override
  void initState() {
    widget.setObject = (MsgBean msg) {
      widget.chatObj = msg;
      setState(() {
        _messages = [];
      });
      setState(() {
        _initMessages();
      });
    };

    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.messageRaw) {
        _messageReceived(event.data);
      }
    });

    // 初始化控件
    _textController = new TextEditingController();
    _editorFocus = FocusNode();
    _scrollController =
        new ScrollController(initialScrollOffset: 0.0, keepScrollOffset: true);
    _scrollController.addListener(() {
      // 是否保持底部（有新消息、图标加载完毕等事件）
      _keepScrollBottom = (_scrollController.offset >=
          _scrollController.position.maxScrollExtent - 50);

      // 滚动时判断是否需要“回到底部”悬浮按钮
      bool _prevShow = _showGoToBottomButton;
      _showGoToBottomButton = (_scrollController.offset <
          _scrollController.position.maxScrollExtent - 500);
      if (_prevShow != _showGoToBottomButton) {
        setState(() {});
      }

      // 顶部加载历史消息
      if (_scrollController.offset <= 0 && !_blankHistory) {
        _loadMsgHistory();
      }
    });

    super.initState();

    // 默认获取焦点
    // FocusScope.of(context).requestFocus(_editorFocus);

    _initMessages();
  }

  void _initMessages() {
    MsgBean msg = widget.chatObj;
    // 获取历史消息
    _messages = [];
    if (G.ac.allMessages.containsKey(msg.keyId())) {
      List<MsgBean> list = G.ac.allMessages[msg.keyId()];
      _messages = list.sublist(max(0, list.length - G.st.loadMsgHistoryCount));
    }

    // 默认滚动到底部
    _keepScrollBottom = true;
    _blankHistory = false;
    _showGoToBottomButton = false;
    _hasNewMsg = 0;
    _scrollToBottom(false);
  }

  void _scrollToBottom(bool ani) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (ani) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 400),
            curve: Curves.fastLinearToSlowEaseIn);
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      _hasNewMsg = 0;
    });
  }

  Widget _buildBody(BuildContext context) {
    return new Column(
      children: <Widget>[
        // 消息列表
        new Flexible(
          child: new ListView.separated(
            separatorBuilder: (BuildContext context, int index) {
              return Divider(
                color: Colors.transparent,
                height: 0.0,
                indent: 0,
              );
            },
            // padding: new EdgeInsets.all(8.0),
            itemBuilder: (context, int index) => MessageView(
                _messages[index],
                index <= 0
                    ? false
                    : _messages[index - 1].senderId ==
                        _messages[index].senderId, () {
              if (_keepScrollBottom) {
                if (!hasToBottom.containsKey(_messages[index].messageId)) {
                  hasToBottom[_messages[index].messageId] = true;
                  _scrollToBottom(true);
                }
              }
            }, ValueKey(_messages[index].messageId)),
            itemCount: _messages.length,
            controller: _scrollController,
          ),
        ),
        // new Divider(height: 1.0), // 分割线
        // 输入框
        widget.innerMode ? _buildTextEditor() : _buildLineEditor()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.innerMode) {
      // 不显示脚手架
      return _buildBody(context);
    } else {
      return Scaffold(
        appBar: AppBar(
          title: new Text(widget.chatObj.title()),
        ),
        body: _buildBody(context),
        floatingActionButton: _hasNewMsg > 0 && _showGoToBottomButton
            ? FloatingActionButton(
                child: Icon(Icons.arrow_downward),
                onPressed: () {
                  _scrollToBottom(true);
                },
              )
            : null,
        floatingActionButtonLocation: CustomFloatingActionButtonLocation(
            FloatingActionButtonLocation.miniEndFloat, 0, -56),
      );
    }
  }

  /// 构造单行输入框
  Widget _buildLineEditor() {
    return new Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(children: <Widget>[
          new IconButton(
              icon: new Icon(Icons.image),
              onPressed: () => getImage(false),
              color: Theme.of(context).primaryColor),
          // 输入框
          new Flexible(
              child: Container(
            child: new TextField(
              controller: _textController,
              onSubmitted: _sendMessage,
              decoration: new InputDecoration.collapsed(
                hintText: '发送消息',
              ),
              focusNode: _editorFocus,
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).primaryColor, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(15))),
          )),
          // 发送按钮
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

  /// 构造多行输入框（横屏）
  Widget _buildTextEditor() {
    return new Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(children: <Widget>[
          new IconButton(
              icon: new Icon(Icons.image),
              onPressed: () => getImage(false),
              color: Theme.of(context).primaryColor),
          // 输入框
          new Flexible(
              child: Container(
            constraints: BoxConstraints(maxHeight: 105, minHeight: 75),
            child: new TextField(
              controller: _textController,
              onSubmitted: _sendMessage,
              decoration: new InputDecoration.collapsed( // 取消奇怪的padding
                hintText: '发送消息',
              ),
              focusNode: _editorFocus,
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).primaryColor, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(15))),
          )),
          // 发送按钮
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
    if (!msg.isObj(widget.chatObj)) {
      return;
    }
    _messages.add(msg);
    if (!_keepScrollBottom) {
      _hasNewMsg++;
    }
    // 判断是否已经释放
    if (!mounted) {
      // 不判断的话，会报错：setState() called after dispose():
      return;
    }
    // 刷新界面
    setState(() {});
    if (_keepScrollBottom) {
      _scrollToBottom(true);
    }
  }

  @override
  void dispose() {
    super.dispose();
    eventBusFn.cancel();
  }

  ///发送信息
  void _sendMessage(String text) {
    if (text.isEmpty) {
      return;
    }
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

  /// 获取图片
  /// @param index 0本地图库，1拍照
  Future getImage(bool camera) async {
    PickedFile selectedFile;
    bool supportCamera = true; // 有些平台不支持相机，这个得想办法获取
    if (!supportCamera) {
      // selectedFile=await ImagePicker.platform.pickImage(source: ImageSource.gallery);
      selectedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    } else {
      if (!camera)
        selectedFile =
            await ImagePicker().getImage(source: ImageSource.gallery);
      else
        selectedFile = await ImagePicker().getImage(source: ImageSource.camera);
      // imageFile = File(selectedFile.path);
    }

    if (selectedFile != null) {
      // TODO: 上传文件
      // uploadFile(selectedFile);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('等待开发')));
    }
  }

  void _loadMsgHistory() {
    if (!G.ac.allMessages.containsKey(widget.chatObj.keyId())) {
      _blankHistory = true;
      return;
    }

    // 获取需要加载的位置
    List<MsgBean> list = G.ac.allMessages[widget.chatObj.keyId()];
    int endIndex = list.length, startIndex = 0; // 最后一个需要加载的位置+1（不包括）
    if (_messages != null && _messages.length > 0) {
      // 判断第一条消息的位置
      int messageId = _messages[0].messageId;
      while (endIndex-- > 0 && list[endIndex].messageId != messageId) {}
      if (endIndex <= 0) {
        print('没有历史消息');
        return;
      }
    } else {
      // 加载最新的
    }
    startIndex = max(0, endIndex - G.st.loadMsgHistoryCount);

    // 进行加载操作
    var deltaBottom = _scrollController.position.extentAfter; // 距离底部的位置
    print('margin_bottom:' +
        deltaBottom.toString() +
        "   " +
        (_keepScrollBottom ? "true" : "false"));
    setState(() {
      for (int i = endIndex - 1; i >= startIndex; i--) {
        _messages.insert(0, list[i]);
      }
    });
    // 恢复底部位置
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController
          .jumpTo(_scrollController.position.maxScrollExtent - deltaBottom);
    });
  }
}
