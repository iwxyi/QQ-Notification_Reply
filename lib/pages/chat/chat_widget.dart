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
      _keepScrollBottom = (_scrollController.offset >=
          _scrollController.position.maxScrollExtent - 50);
      bool _prevShow = _showGoToBottomButton;
      _showGoToBottomButton = (_scrollController.offset <
          _scrollController.position.maxScrollExtent - 500);
      if (_prevShow != _showGoToBottomButton) {
        setState(() {});
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
      var list = G.ac.allMessages[msg.keyId()];
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
                _scrollToBottom(true);
              }
            }, ValueKey(_messages[index].messageId)),
            itemCount: _messages.length,
            controller: _scrollController,
          ),
        ),
        // 输入框
        new Divider(height: 1.0),
        new Container(
          decoration: new BoxDecoration(
            color: Theme.of(context).cardColor,
          ),
          child: _buildTextEditor(),
        )
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

  /// 构造输入框
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
              child: new TextField(
            controller: _textController,
            onSubmitted: _sendMessage,
            decoration: new InputDecoration.collapsed(hintText: '发送消息'),
            focusNode: _editorFocus,
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
}
