import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:date_format/date_format.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_pickers/image_pickers.dart';
import 'package:qqnotificationreply/global/api.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/pages/main/search_page.dart';
import 'package:qqnotificationreply/pages/profile/group_profile_widget.dart';
import 'package:qqnotificationreply/pages/profile/user_profile_widget.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:qqnotificationreply/widgets/customfloatingactionbuttonlocation.dart';

import 'emoji_grid.dart';
import 'message_view.dart';

enum ChatMenuItems {
  Info,
  Members,
  EnableNotification,
  CustomName,
  MessageHistories,
  SendImage,
  InsertFakeLeft,
  InsertFakeRight
}

// ignore: must_be_immutable
class ChatWidget extends StatefulWidget {
  MsgBean chatObj;
  var setObject;
  bool innerMode;
  var buildChatMenu;
  var unfocusEditor;
  var focusEditor;
  var setUnreadCount;
  var setDirectlyClose;
  bool directlyClose = false;

  var showJumpMessage; // 显示其他聊天对象的最新消息的入口
  MsgBean jumpMsg; // 其他聊天对象的最新消息
  int jumpMsgTimestamp = 0;

  ChatWidget(this.chatObj, {this.innerMode: false, this.directlyClose: false});

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
  int _unreadCount = 0;

  List<MsgBean> _messages = []; // 显示的msg列表，不显示全
  Map<int, bool> hasToBottom = {}; // 指定图片是否已经申请跳bottom

