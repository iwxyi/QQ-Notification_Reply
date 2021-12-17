import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:date_format/date_format.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_pickers/image_pickers.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/pages/profile/user_profile_widget.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:qqnotificationreply/widgets/customfloatingactionbuttonlocation.dart';

import 'emoji_grid.dart';
import 'message_view.dart';

enum ChatMenuItems { Info, EnableNotification, CustomName }

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
      if (widget.chatObj != null) {
        // 去掉正在获取群成员的flag
        G.ac.gettingGroupMembers.remove(widget.chatObj.keyId());
      }
      widget.jumpMsg = null;

      // 设置为新的
      widget.chatObj = msg;
      setState(() {
        _messages = [];
        _initMessages();
      });

      if (!widget.innerMode) {
        G.rt.updateChatPageUnreadCount();
      }
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
      if (event.event == Event.messageRaw) {
        _messageReceived(event.data);
      } else if (event.event == Event.groupMember) {
        if (mounted) {
          setState(() {});
        }
      } else if (event.event == Event.messageRecall) {
        if (widget.chatObj.isObj(event.data)) {
          print('message recall, refresh state');
          if (mounted) {
            setState(() {});
          }
        }
      } else if (event.event == Event.refreshState) {
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

    _initMessages();
  }

  void _initMessages() {
    MsgBean msg = widget.chatObj;
    // 获取历史消息
    _messages = [];
    if (G.ac.allMessages.containsKey(msg.keyId())) {
      List<MsgBean> list = G.ac.allMessages[msg.keyId()];
      // _messages = list.sublist(max(0, list.length - G.st.loadMsgHistoryCount));
      // 逆序
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

    G.rt.updateChatPageUnreadCount();
  }

  /// 跳转到最新的位置
  void _scrollToLatest(bool ani) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
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

  Widget _buildListStack(BuildContext context) {
    List<Widget> stack = [
      new ListView.separated(
        separatorBuilder: (BuildContext context, int index) {
          if (index < _messages.length - 1) {
            int ts0 = _messages[index].timestamp;
            int ts1 = _messages[index + 1].timestamp;
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
        reverse: true,
        // padding: new EdgeInsets.all(8.0),
        itemBuilder: (context, int index) => MessageView(
            _messages[index],
            index >= _messages.length - 1
                ? false
                : _messages[index + 1].senderId == _messages[index].senderId,
            ValueKey(_messages[index].messageId), loadFinishedCallback: () {
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
          // 本地删除消息
          setState(() {
            _messages
                .removeWhere((element) => element.messageId == msg.messageId);
            G.ac.allMessages[msg.keyId()]
                .removeWhere((element) => element.messageId == msg.messageId);
          });
        }, unfocusEditorCallback: () {
          _removeEditorFocus();
        }, showUserInfoCallback: (int id, nickname) {
          showUserInfo(id, nickname);
        }),
        itemCount: _messages.length,
        controller: _scrollController,
      ),
    ];

    // 显示跳转的消息
    if (widget.jumpMsg != null &&
        ((DateTime.now().millisecondsSinceEpoch - widget.jumpMsgTimestamp) <
            G.st.chatTopMsgDisplayMSecond)) {
      MsgBean msg = widget.jumpMsg;
      String title = msg.username() + "：" + G.cs.getMessageDisplay(msg);
      if (msg.isGroup()) {
        String gn = G.st.getLocalNickname(msg.keyId(), msg.groupName);
        title = '[$gn] ' + title;
      }
      Widget label = Text(
        title,
        maxLines: 2,
        style: TextStyle(fontSize: G.st.msgFontSize),
      );
      stack.add(Positioned(
        top: -4, // 因为上面有几个像素阴影，会露出后面的
        child: FlatButton(
          color: Color.fromARGB(255, 230, 230, 255),
          child: Container(
            padding: EdgeInsets.all(6),
            child: label,
            width: MediaQuery.of(context).size.width,
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
        title = msg.username() + "：" + title;
      }
      Widget label = Text(
        title,
        maxLines: 2,
        style: TextStyle(fontSize: G.st.msgFontSize),
      );
      stack.add(Positioned(
        bottom: -4,
        child: FlatButton(
          color: Color.fromARGB(255, 230, 230, 255),
          child: Container(
            padding: EdgeInsets.all(6),
            child: label,
            width: MediaQuery.of(context).size.width,
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

  Widget _buildBody(BuildContext context) {
    return new Column(
      children: <Widget>[
        // 消息列表
        _buildListStack(context),
        SizedBox(height: 8),
        // 输入框
        widget.innerMode ? _buildTextEditor() : _buildLineEditor(),
        SizedBox(height: 8),
      ],
    );
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
            }
          },
          icon: Icon(widget.directlyClose ? Icons.close : Icons.arrow_back)),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).textTheme.bodyText2.color,
              fontWeight: FontWeight.w500),
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
      enabled: false,
    ));

    if (widget.chatObj.isGroup()) {
      String t =
          G.st.enabledGroups.contains(widget.chatObj.groupId) ? '关闭通知' : '开启通知';
      menus.add(PopupMenuItem<ChatMenuItems>(
        value: ChatMenuItems.EnableNotification,
        child: Text(t, key: ValueKey(t)),
      ));
    }

    menus.add(PopupMenuItem<ChatMenuItems>(
      value: ChatMenuItems.CustomName,
      child: Text('本地昵称'),
    ));

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
            break;
          case ChatMenuItems.EnableNotification:
            setState(() {
              print('开关通知：${widget.chatObj.groupId}');
              G.st.switchEnabledGroup(widget.chatObj.groupId);
            });
            break;
          case ChatMenuItems.CustomName:
            TextEditingController controller = TextEditingController();
            int keyId = widget.chatObj.keyId();
            String curName =
                G.st.getLocalNickname(keyId, widget.chatObj.title());
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
                          Navigator.pop(context);
                        },
                        child: Text('取消'),
                      ),
                      TextButton(
                        onPressed: () {
                          confirm();
                        },
                        child: Text('确定'),
                      ),
                    ],
                  );
                });
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
          new IconButton(
              icon: new Icon(Icons.image),
              onPressed: getImage,
              color: Theme.of(context).primaryColor),
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

  @override
  void dispose() {
    G.ac.gettingChatObjColor.clear();
    if (widget.chatObj != null) {
      G.ac.gettingGroupMembers.remove(widget.chatObj.keyId());
      G.ac.unreadMessageCount.remove(widget.chatObj.keyId());
    }
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
      return;
    }

    // 获取需要加载的位置
    List<MsgBean> list = G.ac.allMessages[widget.chatObj.keyId()];
    int endIndex = list.length; // 最后一个需要加载的位置+1（不包括）
    int startIndex = 0;
    if (_messages != null && _messages.length > 0) {
      // 判断最老消息的位置
      int messageId = _messages.last.messageId;
      while (endIndex-- > 0 && list[endIndex].messageId != messageId) {}
      if (endIndex <= 0) {
        print('没有历史消息，${list.length}>=${_messages.length}');
        _blankHistory = true;
        return;
      }
    } else {
      // 加载最新的
    }
    startIndex = max(0, endIndex - G.st.loadMsgHistoryCount);

    // 进行加载操作
    var deltaBottom = _scrollController.position.extentAfter; // 距离底部的位置
    print('加载历史记录，margin_bottom:$deltaBottom, $_keepScrollBottom');
    setState(() {
      for (int i = endIndex - 1; i >= startIndex; i--) {
        _messages.add(list[i]);
      }
    });
    // 恢复底部位置
    /* SchedulerBinding.instance.addPostFrameCallback((_) {
      _scrollController
          .jumpTo(_scrollController.position.maxScrollExtent - deltaBottom);
    }); */
  }

  void showEmojiList() {
    final size = MediaQuery.of(context).size;
    final twidth = size.width / 2;
    final theight = size.height * 4 / 5;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
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

  void showUserInfo(int userId, String nickname) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Container(
              constraints: BoxConstraints(minWidth: 350, maxHeight: 500),
              child: UserProfileWidget(userId: userId, nickname: nickname),
            ),
            contentPadding: EdgeInsets.all(5),
          );
        });
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
