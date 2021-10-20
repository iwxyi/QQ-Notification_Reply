import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

import 'slide_images_page.dart';

// ignore: must_be_immutable
class ChatWidget extends StatefulWidget {
  MsgBean chatObj;
  var setObject;

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
  bool _keepScrollBottom = true; // 修改内容时是否滚动到末尾
  bool _blankHistory = false; // 是否已经将加载完历史记录
  bool _showGoToBottomButton = false; // 是否显示返回底部按钮
  num _hasNewMsg = 0; // 是否有新消息

  List<MsgBean> _messages = [];

  @override
  void initState() {
    widget.setObject = (MsgBean msg) {
      widget.chatObj = msg;
      _loadMessages();
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

    _loadMessages();
  }

  void _loadMessages() {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          // 消息列表
          new Flexible(
            child: new ListView.separated(
              separatorBuilder: (BuildContext context, int index) {
                return divider;
              },
              padding: new EdgeInsets.all(8.0),
              itemBuilder: (context, int index) =>
                  MessageView(_messages[index], () {
                if (_keepScrollBottom) {
                  _scrollToBottom(true);
                }
              }),
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
      ),
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

  /// 构造输入框
  Widget _buildTextEditor() {
    return new Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(children: <Widget>[
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
}

/// 构造发送的信息
/// 每一条消息显示的复杂对象
class MessageView extends StatefulWidget {
  final MsgBean msg;
  final loadFinishedCallback;

  MessageView(this.msg, this.loadFinishedCallback);

  @override
  _MessageViewState createState() => _MessageViewState(msg);
}

class _MessageViewState extends State<MessageView>
    with SingleTickerProviderStateMixin {
  final MsgBean msg;
  AnimationController _controller;

  _MessageViewState(this.msg);

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        lowerBound: 0.0,
        upperBound: 1.0);
    super.initState();
  }

  /// 一整行
  Widget _buildMessageLine() {
    // 判断左右
    bool isSelf = msg.senderId == G.ac.qqId;

    // 消息列，是否显示昵称
    List<Widget> vWidgets = [];
    if (!isSelf) {
      vWidgets.add(_buildNicknameView());
    }
    vWidgets.add(_buildMessageContainer());

    Widget vWidget = Flexible(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: vWidgets),
    );

    // 头像和消息的顺序
    List<Widget> hWidgets;
    if (isSelf) {
      hWidgets = [vWidget, _buildHeaderView()];
    } else {
      hWidgets = [_buildHeaderView(), vWidget];
    }

    return new Row(
        mainAxisAlignment:
            isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hWidgets);
  }

  /// 构建头像控件
  Widget _buildHeaderView() {
    // 头像URL
    String headerUrl =
        "http://q1.qlogo.cn/g?b=qq&nk=" + msg.senderId.toString() + "&s=100&t=";

    Widget header = new Container(
        margin: const EdgeInsets.only(left: 12.0, right: 12.0),
        child: new CircleAvatar(
          backgroundImage: NetworkImage(headerUrl),
          radius: 24.0,
          backgroundColor: Colors.transparent,
        ));

    return header;
  }

  /// 构建昵称控件
  Widget _buildNicknameView() {
    return new Container(
      margin: const EdgeInsets.only(top: 5.0),
      child: new Text(
        msg.username() + ":", // 用户昵称
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  /// 构建消息容器
  Widget _buildMessageContainer() {
    return new Container(
        margin: const EdgeInsets.only(top: 5.0),
        child: _buildMessageTypeView());
  }

  /// 构建消息控件
  Widget _buildMessageTypeView() {
    String text = msg.message;
    Match match;
    RegExp imageRE = RegExp(r'^\[CQ:image,file=.+?,url=(.+?)(,.+?)?\]$');
    if ((match = imageRE.firstMatch(text)) != null) {
      // 如果是图片
      String url = match.group(1);
      return GestureDetector(
          child: Hero(
              tag: url,
              child: url == 'This is an video'
                  ? Container(
                      alignment: Alignment.center,
                      child: const Text('This is an video'),
                    )
                  : ExtendedImage.network(
                      url,
                      fit: BoxFit.contain,
                      cache: true,
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      scale: 1,
                      mode: ExtendedImageMode.gesture,
                      initGestureConfigHandler: (state) {
                        return GestureConfig(
                          minScale: 0.9,
                          animationMinScale: 0.7,
                          maxScale: 3.0,
                          animationMaxScale: 3.5,
                          speed: 1.0,
                          inertialSpeed: 100.0,
                          initialScale: 1.0,
                          inPageView: false,
                          initialAlignment: InitialAlignment.center,
                        );
                      },
                      loadStateChanged: (ExtendedImageState state) {
                        state.extendedImageInfo;
                        switch (state.extendedImageLoadState) {
                          case LoadState.loading:
                            _controller.reset();
                            return Image.asset(
                              "assets/images/loading.gif",
                              fit: BoxFit.fill,
                            );

                          ///if you don't want override completed widget
                          ///please return null or state.completedWidget
                          //return null;
                          //return state.completedWidget;
                          case LoadState.completed:
                            _controller.forward();
                            if (widget.loadFinishedCallback != null) {
                              widget.loadFinishedCallback();
                            }
                            return FadeTransition(
                              opacity: _controller,
                              child: ExtendedRawImage(
                                image: state.extendedImageInfo?.image,
                                fit: BoxFit.contain,
                              ),
                            ); // 显示图片
                          case LoadState.failed:
                            _controller.reset();
                            return GestureDetector(
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  Image.asset(
                                    "assets/images/failed.jpg",
                                    fit: BoxFit.fill,
                                  ),
                                  Positioned(
                                    bottom: 0.0,
                                    left: 0.0,
                                    right: 0.0,
                                    child: Text(
                                      "加载失败，点击重试",
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                ],
                              ),
                              onTap: () {
                                state.reLoadImage();
                              },
                            );
                            break;
                        }
                        return null;
                      },
                    )),
          onTap: () {
            /* Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return new SlidePage(url: url);
            })); */
            Navigator.of(context).push(PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => new SlidePage(url: url)));
          });
    } else {
      // 未知，当做纯文本了
      return new Text(
        G.cs.getMessageDisplay(msg),
        style: TextStyle(color: Colors.black, fontSize: 16),
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

/// 自定义 FloatingActionButton 的偏移位置
class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  FloatingActionButtonLocation location;
  double offsetX; // X方向的偏移量
  double offsetY; // Y方向的偏移量
  CustomFloatingActionButtonLocation(this.location, this.offsetX, this.offsetY);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    Offset offset = location.getOffset(scaffoldGeometry);
    return Offset(offset.dx + offsetX, offset.dy + offsetY);
  }
}
