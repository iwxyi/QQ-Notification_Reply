import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker_saver/image_picker_saver.dart';
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
  final GlobalKey globalKey = GlobalKey();

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
      } else if (event.event == Event.groupMember) {
        if (mounted) {
          setState(() {});
        }
      } else if (event.event == Event.messageRecall &&
          widget.chatObj.isObj(event.data)) {
        print('message recall, refresh state');
        if (mounted) {
          setState(() {});
        }
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
    _textController.text = "";
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
                          _messages[index].senderId &&
                      !_messages[index - 1].recalled,
              ValueKey(_messages[index].messageId),
              loadFinishedCallback: () {
                // 图片加载完毕，会影响大小
                if (_keepScrollBottom) {
                  if (!hasToBottom.containsKey(_messages[index].messageId)) {
                    // 重复判断，避免不知道哪来的多次complete
                    hasToBottom[_messages[index].messageId] = true;
                    _scrollToBottom(true);
                  }
                }
              },
              jumpMessageCallback: (int messageId) {
                // 跳转到指定消息（如果有）
                int index = _messages.lastIndexWhere((element) {
                  return element.messageId == messageId;
                });
                if (index > -1) {
                  // TODO: 滚动到index
                }
              },
              addMessageCallback: (String text) {
                // 添加消息到发送框
                _insertMessage(text);
                FocusScope.of(context).requestFocus(_editorFocus);
              },
              sendMessageCallback: (String text) {
                // 直接发送消息
                MsgBean msg = _messages[index];
                if (msg.isPrivate()) {
                  G.cs.sendPrivateMessage(msg.friendId, text);
                } else if (msg.isGroup()) {
                  G.cs.sendGroupMessage(msg.groupId, text);
                } else {
                  print('error: 未知的发送对象');
                }
              },
              deleteMessageCallback: (MsgBean msg) {
                // 本地删除消息
                setState(() {
                  _messages.removeWhere(
                      (element) => element.messageId == msg.messageId);
                  G.ac.allMessages[msg.keyId()].removeWhere(
                      (element) => element.messageId == msg.messageId);
                });
              },
            ),
            itemCount: _messages.length,
            controller: _scrollController,
          ),
        ),
        SizedBox(height: 8),
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
    return new CtrlEnterWidget(
      child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: new Column(
            children: <Widget>[
              // 分割线
              Divider(
                color: Color(0xFFCCCCCC),
                height: 1.0,
                indent: 8,
              ),
              // 输入框
              Container(
                constraints: BoxConstraints(maxHeight: 105, minHeight: 75),
                child: new TextField(
                  controller: _textController,
                  decoration: new InputDecoration.collapsed(
                    // 取消奇怪的padding
                    hintText: '发送消息',
                  ),
                  focusNode: _editorFocus,
                  onSubmitted: _sendMessage, // TODO: CtrlEnter发送
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              ),
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
            ],
            crossAxisAlignment: CrossAxisAlignment.end,
          )),
      onCtrlEnterCallback: () {
        _sendMessage(_textController.text);
      },
    );
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
    G.cs.sendMsg(widget.chatObj, text);
  }

  void _insertMessage(String text) {
    int start = _textController.selection.start;
    int end = _textController.selection.end;
    if (start == -1 && end == -1) {
      // 没有任何位置，直接添加到末尾
      _textController.text = _textController.text + text;
    } else {
      int pos = end;
      String full = _textController.text;
      if (start > -1 && end > -1) {
        // 有选中，先删除选中
        if (start > end) {
          int tmp = start;
          start = end;
          end = tmp;
        }
        pos = start;
        full =
            full.substring(0, start) + text + full.substring(end, full.length);
      } else {
        if (pos < 0) {
          pos = start;
        }
        full = full.substring(0, pos) + text + full.substring(pos, full.length);
      }
      _textController.text = full;
      _textController.selection =
          TextSelection.fromPosition(TextPosition(offset: pos + text.length));
    }
  }

  /// 获取图片
  /// @param immediate 是否立刻上传
  Future getImage(bool immediate) async {
    var image = await ImagePickerSaver.pickImage(source: ImageSource.gallery);
    if (image == null) {
      // 取消选择图片
      return;
    }
    _uploadImage(image, immediate);
  }

  void _uploadImage(File image, bool send) async {
    if (G.st.server == null || G.st.server.isEmpty) {
      Fluttertoast.showToast(
          msg: "未设置后台服务主机",
          gravity: ToastGravity.CENTER,
          textColor: Colors.grey);
      return;
    }

    String path = image.path;
    var name = path.substring(path.lastIndexOf("/") + 1, path.length);
    var suffix = name.substring(name.lastIndexOf(".") + 1, name.length);
    FormData formData = new FormData.fromMap({
      "upfile": await MultipartFile.fromFile(path,
          filename: name, contentType: MediaType.parse("image/$suffix"))
    });

    Dio dio = new Dio();
    var response = await dio.post<String>("${G.st.server}/file_upload.php",
        data: formData);
    if (response.statusCode == 200) {
      Fluttertoast.showToast(
          msg: "图片上传成功", gravity: ToastGravity.CENTER, textColor: Colors.grey);

      var data = json.decode(response.data);
      String hash = data['hash'];
      String text = "[CQ:image,file=${G.st.server}/files/$hash]";
      if (send) {
        G.cs.sendMsg(widget.chatObj, text);
      } else {
        _insertMessage(text);
      }
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
        _blankHistory = true;
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

final ctrlEnterKeySet = LogicalKeySet(
  Platform.isMacOS
      ? LogicalKeyboardKey.meta
      : LogicalKeyboardKey.control, // Windows:control, MacOS:meta
  LogicalKeyboardKey.arrowUp,
);

class CtrlEnterIntent extends Intent {}

class CtrlEnterWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback onCtrlEnterCallback;

  const CtrlEnterWidget(
      {Key key, @required this.child, @required this.onCtrlEnterCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(child: child, autofocus: true, shortcuts: {
      ctrlEnterKeySet: CtrlEnterIntent(),
    }, actions: {
      CtrlEnterIntent:
          CallbackAction(onInvoke: (e) => onCtrlEnterCallback?.call()),
    });
  }
}