  @override
  void initState() {
    // 设置新的聊天对象
    widget.setObject = (MsgBean msg) {
      // 取消旧的
      _releaseChatObjData();
      widget.jumpMsg = null;

      // 设置为新的
      widget.chatObj = msg;
      setState(() {
        _messages = [];
        _initChatObjData();
      });

      /* if (!widget.innerMode) {
        G.rt.updateChatPageUnreadCount();
      } */
    };

    widget.buildChatMenu = () {
      return buildMenu();
    };

    widget.unfocusEditor = () {
      _removeEditorFocus();
    };

    widget.focusEditor = () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_editorFocus);
      }
    };

    widget.showJumpMessage = (MsgBean msg) {
      setState(() {
        widget.jumpMsg = msg;
        widget.jumpMsgTimestamp = DateTime.now().millisecondsSinceEpoch;
      });
      // 显示几秒后取消显示
      Timer(Duration(milliseconds: G.st.chatTopMsgDisplayMSecond + 200), () {
        if (mounted) {
          setState(() {});
        }
      });
    };

    widget.setUnreadCount = (int c) {
      if (mounted) {
        setState(() {
          _unreadCount = c;
        });
      }
    };

    widget.setDirectlyClose = (bool b) {
      setState(() {
        widget.directlyClose = b;
      });
    };

    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      MsgBean chatObj = widget.chatObj;
      if (event.event == Event.messageRaw) {
        _messageReceived(event.data);
      } else if (event.event == Event.groupMember) {
        if (mounted) {
          setState(() {});
        }
      } else if (event.event == Event.messageRecall) {
        if (widget.chatObj.isObj(event.data)) {
          print('监听到消息撤回，刷新状态');
          if (mounted) {
            setState(() {});
          }
        }
      } else if (event.event == Event.refreshState) {
        if (mounted) {
          setState(() {});
        }
      } else if (event.event == Event.groupMessageHistories) {
        if (chatObj.isGroup() && chatObj.groupId == event.data['group_id']) {
          print('收到群消息历史，刷新状态');
          if (mounted) {
            _blankHistory = false;
            _loadMsgHistory();
            setState(() {});
          }
        }
      } else if (event.event == Event.playAudio) {
        if (event.data['key_id'] == chatObj.keyId()) {
          String url = event.data['url'];
          print('播放音频：$url');
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
      _keepScrollBottom = (_scrollController.offset <= 50);

      // 滚动时判断是否需要“回到底部”悬浮按钮
      bool _prevShow = _showGoToBottomButton;
      _showGoToBottomButton = (_scrollController.offset >
          _scrollController.position.minScrollExtent + 500);
      if (_prevShow != _showGoToBottomButton) {
        setState(() {});
        if (!_showGoToBottomButton) {
          // 开始滚动到底部
          _hasNewMsg = 0;
        }
      }

      // 顶部加载历史消息
      if (_scrollController.offset >=
              _scrollController.position.maxScrollExtent &&
          !_blankHistory) {
        _loadMsgHistory();
      }
    });

    super.initState();

    // 默认获取焦点
    // FocusScope.of(context).requestFocus(_editorFocus);

    _initChatObjData();
  }

  void _initChatObjData() {
    MsgBean msg = widget.chatObj;
    // 获取历史消息
    _messages = [];
    if (G.ac.allMessages.containsKey(msg.keyId())) {
      List<MsgBean> list = G.ac.allMessages[msg.keyId()];
      // _messages = list.sublist(max(0, list.length - G.st.loadMsgHistoryCount));
      // 逆序，最新消息是0，最旧消息是len-1
      _messages.clear();
      int start = max(0, list.length - G.st.loadMsgHistoryCount);
      for (int i = list.length - 1; i >= start; --i) {
        _messages.add(list[i]);
      }
    }

    // 默认滚动到底部
    _keepScrollBottom = true;
    _blankHistory = false;
    _showGoToBottomButton = false;
    _hasNewMsg = 0;
    _scrollToLatest(false);
    _textController.text = "";

    // 一些标记变量
    if (G.ac.unsentMessages.containsKey(msg.keyId())) {
      _setMessage(G.ac.unsentMessages[msg.keyId()]);
    }
    G.ac.unreadMessageCount.remove(widget.chatObj.keyId());
    G.rt.updateChatPageUnreadCount();

    if (msg.isGroup()) {
      // 智能聚焦
      if (G.st.groupSmartFocus) {
        GroupInfo group = G.ac.groupList[msg.groupId];
        if (group.focusAsk) {
          group.focusAsk = false;
          print('群消息.关闭疑问聚焦');
        }
        if (group.focusAt != null) {
          group.focusAt = null;
          print('群消息.关闭艾特聚焦');
        }
      }
      if (G.ac.atMeGroups.contains(msg.groupId)) {
        G.ac.atMeGroups.remove(msg.groupId);
      }
      if (G.ac.replyMeGroups.contains(msg.groupId)) {
        G.ac.replyMeGroups.remove(msg.groupId);
      }
    }

    // 清除通知（遗留在 showChatPage 中）
    if (G.rt.enableNotification) {
      if (UserAccount.notificationIdMap.containsKey(msg.keyId())) {
        AwesomeNotifications()
            .cancel(UserAccount.notificationIdMap[msg.keyId()]);
      }
    }
  }

  /// 跳转到最新的位置
  void _scrollToLatest(bool ani) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ani) {
        _scrollController.animateTo(_scrollController.position.minScrollExtent,
            duration: Duration(milliseconds: 400),
            curve: Curves.fastLinearToSlowEaseIn);
      } else {
        _scrollController.jumpTo(_scrollController.position.minScrollExtent);
      }
      _hasNewMsg = 0;
    });
  }

  Widget _buildMessageList(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime zero = DateTime(now.year, now.month, now.day);
    return new ListView.separated(
      separatorBuilder: (BuildContext context, int index) {
        // 计算时间差，显示时间
        if (index >= 0) {
          int ts0 = _messages[index].timestamp;
          int ts1 = 0;
          if (index < _messages.length - 1) {
            ts1 = _messages[index + 1].timestamp;
          }
          int delta = ts0 - ts1;
          int maxDelta = 120 * 1000;
          // int maxDelta = 0;
          if (delta > maxDelta) {
            // 超过一分钟，显示时间
            DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts0);
            bool today = dt.isAfter(zero);
            String str = today
                ? formatDate(dt, ['HH', ':', 'nn'])
                : formatDate(dt, ['mm', '-', 'dd', ' ', 'HH', ':', 'nn']);
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
      reverse: true,
      // padding: new EdgeInsets.all(8.0),
      itemBuilder: (context, int index) {
        // 点击加载历史消息
        if (index >= _messages.length) {
          Widget header = CircleAvatar(
            backgroundImage: NetworkImage(API.chatObjHeader(widget.chatObj)),
            radius: 48.0,
            backgroundColor: Colors.transparent,
          );

          List<Widget> widgets = [header];
          if (_messages.length <= 0) {
            Widget name = Text(widget.chatObj.title(),
                style: TextStyle(fontSize: 20, color: Colors.grey));
            widgets.add(SizedBox(height: 12));
            widgets.add(name);
            widgets.add(SizedBox(height: 2));
          }

          if (widget.chatObj.isGroup()) {
            Widget btn = FlatButton(
                child: Container(
                    padding: new EdgeInsets.all(6),
                    child:
                        Text('查看历史消息', style: TextStyle(color: Colors.grey))),
                onPressed: () {
                  _loadMsgHistory();
                });
            widgets.add(btn);
          }
          return Container(
              alignment: Alignment.center, child: Column(children: widgets));
        }

        // 是否是下一个
        bool isNext = index >= _messages.length - 1
            ? false
            : _messages[index + 1].senderId == _messages[index].senderId &&
                _messages[index + 1].action == MessageType.Message &&
                !G.st.blockedUsers.contains(_messages[index].senderId);

        int valueKey = (_messages[index].messageId ?? 0) + (isNext ? 1 : 0);

        return MessageView(_messages[index], isNext, ValueKey(valueKey),
            loadFinishedCallback: () {
          // 图片加载完毕，会影响大小
          if (_keepScrollBottom) {
            if (!hasToBottom.containsKey(_messages[index].messageId)) {
              // 重复判断，避免不知道哪来的多次complete
              hasToBottom[_messages[index].messageId] = true;
              _scrollToLatest(true);
            }
          }
        }, jumpMessageCallback: (int messageId) {
          // 跳转到指定消息（如果有）
          int index = _messages.lastIndexWhere((element) {
            return element.messageId == messageId;
          });
          if (index > -1) {
            // TODO: 滚动到index
          }
        }, addMessageCallback: (String text) {
          // 添加消息到发送框
          _insertMessage(text);
          FocusScope.of(context).requestFocus(_editorFocus);
        }, sendMessageCallback: (String text) {
          // 直接发送消息
          MsgBean msg = _messages[index];
          G.cs.sendMsg(msg, text);
        }, deleteMessageCallback: (MsgBean msg) {
          setState(() {
            // 本地删除消息
            _messages
                .removeWhere((element) => element.messageId == msg.messageId);
            G.ac.allMessages[msg.keyId()]
                .removeWhere((element) => element.messageId == msg.messageId);
          });
        }, unfocusEditorCallback: () {
          _removeEditorFocus();
        }, showUserInfoCallback: (MsgBean msg) {
          showUserInfo(msg);
        }, fakeSendCallback: (int senderId) {
          insertFakeMessage(senderId);
        });
      },
      itemCount: _messages.length + 1,
      controller: _scrollController,
    );
  }

  double _pointPressX = 0, _pointPressY = 0;
  bool _movedLarge = false, hidedKeyboard = false;
  void onPointerMove(movePointEvent) {
    const DIS_L = 50; // 隐藏键盘的方向
    const DIS_M = 35; // 同方向滑动，生效的距离
    const DIS_S = 20; // 垂直方向滑动，导致不生效的距离

    if (_movedLarge) {
      if (!hidedKeyboard && G.st.hideKeyboardOnSlide) {
        if (movePointEvent.position.dy - _pointPressY > DIS_L) {
          hidedKeyboard = true;
          // 隐藏键盘
          FocusScope.of(context).requestFocus(FocusNode());
        }
      }
      return;
    }

    var deltaX = movePointEvent.position.dx - _pointPressX;
    var deltaY = movePointEvent.position.dy - _pointPressY;
    if (deltaY >= DIS_S || deltaY <= -DIS_S) {
      // 上下划过超过距离，无视
      _movedLarge = true;
    } else if (!_movedLarge) {
      if (deltaX > DIS_M) {
        _movedLarge = true;
        // #右滑
        if (!G.st.enableHorizontalSwitch) {
          // 返回到上一页
          if (G.rt.currentChatPage == null) {
            // 可能返回手势已经取消这一页了
            return;
          }
          Navigator.pop(context);
        } else {
          // 切换到上一个聊天对象
          switchToPreviousObject();
        }
      } else if (deltaX < -DIS_M) {
        _movedLarge = true;
        // #左滑
        if (!G.st.enableHorizontalSwitch) {
          // 下一条未读消息
          switchToUnreadObject();
        } else {
          // 切换到下一个聊天对象
          switchToNextObject();
        }
      }
    }
  }

  Widget _buildListStack(BuildContext context) {
    // 消息列表
    List<Widget> stack = [
      widget.innerMode
          ? _buildMessageList(context)
          : Listener(
              onPointerDown: (dowPointEvent) {
                _pointPressX = dowPointEvent.position.dx;
                _pointPressY = dowPointEvent.position.dy;
                _movedLarge = false;
              },
              onPointerMove: onPointerMove,
              child: _buildMessageList(context))
    ];

    // 显示跳转的消息
    if (widget.jumpMsg != null &&
        ((DateTime.now().millisecondsSinceEpoch - widget.jumpMsgTimestamp) <
            G.st.chatTopMsgDisplayMSecond)) {
      MsgBean msg = widget.jumpMsg;
      String title = G.cs.getMessageDisplay(msg);
      if (msg.action == MessageType.Message) {
        String username =
            G.st.getLocalNickname(msg.senderKeyId(), msg.username());
        title = username + "：" + title;
      }
      if (msg.isGroup()) {
        String gn = G.st.getLocalNickname(msg.senderKeyId(), msg.groupName);
        title = '[$gn] ' + title;
      }
      Widget label = Text(
        title,
        maxLines: G.st.enableMessagePreviewSingleLine ? 1 : 2,
        style: TextStyle(fontSize: G.st.msgFontSize),
      );
      stack.add(Positioned(
        top: -6, // 因为上面有几个像素阴影，会露出后面的
        child: FlatButton(
          color: Color.fromARGB(255, 230, 230, 255),
          child: Container(
            padding: EdgeInsets.all(6),
            child: label,
            width: MediaQuery.of(context).size.width - 12,
          ),
          onPressed: () {
            widget.setObject(widget.jumpMsg);
          },
        ),
      ));
    }

    // 显示最新的消息
    if (_hasNewMsg > 0 && !_keepScrollBottom && _showGoToBottomButton) {
      MsgBean msg = _messages.first;
      String title = G.cs.getMessageDisplay(msg);
      if (msg.isGroup()) {
        if (msg.action == MessageType.Message) {
          String username =
              G.st.getLocalNickname(msg.senderKeyId(), msg.username());
          title = username + "：" + title;
        }
      }
      Widget label = Text(
        title,
        maxLines: G.st.enableMessagePreviewSingleLine ? 1 : 2,
        style: TextStyle(fontSize: G.st.msgFontSize),
      );
      stack.add(Positioned(
        bottom: -6,
        child: FlatButton(
          color: Color.fromARGB(255, 230, 230, 255),
          child: Container(
            padding: EdgeInsets.all(6),
            child: label,
            width: MediaQuery.of(context).size.width - 12,
          ),
          onPressed: () {
            _scrollToLatest(true);
          },
        ),
      ));
    }

    return new Flexible(
        child: Stack(
      children: stack,
    ));
  }

  Widget _buildQuickSwitcher(BuildContext context, bool horizontal) {
    List<MsgBean> timedMsgs = G.rt.chatObjList;
    if (timedMsgs == null || timedMsgs.length == 0) {
      return null;
    }
    return Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: ListView.builder(
            scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
            itemCount: timedMsgs.length,
            itemBuilder: (context, index) {
              // 消息对象
              MsgBean msg = timedMsgs[index];
              // 圆形头像
              Widget headerView = ClipOval(
                child: new FadeInImage.assetNetwork(
                  placeholder: "assets/icons/default_header.png",
                  //预览图
                  fit: BoxFit.contain,
                  image: API.chatObjHeader(msg),
                  width: 40.0,
                  height: 40.0,
                  placeholderErrorBuilder: (context, error, stackTrace) {
                    return Text('Null');
                  },
                ),
              );
              // 栈对象
              List<Widget> widgets = [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  // 每个头像的间距
                  child: Opacity(
                    child: headerView,
                    opacity: widget.chatObj.isObj(msg) ? 1.0 : 0.5,
                  ),
                  /* decoration: BoxDecoration(
                        border: Border.all(
                            color: widget.chatObj.isObj(msg)
                                ? Theme.of(context).primaryColor
                                : Colors.transparent,
                            width: 2),
                        borderRadius: BorderRadius.circular(22)) */
                )
              ];
              // 未读计数
              if (G.ac.unreadMessageCount.containsKey(msg.keyId())) {
                int count = G.ac.unreadMessageCount[msg.keyId()];
                if (count > 0) {
                  Color c = Colors.blue; // 重要消息：红色
                  bool showNum = true;
                  if (msg.isGroup()) {
                    if (G.st.importantGroups.contains(msg.groupId)) {
                      // 重要群组，也是红色
                      c = Colors.blue;
                    } else if (G.st.enabledGroups.contains(msg.groupId)) {
                      // 通知群组，橙色
                      c = Colors.grey;
                    } else {
                      // 不通知的群组，淡蓝色
                      c = Colors.grey;
                      showNum = false;
                    }
                  }

                  // 添加未读消息计数
                  Widget container;
                  if (showNum) {
                    container = new Container(
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
                        count.toString(), //通知数量
                        style: new TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else {
                    // 只添加一个点
                    container = new Container(
                        padding: EdgeInsets.all(2),
                        margin: EdgeInsets.all(6),
                        decoration: new BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                        child: SizedBox());
                  }

                  Widget position = Positioned(right: 0, child: container);
                  widgets.add(position);
                }
              }

              // 构造可点击区域
              return GestureDetector(
                  child: Stack(
                    children: widgets,
                  ),
                  onTap: () {
                    G.rt.showChatPage(msg);
                  });
            }));
  }

  Widget _buildBody(BuildContext context) {
    // 消息列表
    List<Widget> widgets = [
      _buildListStack(context),
    ];

    // 显示输入框
    if (widget.innerMode) {
      widgets.add(SizedBox(height: 8));
      widgets.add(_buildTextEditor());
    } else {
      widgets.add(_buildLineEditor());
    }

    // 显示快速切换框
    if (G.st.enableQuickSwitcher && !widget.innerMode) {
      Widget w = _buildQuickSwitcher(context, true);
      if (w != null) {
        widgets.add(w);
      }
    }
    // 全面屏底部必须要添加一些空白，否则很难点到
    widgets.add(SizedBox(height: 8));

    Widget body = new Column(
      children: widgets,
    );

    if (G.st.enableChatWidgetRoundedRect) {
      BorderRadius radius;
      if (widget.innerMode) {
        radius = new BorderRadius.all(Radius.circular(G.st.cardRadiusL));
      } else {
        radius = new BorderRadius.only(
            topLeft: Radius.circular(G.st.cardRadiusL),
            topRight: Radius.circular(G.st.cardRadiusL));
      }

      body = Container(
        child: body,
        decoration:
            new BoxDecoration(color: Color(0xFFEEEEEE), borderRadius: radius),
        margin: EdgeInsets.only(left: 4, right: 4, bottom: 4),
      );
    }

    return body;
  }

  AppBar _buildAppBar(BuildContext context) {
    String title =
        G.st.getLocalNickname(widget.chatObj.keyId(), widget.chatObj.title());

    List<Widget> widgets = [
      IconButton(
          onPressed: () {
            // 返回上一页
            Navigator.of(context).pop();
            if (widget.directlyClose) {
              // TODO:离开整个程序，模拟返回键
              // Navigator.of(context).pop();
            }
          },
          icon: Icon(widget.directlyClose ? Icons.close : Icons.arrow_back)),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlatButton(
                child: Text(
                  title ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).textTheme.bodyText2.color,
                      fontWeight: FontWeight.w500),
                ),
                onPressed: () {
                  if (widget.chatObj.isGroup()) {
                    showGroupInfo(widget.chatObj);
                  } else if (widget.chatObj.isPrivate()) {
                    showUserInfo(widget.chatObj);
                  }
                })
          ],
        ),
      ),
      buildMenu()
    ];

    if (_unreadCount > 0) {
      Widget pt = new Container(
        padding: EdgeInsets.all(4),
        decoration: new BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        child: new Text(
          _unreadCount.toString(), //通知数量
          style: new TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      );
      widgets.insert(1, pt);
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          // 整个区域，包括leading等
          child: Row(
            children: widgets,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
          height: kToolbarHeight),
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
        appBar: _buildAppBar(context),
        body: _buildBody(context),
        /* floatingActionButton: _hasNewMsg > 0 && _showGoToBottomButton
            ? FloatingActionButton(
                child: Icon(Icons.arrow_downward),
                onPressed: () {
                  _scrollToLatest(true);
                },
              )
            : null, */
        floatingActionButtonLocation: CustomFloatingActionButtonLocation(
            FloatingActionButtonLocation.miniEndFloat, 0, -56),
      );
    }
  }

  PopupMenuButton buildMenu() {
    List<PopupMenuEntry<ChatMenuItems>> menus = [];
    menus.add(PopupMenuItem<ChatMenuItems>(
      value: ChatMenuItems.Info,
      child: Text(widget.chatObj.isPrivate() ? '用户资料' : '群组资料'),
    ));

    if (widget.chatObj.isGroup()) {
      // menus.add(PopupMenuItem<ChatMenuItems>(
      //   value: ChatMenuItems.Members,
      //   child: Text('查看成员'),
      // ));

      String t =
          G.st.enabledGroups.contains(widget.chatObj.groupId) ? '关闭通知' : '开启通知';
      menus.add(PopupMenuItem<ChatMenuItems>(
        value: ChatMenuItems.EnableNotification,
        child: Text(t, key: ValueKey(t)),
      ));
    }

    /* menus.add(PopupMenuItem<ChatMenuItems>(
      value: ChatMenuItems.CustomName,
      child: Text('本地昵称'),
    )); */

    if (!widget.innerMode) {
      menus.add(PopupMenuItem<ChatMenuItems>(
        value: ChatMenuItems.SendImage,
        child: Text('发送图片'),
      ));
    }

    /* menus.add(PopupMenuItem<ChatMenuItems>(
      value: ChatMenuItems.MessageHistories,
      child: Text('历史消息'),
    )); */

    if (G.st.enableNonsenseMode) {
      // 插入自己的消息
      menus.add(PopupMenuItem<ChatMenuItems>(
        value: ChatMenuItems.InsertFakeRight,
        child: Text('发送假消息'),
      ));
      if (widget.chatObj.isPrivate()) {
        // 插入私聊对方的消息
        menus.add(PopupMenuItem<ChatMenuItems>(
          value: ChatMenuItems.InsertFakeLeft,
          child: Text('接收假消息'),
        ));
      }
    }

    return PopupMenuButton<ChatMenuItems>(
      icon: Icon(Icons.more_vert,
          color: !mounted
              ? Colors.black
              : G.rt.horizontal
                  ? Theme.of(context).textTheme.bodyText2.color
                  : Theme.of(context).iconTheme.color),
      tooltip: '菜单',
      itemBuilder: (BuildContext context) => menus,
      onSelected: (ChatMenuItems result) {
        if (G.rt.currentChatPage != null) {
          G.rt.currentChatPage.unfocusEditor();
        }
        switch (result) {
          case ChatMenuItems.Info:
            if (widget.chatObj.isPrivate()) {
              // 显示用户信息
              showUserInfo(widget.chatObj);
            } else if (widget.chatObj.isGroup()) {
              showGroupInfo(widget.chatObj);
            }
            break;
          case ChatMenuItems.Members:
            showGroupMembers();
            break;
          case ChatMenuItems.EnableNotification:
            setState(() {
              print('开关通知：${widget.chatObj.groupId}');
              G.st.switchEnabledGroup(widget.chatObj.groupId);
            });
            break;
          case ChatMenuItems.CustomName:
            editCustomName();
            break;
          case ChatMenuItems.SendImage:
            getImage();
            break;
          case ChatMenuItems.MessageHistories:
            _loadNetMsgHistory();
            break;
          case ChatMenuItems.InsertFakeRight:
            insertFakeMessage(G.ac.myId);
            break;
          case ChatMenuItems.InsertFakeLeft:
            insertFakeMessage(widget.chatObj.friendId);
            break;
        }
      },
      onCanceled: () {
        if (G.rt.currentChatPage != null) {
          G.rt.currentChatPage.unfocusEditor();
        }
      },
    );
  }

  /// 输入框是否自动聚焦
  bool _autofocusEdit() {
    return Platform.isWindows;
  }

  /// 构造单行输入框
  Widget _buildLineEditor() {
    return new Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(children: <Widget>[
          /* new IconButton(
              icon: new Icon(Icons.image),
              onPressed: getImage,
              color: Theme.of(context).primaryColor), */
          new IconButton(
              icon: new Icon(Icons.face),
              onPressed: showEmojiList,
              color: Theme.of(context).primaryColor),
          // 输入框
          new Flexible(
              child: Container(
            child: new TextField(
              autofocus: _autofocusEdit(),
              controller: _textController,
              onSubmitted: _sendMessage,
              decoration: new InputDecoration(
                hintText: '发送消息',
                enabledBorder: UnderlineInputBorder(
                  // 未获得焦点下划线
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  //获得焦点下划线
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                isDense: true, // 去除很大的间距
              ),
              focusNode: _editorFocus,
              textInputAction: TextInputAction.send,
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            /* decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).primaryColor, width: 0.5),
                borderRadius: BorderRadius.all(Radius.circular(15))), */
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
                  child: new TextField(
                    autofocus: _autofocusEdit(),
                    controller: _textController,
                    decoration: new InputDecoration.collapsed(
                      // 取消奇怪的padding
                      hintText: '发送消息',
                    ),
                    focusNode: _editorFocus,
                    onSubmitted: _sendMessage,
                    minLines: G.st.inputEnterSend ? 1 : 2,
                    maxLines: G.st.inputEnterSend ? 1 : 5,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                ),
                // 底部功能区
                new Container(
                  margin: new EdgeInsets.symmetric(horizontal: 8.0),
                  child: new Row(
                    children: [
                      new IconButton(
                          icon: new Icon(Icons.image),
                          onPressed: getImage,
                          color: Theme.of(context).primaryColor),
                      new IconButton(
                        icon: new Icon(Icons.face),
                        onPressed: showEmojiList,
                        color: Theme.of(context).primaryColor,
                      ),
                      Expanded(child: new SizedBox(width: 100)),
                      new IconButton(
                          icon: new Icon(Icons.send),
                          onPressed: () => _sendMessage(_textController.text),
                          color: Theme.of(context).primaryColor)
                    ],
                    crossAxisAlignment: CrossAxisAlignment.end,
                  ),
                )
              ],
            )),
        onCtrlEnterCallback: () {
          _sendMessage(_textController.text);
        },
        onAltSCallback: () {
          _sendMessage(_textController.text);
        });
  }

  /// 收到消息
  void _messageReceived(MsgBean msg) {
    if (!msg.isObj(widget.chatObj)) {
      return;
    }
    _messages.insert(0, msg);
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
      _scrollToLatest(true);
    }
  }

  void _releaseChatObjData() {
    // 保存状态
    String unsentText = _textController.text;
    if (unsentText.isNotEmpty) {
      G.ac.unsentMessages[widget.chatObj.keyId()] = unsentText;
    } else {
      G.ac.unsentMessages.remove(widget.chatObj.keyId());
    }

    // 清除标记
    G.ac.gettingChatObjColor.clear();
    if (widget.chatObj != null) {
      if (widget.chatObj.isGroup()) {
        G.ac.gettingGroupMembers.remove(widget.chatObj.groupId);
        // G.ac.groupList[widget.chatObj.groupId]?.ignoredMembers?.clear();
      }
      G.ac.unreadMessageCount.remove(widget.chatObj.keyId());
    }
  }

  @override
  void dispose() {
    _releaseChatObjData();
    _movedLarge = true;
    eventBusFn.cancel();
    super.dispose();
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

  void _setMessage(String text) {
    _textController.text = text;
    _textController.selection =
        TextSelection.fromPosition(TextPosition(offset: text.length));
  }

  void _insertMessage(String text) {
    int start = _textController.selection.start;
    int end = _textController.selection.end;
    if (start == -1 && end == -1) {
      // 没有任何位置，直接添加到末尾
      _textController.text = _textController.text + text;
      _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length));
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

  void _removeEditorFocus() {
    _editorFocus.unfocus();
  }

  /// 获取图片
  /// @param immediate 是否立刻上传
  Future getImage() async {
    if (Platform.isWindows) {
      var clipboardData =
          await Clipboard.getData(Clipboard.kTextPlain); //获取粘贴板中的文本
      if (clipboardData != null) {
        print(clipboardData); //打印内容
      }
    }

    bool sendDirectly = _textController.text.isEmpty;
    ImagePickers.pickerPaths().then((List<Media> medias) {
      /// medias 照片路径信息 Photo path information
      medias.forEach((media) {
        _uploadImage(File(media.path), sendDirectly);
      });
    });

    /* var image = await ImagePickerSaver.pickImage(source: ImageSource.gallery);
    if (image == null) {
      // 取消选择图片
      Fluttertoast.showToast(
          msg: "取消选择图片", gravity: ToastGravity.CENTER, textColor: Colors.grey);
      return;
    }
    _uploadImage(image, sendDirectly); */
  }

  void _uploadImage(File image, bool sendDirectly) async {
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
      if (data['hash'] == null) {
        Fluttertoast.showToast(
            msg: "服务器无效，返回：$data",
            gravity: ToastGravity.CENTER,
            textColor: Colors.grey);
        return;
      }
      String hash = data['hash'];
      String text = "[CQ:image,file=${G.st.server}/files/$hash]";
      if (sendDirectly) {
        // 空文本，直接发送
        G.cs.sendMsg(widget.chatObj, text);
      } else {
        // 有文本，接到现有文本后面
        _insertMessage(text);
      }
    } else {
      Fluttertoast.showToast(
          msg: "图片上传失败：${response.statusCode}",
          gravity: ToastGravity.CENTER,
          textColor: Colors.grey);
    }
  }

  void _loadMsgHistory() {
    // 没有这个对象的消息记录，但应该不会，是出错了
    if (!G.ac.allMessages.containsKey(widget.chatObj.keyId())) {
      print('warning: 未找到该聊天对象的消息记录列表');
      _blankHistory = true;
      G.ac.allMessages[widget.chatObj.keyId()] = [];
    }

    // 获取需要加载的位置
    List<MsgBean> totalList = G.ac.allMessages[widget.chatObj.keyId()];
    int endIndex = totalList.length; // 最后一个需要加载的位置+1（不包括）
    int startIndex = 0;
    if (_messages != null && _messages.length > 0) {
      // 判断最老消息的位置
      int messageId = _messages.last.messageId;
      if (messageId == null) {
        int i = _messages.length;
        while (--i >= 0) {
          messageId = _messages[i].messageId;
          if (messageId != null) {
            break;
          }
        }
      }

      // 理论上来讲，_message.length = totalList后半段
      while (endIndex-- > 0 && totalList[endIndex].messageId != messageId) {}
      if (endIndex <= 0) {
        print('已加载完消息：${_messages.length}>=${totalList.length}');
        if (_messages.length >= totalList.length) {
          _blankHistory = true;
          _loadNetMsgHistory();
          return;
        } else {
          // 这里可能是出问题了
          endIndex = totalList.length - _messages.length - 1;
        }
      }
    } else if (totalList == null || totalList.length == 0) {
      _blankHistory = true;
      _loadNetMsgHistory();
      return;
    } else {
      // 加载最新的
    }
    startIndex = max(0, endIndex - G.st.loadMsgHistoryCount);

    // 进行加载操作
    var deltaBottom = _scrollController.position.extentAfter; // 距离底部的位置
    print(
        '加载历史记录，${_messages.length} in ${totalList.length} margin_bottom:$deltaBottom, $_keepScrollBottom');
    setState(() {
      for (int i = endIndex - 1; i >= startIndex; i--) {
        _messages.add(totalList[i]);
      }
    });
    // 恢复底部位置
    /* SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController
          .jumpTo(_scrollController.position.maxScrollExtent - deltaBottom);
    }); */
  }

  void _loadNetMsgHistory() {
    print("加载云端消息历史");
    List<MsgBean> list = G.ac.allMessages[widget.chatObj.keyId()];
    int earliestId;
    if (list != null) {
      int i = -1;
      while (++i < list.length) {
        if (list[i].action == MessageType.Message) {
          earliestId = list[i].messageSeq;
          break;
        }
      }
    }

    if (widget.chatObj.isPrivate()) {
      // TODO: 加载私聊消息
    } else if (widget.chatObj.isGroup()) {
      // 加载群聊消息
      G.cs.getGroupMessageHistories(widget.chatObj.groupId, earliestId);
    }
  }

  void showEmojiList() {
    final size = MediaQuery.of(context).size;
    final twidth = size.width / 2;
    final theight = size.height * 3 / 5;

    // 如果是直接发送图片，则取消输入焦点
    if (_textController.text == null || _textController.text.isEmpty) {
      _removeEditorFocus();
    }

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            contentPadding: EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
            content: Container(
                constraints: BoxConstraints(
                    minWidth: twidth,
                    maxWidth: twidth,
                    minHeight: theight,
                    maxHeight: theight),
                child: EmojiGrid(
                  sendEmojiCallback: (cq) {
                    if (_textController.text.isEmpty) {
                      _sendMessage(cq);
                    } else {
                      _insertMessage(cq);
                    }
                  },
                )),
          );
        });
  }

  void showUserInfo(MsgBean msg) {
    _removeEditorFocus();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Container(
              constraints:
                  BoxConstraints(minWidth: 200, minHeight: 100, maxHeight: 250),
              child: UserProfileWidget(chatObj: msg),
            ),
            contentPadding: EdgeInsets.all(5),
          );
        });
  }

  void showGroupInfo(MsgBean msg) {
    G.cs.refreshGroupMembers(widget.chatObj.groupId);
    _removeEditorFocus();
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Container(
              constraints:
                  BoxConstraints(minWidth: 200, minHeight: 100, maxHeight: 300),
              child: GroupProfileWidget(
                  chatObj: msg, showGroupMembers: showGroupMembers),
            ),
            contentPadding: EdgeInsets.all(5),
          );
        });
  }

  void showGroupMembers() {
    // G.cs.refreshGroupMembers(widget.chatObj.groupId);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Container(
              constraints: BoxConstraints(minWidth: 350, maxHeight: 500),
              child: SearchPage(
                members: G.ac.groupList[widget.chatObj.groupId].members,
                selectCallback: (MsgBean msg) {
                  G.rt.showChatPage(msg);
                },
              ),
            ),
            contentPadding: EdgeInsets.all(5),
          );
        });
  }

  void editCustomName() {
    int keyId = widget.chatObj.keyId();
    String curName = G.st.getLocalNickname(keyId, widget.chatObj.title());

    TextEditingController controller = TextEditingController();
    controller.text = curName;
    if (curName.isNotEmpty) {
      controller.selection =
          TextSelection(baseOffset: 0, extentOffset: curName.length);
    }

    var confirm = () {
      setState(() {
        G.st.setLocalNickname(keyId, controller.text);
        Navigator.pop(context);
        G.ac.eventBus.fire(EventFn(Event.refreshState, {}));
      });
    };

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('请输入本地昵称'),
            content: TextField(
              decoration: InputDecoration(
                hintText: '不影响真实昵称',
              ),
              controller: controller,
              autofocus: true,
              onSubmitted: (text) {
                confirm();
              },
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  confirm();
                },
                child: Text('确定'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('取消'),
              ),
            ],
          );
        });
  }

  void insertFakeMessage(int senderId) {
    var createFakePrivateMsg = (String str) {
      bool isMe = senderId == G.ac.myId;
      int friendId = widget.chatObj.friendId;
      int targetId = isMe ? friendId : G.ac.myId;
      String senderName = isMe ? G.ac.myNickname : widget.chatObj.nickname;
      var fakeMsg = {
        'post_type': isMe ? 'message_sent' : 'message',
        'message_type': 'private',
        'sub_type': 'friend',
        'message': str,
        'raw_message': str,
        'message_id': DateTime.now().millisecondsSinceEpoch,
        'target_id': targetId,
        'self_id': G.ac.myId,
        'sender': {
          'user_id': senderId,
          'nickname': senderName,
          'remark': isMe ? null : G.ac.friendList[friendId].remark
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch / 1000
      };
      print(fakeMsg);
      G.cs.parsePrivateMessage(fakeMsg);
    };

    var createFakeGroupMsg = (String str) {
      bool isMe = senderId == G.ac.myId;
      int groupId = widget.chatObj.groupId;
      int keyId = widget.chatObj.keyId();
      // 获取这个人旧的信息（如果不是自己的，则肯定有）
      MsgBean oldMsg;
      G.ac.allMessages[keyId].forEach((element) {
        if (element.senderId == senderId) {
          oldMsg = element;
        }
      });
      if (!isMe && oldMsg == null) {
        print('error: 未找到该用户的旧信息：$senderId');
        return;
      }

      var fakeMsg = {
        'post_type': 'message',
        'message_type': 'group',
        'sub_type': 'normal',
        'group_id': groupId,
        'message_seq': 0,
        'message': str,
        'raw_message': str,
        'message_id': DateTime.now().millisecondsSinceEpoch,
        'self_id': G.ac.myId,
        'sender': {
          'user_id': senderId,
          'card': oldMsg != null ? oldMsg.groupCard : G.ac.myId,
          'nickname': oldMsg != null ? oldMsg.nickname : G.ac.myId,
          'remark': isMe ? null : oldMsg.remark,
          'role': oldMsg != null ? oldMsg.role : null,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch / 1000
      };
      G.cs.parseGroupMessage(fakeMsg);
    };

    TextEditingController controller = TextEditingController();

    var confirm = () {
      setState(() {
        Navigator.pop(context);
        String text = controller.text;
        if (text == null || text.isEmpty) {
          return;
        }
        // 创建对应的消息
        if (widget.chatObj.isPrivate()) {
          createFakePrivateMsg(text);
        } else if (widget.chatObj.isGroup()) {
          createFakeGroupMsg(text);
        }
      });
    };

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('请输入虚拟消息，只在本地显示，不会真正发送'),
            content: TextField(
              decoration: InputDecoration(
                hintText: '消息内容',
              ),
              controller: controller,
              autofocus: true,
              onSubmitted: (text) {
                confirm();
              },
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  confirm();
                },
                child: Text('确定'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('取消'),
              ),
            ],
          );
        });
  }

  /// 切换到快速切换的第一条未读消息
  void switchToUnreadObject() {
    List<MsgBean> timedMsgs = G.rt.chatObjList;
    if (timedMsgs == null || timedMsgs.length <= 1) {
      return;
    }

    // 生成列表
    List<MsgBean> msgs = [];
    List<MessageImportance> imps = [];
    for (int i = 0; i < timedMsgs.length; i++) {
      MsgBean msg = timedMsgs[i];
      if (G.ac.unreadMessageCount.containsKey(msg.keyId()) &&
          G.ac.unreadMessageCount[msg.keyId()] > 0) {
        msgs.add(msg);
        imps.add(G.cs.getMsgImportance(msg));
      }
    }

    // 很重要消息
    for (int i = 0; i < msgs.length; i++) {
      if (imps[i] == MessageImportance.Very) {
        widget.setObject(msgs[i]);
        return;
      }
    }

    // 小重要消息
    for (int i = 0; i < msgs.length; i++) {
      if (imps[i] == MessageImportance.Little) {
        widget.setObject(msgs[i]);
        return;
      }
    }

    // 普通消息
    for (int i = 0; i < msgs.length; i++) {
      if (imps[i] == MessageImportance.Normal) {
        widget.setObject(msgs[i]);
        return;
      }
    }

    // 不重要消息
    for (int i = 0; i < msgs.length; i++) {
      if (imps[i] == MessageImportance.Ignored) {
        widget.setObject(msgs[i]);
        return;
      }
    }
  }

  /// 切换到快速切换的上一条消息
  void switchToPreviousObject() {
    List<MsgBean> timedMsgs = G.rt.chatObjList;
    if (timedMsgs == null || timedMsgs.length <= 1) {
      return;
    }
    int index = timedMsgs.indexOf(widget.chatObj);
    if (index == -1 || index == 0) {
      return;
    }
    widget.setObject(timedMsgs[index - 1]);
  }

  /// 切换到快速切换的下一条消息
  void switchToNextObject() {
    List<MsgBean> timedMsgs = G.rt.chatObjList;
    if (timedMsgs == null || timedMsgs.length <= 1) {
      return;
    }
    int index = timedMsgs.indexOf(widget.chatObj);
    if (index == -1 || index == timedMsgs.length - 1) {
      return;
    }
    widget.setObject(timedMsgs[index + 1]);
  }
}

final ctrlEnterKeySet = LogicalKeySet(
  Platform.isMacOS
      ? LogicalKeyboardKey.meta
      : LogicalKeyboardKey.control, // Windows:control, MacOS:meta
  LogicalKeyboardKey.arrowUp,
);

final altSKeySet = LogicalKeySet(
  Platform.isMacOS
      ? LogicalKeyboardKey.meta
      : LogicalKeyboardKey.control, // Windows:control, MacOS:meta
  LogicalKeyboardKey.arrowUp,
);

class CtrlEnterIntent extends Intent {}

class AltSIntent extends Intent {}

class CtrlEnterWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback onCtrlEnterCallback;
  final VoidCallback onAltSCallback;

  const CtrlEnterWidget(
      {Key key,
      @required this.child,
      @required this.onCtrlEnterCallback,
      @required this.onAltSCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(child: child, autofocus: true, shortcuts: {
      ctrlEnterKeySet: CtrlEnterIntent(),
      altSKeySet: AltSIntent()
    }, actions: {
      CtrlEnterIntent:
          CallbackAction(onInvoke: (e) => onCtrlEnterCallback?.call()),
      AltSIntent: CallbackAction(onInvoke: (e) => onAltSCallback?.call()),
    });
  }
}
