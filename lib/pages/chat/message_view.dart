import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:color_thief_flutter/color_thief_flutter.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qqnotificationreply/global/api.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:qqnotificationreply/utils/color_util.dart';
import 'package:qqnotificationreply/widgets/video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/slide_images_page.dart';
import '../main/search_page.dart';

/// 构造发送的信息
/// 每一条消息显示的复杂对象
class MessageView extends StatefulWidget {
  final MsgBean msg;
  final bool isNext;

  final loadFinishedCallback;
  final jumpMessageCallback;
  final addMessageCallback;
  final sendMessageCallback;
  final deleteMessageCallback;
  final unfocusEditorCallback;
  final showUserInfoCallback;

  MessageView(this.msg, this.isNext, Key key,
      {this.loadFinishedCallback,
      this.jumpMessageCallback,
      this.addMessageCallback,
      this.sendMessageCallback,
      this.deleteMessageCallback,
      this.unfocusEditorCallback,
      this.showUserInfoCallback})
      : super(key: key);

  @override
  _MessageViewState createState() => _MessageViewState(msg, isNext);
}

class _MessageViewState extends State<MessageView> {
  final bool isNext;
  final MsgBean msg;
  bool hasCompleted = false;
  GlobalKey anchorKey = GlobalKey();
  bool pressing = false;

  // 媒体播放
  AudioPlayer audioPlayer;
  String currentAudio = '';

  _MessageViewState(this.msg, this.isNext);

  /// 一整行
  Widget _buildMessageLine() {
    // 判断左右
    bool isSelf = msg.senderId == G.ac.myId;

    // 消息列的上下控件，是否显示昵称
    List<Widget> vWidgets = [];
    if (!isSelf && !isNext) {
      vWidgets.add(_buildNicknameView());
    }
    vWidgets.add(_buildMessageContainer());

    Widget vWidget = Flexible(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: vWidgets),
    );

    // 头像和消息的左右顺序
    List<Widget> hWidgets;
    if (isSelf) {
      hWidgets = [SizedBox(width: 72, height: 48), vWidget, _buildHeaderView()];
    } else {
      hWidgets = [_buildHeaderView(), vWidget, SizedBox(width: 72, height: 48)];
    }

    Widget container = new Container(
      child: new Row(
          mainAxisAlignment:
              isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: hWidgets),
      padding: EdgeInsets.only(top: isNext ? 0 : 6),
    );

    // 撤回的消息变成半透明
    if (msg.recalled) {
      container = Opacity(opacity: 0.3, child: container);
    }

    return container;
  }

  /// 构建头像控件
  Widget _buildHeaderView() {
    if (isNext) {
      // 24*2 + 12 + 12 = 72
      return SizedBox(width: 72, height: 48);
    }

    String headerUrl = API.userHeader(msg.senderId);
    Widget container = new Container(
        margin: const EdgeInsets.only(left: 12.0, right: 12.0),
        child: new CircleAvatar(
          backgroundImage: NetworkImage(headerUrl),
          radius: 24.0,
          backgroundColor: Colors.transparent,
        ));

    return GestureDetector(
        child: container,
        onTap: () {
          // 头像单击
          widget.showUserInfoCallback(msg);
        },
        onLongPress: () {
          widget.addMessageCallback('[CQ:at,qq=${msg.senderId}] ');
        });
  }

  Color _getColorfulNickname(int keyId, Color def) {
    if (G.st.enableColorfulChatName &&
        !G.ac.gettingChatObjColor.contains(keyId)) {
      if (G.ac.chatObjColor.containsKey(keyId)) {
        return ColorUtil.rangeLight(G.ac.chatObjColor[keyId],
            G.st.colorfulChatNameFont - 0.1, G.st.colorfulChatNameFont + 0.1);
      } else {
        G.ac.gettingChatObjColor.add(keyId);
        String url = API.userHeader(msg.senderId);
        getColorFromUrl(url).then((v) {
          if (v == null) {
            // 一直保持获取状态，就不使用了
            return;
          }
          print('主题色：' + msg.username() + ": " + v.toString());
          G.ac.gettingChatObjColor.remove(keyId);
          Color c = Color.fromARGB(255, v[0], v[1], v[2]);
          G.ac.chatObjColor[keyId] = c;
          if (mounted) {
            setState(() {});
          }
        });
      }
    }
    return def;
  }

  /// 构建昵称控件
  /// 自己发的没有昵称
  Widget _buildNicknameView() {
    Color c = _getColorfulNickname(msg.senderKeyId(), G.st.msgNicknameColor);
    return new Container(
      margin: const EdgeInsets.only(top: 5.0),
      child: new Text(
        msg.username(), // 用户昵称
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: c, fontSize: 16),
      ),
    );
  }

  /// 构建消息控件
  /// 最外层的直接方法
  Widget _buildMessageContainer() {
    EdgeInsets bubblePadding = EdgeInsets.all(8.0); // 消息内部间距
    EdgeInsets bubbleMargin = EdgeInsets.only(top: 3.0, bottom: 3.0);
    Widget bubbleContent;

    String text = msg.message ?? '';
    Match match;
    if (msg.isPureMessage() &&
        (match = RegExp(r'^\[CQ:image,file=[^\]]+?,url=([^\]]+?)(,[^\]]+?)?\]$')
                .firstMatch(text)) !=
            null) {
      // 如果是图片
      String url = match.group(1);
      bubbleContent = _buildImageWidget(url);
      bubblePadding = EdgeInsets.only();
    } else {
      // 动作、文件、纯文本或者富文本
      bubbleContent = _buildRichContentWidget(msg);
    }

    // 显示圆角、间距、背景气泡
    Color c =
        msg.senderId != G.ac.myId ? G.st.msgBubbleColor : G.st.msgBubbleColor2;
    if (G.st.enableColorfulChatBubble &&
        !G.ac.gettingChatObjColor.contains(msg.senderKeyId())) {
      if (G.ac.chatObjColor.containsKey(msg.senderKeyId())) {
        c = ColorUtil.fixedLight(
            G.ac.chatObjColor[msg.senderKeyId()], G.st.colorfulChatBubbleBg);
      } else {
        G.ac.gettingChatObjColor.add(msg.senderKeyId());
        String url = API.userHeader(msg.senderId);
        getColorFromUrl(url).then((v) {
          print('主题色：' + msg.username() + ": " + v.toString());
          G.ac.gettingChatObjColor.remove(msg.senderKeyId());
          setState(() {
            Color c = Color.fromARGB(255, v[0], v[1], v[2]);
            G.ac.chatObjColor[msg.senderKeyId()] = c;
          });
        });
      }
    }
    if (pressing) {
      // 正在按下，需要深色一点
      c = ColorUtil.modifyLight(c, -0.07);
    }
    Widget container = Container(
      child: bubbleContent,
      padding: bubblePadding,
      margin: bubbleMargin, // 上限间距
      decoration: new BoxDecoration(
        color: c,
        borderRadius: BorderRadius.all(Radius.circular(G.st.msgBubbleRadius)),
      ),
    );

    // 手势操作
    return GestureDetector(
      key: anchorKey,
      child: container,
      onTapDown: (e) {
        // 按下极短时间没动
        setState(() {
          pressing = true;
        });
        // print('onTapDown');
      },
      onTapUp: (e) {
        // 单击松起（在此之前会触发onLongPressCancel）
        setState(() {
          pressing = false;
        });
        // print('onTapUp');
      },
      onTapCancel: () {
        // 触发onTapDown后拖拽会触发cancel
        setState(() {
          pressing = false;
        });
        // print('onTapCancel');
      },
      onLongPressStart: (details) {
        // 长按事件
        setState(() {
          pressing = true;
        });
        // print('onLongPressStart');

        // 消息长按菜单
        // 会触发onLongPressCancel
        _showMenu(context, details);
      },
      onLongPressCancel: () {
        // 单击也会触发onLongPressCancel
        setState(() {
          pressing = false;
        });
        // print('onLongPressCancel');
      },
    );
  }

  /// 构建富文本消息框的入口
  Widget _buildRichContentWidget(MsgBean msg,
      {String useMessage, int recursion = 0}) {
    String message = useMessage ?? msg.message ?? G.cs.getMessageDisplay(msg);

    // 是回复的消息，要单独提取
    Widget replyWidget;
    if (message.contains("[CQ:reply,")) {
      RegExp re = new RegExp(r"\[CQ:reply,id=(-?\w+)\]\s*(\[CQ:at,qq=\d+\])?");
      RegExpMatch match = re.firstMatch(message);
      if (match != null) {
        message = message.replaceAll(match.group(0), ""); // 去掉回复的代码
        int messageId = int.parse(match.group(1)); // 回复ID
        replyWidget =
            _buildReplyRichWidget(msg, messageId, recursion: recursion + 1);
      }
    }

    // 判断是卡片还是纯文本
    /*if (message.contains("[CQ:json,")) {
      return _buildJsonCardWidget(msg);
    }*/

    Widget contentWidget =
        _buildRichTextSpans(msg, message, recursion: recursion);
    if (replyWidget != null) {
      // 回复-内容 进行column连接
      contentWidget = Column(
        children: [replyWidget, contentWidget],
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    }
    return contentWidget;
  }

  /// 构建纯内容的span
  /// 不包含回复、JSON等单独大格式
  Widget _buildRichTextSpans(MsgBean msg, String originText,
      {int recursion = 0}) {
    List<InlineSpan> spans = [];
    RegExp re =
        new RegExp(r"\[CQ:(\w+),?([^\]]*)\]|https?://\S+|\d{5,}|\w+@[\w\.]+");
    Iterable<RegExpMatch> matches = re.allMatches(originText);
    if (matches.length == 0) {
      // 纯文本
      return _buildPureTextWidget(msg, originText);
    }

    // 是富文本了
    int pos = 0;
    int replyEndPos = -2; // reply结束的时候，用来取消后面的艾特
    // 遍历每一个CQ
    for (int i = 0; i < matches.length; i++) {
      RegExpMatch match = matches.elementAt(i);

      // 前面的纯文本[match]
      if (match.start > pos) {
        var span = _buildPureTextSpan(originText.substring(pos, match.start));
        spans.add(span);
      }

      // 各类型判断
      String matchedText = match.group(0);
      InlineSpan span;
      InlineSpan spanAfter;
      bool insertFirst = false; // 一些图片是否插入到前面

      if (match.group(0).startsWith("[CQ:")) {
        // 是CQ码，挨个判断匹配到的内容
        String mAll = match.group(0);
        String cqCode = match.group(1); // CQ码
        String params = match.group(2); // 参数字符串

        // 判断CQ码
        Match mat;
        if (cqCode == 'face') {
          // 替换成表情
          RegExp re = RegExp(r'^id=(\d+)(?:,(.+))?$');
          if ((mat = re.firstMatch(params)) != null) {
            String id = mat[1];
            if (File("assets/qq_face/$id.gif").existsSync()) {
              double height = 28;
              double scale = 2;
              if (mat[2] != null && mat[2] == 'type=sticker') {
                height = 56;
                scale = 1;
              }
              span = new WidgetSpan(
                  child: Image.asset("assets/qq_face/$id.gif",
                      scale: scale, height: height));
            } else {
              span = new TextSpan(text: '[表情]');
            }
          } else {
            span = new TextSpan(text: '[表情]');
          }
        } else if (cqCode == 'image') {
          // 替换成图片
          RegExp imageRE = RegExp(r'^file=.+?,url=([^,]+)');
          if ((mat = imageRE.firstMatch(params)) != null) {
            String url = mat[1];
            span = new WidgetSpan(
                child: _buildImageWidget(url, recursion: recursion));
          } else if (RegExp(r"\[CQ:image,type=flash,.+?\]").hasMatch(mAll)) {
            span = new TextSpan(text: '[闪照]');
          } else {
            span = new TextSpan(text: '[图片]');
          }
        } else if (cqCode == 'redbag') {
          RegExp rgRE = RegExp(r'^title=(.+)$');
          if ((mat = rgRE.firstMatch(params)) != null) {
            String title = mat[1];
            span = new WidgetSpan(
                child: Image.asset(
              "assets/icons/redbag.png",
              scale: 2,
            ));
            spanAfter = new TextSpan(text: "[$title]");
          } else {
            span =
                new WidgetSpan(child: Image.asset("assets/icons/redbag.png"));
          }
        } else if (cqCode == 'at') {
          RegExp re = RegExp(r'^qq=(\w+)$');
          if ((mat = re.firstMatch(params)) != null) {
            String id = mat[1];
            if (id == 'all') {
              // @全体成员
              Color c = G.st.msgLinkColor;
              if (G.st.enableColorfulChatName) {}
              span = new TextSpan(
                  text: "@全体成员",
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      print('@全体成员');
                      if (widget.addMessageCallback != null) {
                        widget.addMessageCallback(mAll);
                      }
                    },
                  style: TextStyle(fontSize: G.st.msgFontSize, color: c));
            } else if (match.start != replyEndPos) {
              // @qq，已经判断了不是reply自带的at
              String username =
                  G.ac.getGroupMemberName(int.parse(id), msg.groupId);
              if (username == null) {
                username = id;
                if (msg.isGroup()) {
                  G.cs.refreshGroupMembers(msg.groupId, userId: int.parse(id));
                }
              }
              span = new TextSpan(
                  text: "@$username",
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      print('@$username');
                      if (widget.addMessageCallback != null) {
                        widget.addMessageCallback(mAll);
                      }
                    },
                  style: TextStyle(
                      fontSize: G.st.msgFontSize,
                      color: _getColorfulNickname(
                          MsgBean(
                                  friendId: int.parse(id),
                                  senderId: int.parse(id))
                              .keyId(),
                          G.st.msgLinkColor)));
            }
          }
        } else if (cqCode == 'video') {
          // 视频播放
          RegExp re = RegExp(r'^\[CQ:video,file=(.+?)(?:\.video)?,url=(.+)\]$');
          if ((mat = re.firstMatch(mAll)) != null) {
            String url = mat.group(2);
            url = url.replaceAll('&amp;', '&');
            span = new TextSpan(
                text: "[视频]",
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    print('播放视频：$url');
                    if (widget.unfocusEditorCallback != null) {
                      widget.unfocusEditorCallback();
                    }
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return new VideoPlayerScreen(url: url);
                    }));
                  },
                style: TextStyle(
                    fontSize: G.st.msgFontSize, color: G.st.msgLinkColor));
          } else {
            // 意外的视频格式
            span = new TextSpan(text: '[视频]');
          }
        } else if (cqCode == 'record') {
          // 语音播放
          RegExp re = RegExp(
              r'^\[CQ:record,file=(.+?)(?:\.(?:si?lk|amr))?,url=(.*)\]$');
          if ((mat = re.firstMatch(mAll)) != null) {
            String url = mat.group(2);
            url = url.replaceAll('&amp;', '&');
            print('播放语音：' + url);
            span = new TextSpan(
                text: "[语音]",
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    print('播放/暂停语音：$url');
                    if (audioPlayer == null) {
                      // 初始化音频播放
                      audioPlayer = AudioPlayer();
                      audioPlayer.onPlayerCompletion.listen((event) {
                        print('audio complete');
                        currentAudio = null;
                      });
                    }
                    if (currentAudio != null && currentAudio == url) {
                      // 是当前媒体：暂停/继续
                      if (audioPlayer.state == PlayerState.PAUSED) {
                        audioPlayer.resume().then((value) => print('语音.继续 结束'));
                      } else if (audioPlayer.state == PlayerState.PLAYING) {
                        audioPlayer.pause().then((value) => print('语音.暂停 结束'));
                      } else {
                        audioPlayer
                            .play(url)
                            .then((value) => print('语音.重新开始 结束'));
                      }
                    } else {
                      // 不是当前媒体，或没在播放：从头开始播放
                      audioPlayer.play(url).then((value) => print('语音.播放 结束'));
                      currentAudio = url;
                    }
                  },
                style: TextStyle(
                    fontSize: G.st.msgFontSize, color: G.st.msgLinkColor));
          } else {
            // 意外的语音格式
            span = new TextSpan(text: '[语音]');
          }
        } else if (cqCode == 'json') {
          // JSON卡片
          params = params
              .replaceAll("&#44;", ",")
              .replaceAll("&amp;", "&")
              .replaceAll("&#91;", "[")
              .replaceAll("&#93;", "]");

          // 获取简介
          String prompt = "";
          RegExp r = new RegExp(r'"prompt":\s*"(.+?)"');
          if ((mat = r.firstMatch(params)) != null) {
            prompt = mat[1];
          }

          // 获取网址参数
          String jumpUrl = "";
          String preview = "";
          re = RegExp(r'"(jumpUrl|qqdocurl|preview|icon)":\s*"(.+?)"');
          Iterable<RegExpMatch> mates = re.allMatches(params);
          for (int j = 0; j < mates.length; j++) {
            RegExpMatch match = mates.elementAt(j);
            String key = match.group(1);
            String val = match.group(2);
            if (key == 'jumpUrl') {
              jumpUrl = val;
            } else if (key == 'qqdocurl') {
              if (jumpUrl.isEmpty) {
                jumpUrl = val;
              }
            } else if (key == 'preview') {
              preview = val;
            } else if (key == "icon") {
              if (preview.isEmpty) {
                preview = val;
              }
            }
          }
          jumpUrl = jumpUrl.replaceAll("\\", "");
          preview = preview.replaceAll("\\", "");
          if (preview.isNotEmpty && !preview.contains('://'))
            preview = 'http://' + preview;

          TapGestureRecognizer tap;
          if (jumpUrl.isNotEmpty) {
            tap = TapGestureRecognizer()
              ..onTap = () {
                print('launch url: $jumpUrl');
                launch(jumpUrl);
              };
          }

          span = new TextSpan(
              text: prompt ?? "[json]",
              recognizer: tap,
              style: TextStyle(
                  fontSize: G.st.msgFontSize, color: G.st.msgLinkColor));

          spans.clear(); // 清空，JSON应该是不带有其他消息的
          if (preview.isNotEmpty) {
            spans.add(new WidgetSpan(
                child: _buildImageWidget(preview, onTap: () {
              print('launch url: $jumpUrl');
              launch(jumpUrl);
            }, recursion: recursion)));
            insertFirst = true;
          }
        } else {
          // 进行替换未处理的CQ码
          if (G.cs.CQCodeMap.containsKey(cqCode)) {
            cqCode = G.cs.CQCodeMap[cqCode];
          }
          span = new TextSpan(
              text: "[$cqCode]", style: TextStyle(fontSize: G.st.msgFontSize));
        }
      } else if ((RegExp(r"^https?://\S+$").firstMatch(matchedText)) != null) {
        // 网址
        span = TextSpan(
            text: matchedText,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                print('launch url: $matchedText');
                launch(matchedText);
              },
            style: TextStyle(
                fontSize: G.st.msgFontSize, color: G.st.msgLinkColor));
      } else if (false &&
          (RegExp(r"^\d{5,}$").firstMatch(matchedText)) != null) {
        // 号码
        span = TextSpan(
            text: matchedText,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                print('launch number: $matchedText');
                // TODO: 号码选项
              },
            style: TextStyle(
                fontSize: G.st.msgFontSize, color: G.st.msgLinkColor));
      } else if (false &&
          (RegExp(r"^\w+@[\w\.]+$").firstMatch(matchedText)) != null) {
        // 邮箱
        span = TextSpan(
            text: matchedText,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                print('launch email: $matchedText');
                // TODO: 邮箱选项
              },
            style: TextStyle(
                fontSize: G.st.msgFontSize, color: G.st.msgLinkColor));
      } else {
        // 未处理的格式
        span = new TextSpan(
            text: matchedText, style: TextStyle(fontSize: G.st.msgFontSize));
      }

      if (span != null) {
        if (insertFirst) {
          spans.insert(0, span);
        } else {
          spans.add(span);
        }
      }
      if (spanAfter != null) {
        spans.add(spanAfter);
      }
      pos = match.end;
    }

    // 剩下的普通文本
    if (pos < originText.length) {
      var span =
          _buildPureTextSpan(originText.substring(pos, originText.length));
      spans.add(span);
    }

    return Text.rich(TextSpan(children: spans),
        style: TextStyle(fontSize: G.st.msgFontSize));
  }

  /// 构建回复框控件
  /// 本质上还是调用富文本构建的方法
  /// 再设置底色用以区分
  Widget _buildReplyRichWidget(MsgBean msg, int messageId,
      {int recursion = 0}) {
    Widget replyWidget;
    MsgBean replyMsg;
    // 获取回复的框
    if (G.ac.allMessages.containsKey(msg.keyId())) {
      int index = G.ac.allMessages[msg.keyId()].lastIndexWhere((element) {
        return element.messageId == messageId;
      });
      if (index > -1) {
        // 找到对应的回复对象
        replyMsg = G.ac.allMessages[msg.keyId()].elementAt(index);
        String username =
            G.ac.getGroupMemberName(replyMsg.senderId, replyMsg.groupId);
        if (username == null || username.isEmpty) {
          username = replyMsg.senderId.toString();
          G.cs.refreshGroupMembers(replyMsg.groupId, userId: replyMsg.senderId);
        }
        if (G.st.showRecursionReply) {
          // 显示递归回复，即回复里面可以再显示回复的内容
          // 回复越深，颜色越深
          replyWidget = _buildRichContentWidget(replyMsg,
              useMessage: username + ': ' + replyMsg.message,
              recursion: recursion + 1);
        } else {
          // 只显示最近的回复，回复中的回复将以“[回复]@user”的形式显示
          String rs = replyMsg.message;
          rs = rs.replaceAll(
              RegExp(r"\[CQ:reply,.+?\]\s*(\[CQ:at,qq=\d+?\])?"), '[回复]');
          replyWidget = _buildRichTextSpans(replyMsg, username + ': ' + rs,
              recursion: recursion + 1);
        }
      }
    }
    if (replyWidget == null) {
      replyWidget = Text('[回复]');
    }

    // 设置外面的气泡颜色
    Color c = G.st.replyBubbleColor;
    if (G.st.enableColorfulReplyBubble &&
        replyMsg != null &&
        replyMsg.senderId != null &&
        !G.ac.gettingChatObjColor.contains(replyMsg.senderKeyId())) {
      if (G.ac.chatObjColor.containsKey(replyMsg.senderKeyId())) {
        c = ColorUtil.fixedLight(G.ac.chatObjColor[replyMsg.senderKeyId()],
            G.st.colorfulReplyBubbleBg);
      }
    }
    // 回复的气泡
    replyWidget = Container(
        child: replyWidget,
        padding: EdgeInsets.all(5.0),
        decoration: new BoxDecoration(
          color: c,
          borderRadius: BorderRadius.all(Radius.circular(G.st.msgBubbleRadius)),
        ));

    return replyWidget;
  }

  /// 单独构建一个JSON卡片控件
  Widget _buildJsonCardWidget(MsgBean msg) {
    return Container(
      child: Text('TODO'),
    );
  }

  /// 构建纯文本span
  /// 替换一些因为CQ码导致的内容
  /// 用来统一字体、颜色等
  InlineSpan _buildPureTextSpan(String text) {
    // 替换实体
    return TextSpan(
        text: replaceHtmlCode(text),
        style: TextStyle(fontSize: G.st.msgFontSize));
  }

  /// 构建一个最简单的纯文本消息框
  Widget _buildPureTextWidget(MsgBean msg, String text) {
    return new Text(
      replaceHtmlCode(text),
      style: TextStyle(color: Colors.black, fontSize: G.st.msgFontSize),
    );
  }

  String replaceHtmlCode(String text) {
    return text
        .replaceAll("&#44;", ",")
        .replaceAll("&amp;", "&")
        .replaceAll("&#91;", "[")
        .replaceAll("&#93;", "]");
  }

  /// 构建一个纯图片消息框
  Widget _buildImageWidget(String url, {var onTap, int recursion = 0}) {
    Widget image = ExtendedImage.network(
      url,
      fit: BoxFit.contain,
      cache: true,
      shape: BoxShape.rectangle,
      borderRadius: BorderRadius.all(Radius.circular(5.0)),
      scale: 2,
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
            return Image.asset(
              "assets/images/loading.gif",
              fit: BoxFit.fill,
              scale: 2,
            );

          ///if you don't want override completed widget
          ///please return null or state.completedWidget
          //return null;
          //return state.completedWidget;
          case LoadState.completed:
            if (!hasCompleted && widget.loadFinishedCallback != null) {
              hasCompleted = true;
              widget.loadFinishedCallback();
            }

            // 自适应缩放
            double scale = 4;
            var image = state.extendedImageInfo?.image;
            if (image != null) {
              int minHW = min(image.width, image.height);
              if (minHW < 64) {
                scale = 1;
              } else if (minHW < 128) {
                scale = 1.5;
              } else if (minHW < 256) {
                scale = 2;
              }

              // 回复中的图片更小一级
              if (minHW > 32 && recursion > 0) {
                scale *= 2;
              }
            }

            double maxHeight = MediaQuery.of(context).size.height / 3;
            if (recursion > 0) {
              maxHeight /= 2;
            }

            return Container(
              child: ExtendedRawImage(
                image: image,
                fit: BoxFit.contain,
                scale: scale,
              ),
              constraints: BoxConstraints(
                maxHeight: maxHeight,
              ),
            ); // 显示图片
          case LoadState.failed:
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
              onTap: onTap ??
                  () {
                    state.reLoadImage();
                  },
            );
            break;
        }
        return null;
      },
    );

    // 如果不是递归，则使用hero
    if (recursion == 0) {
      image = Hero(tag: url, child: image);
    }

    // 添加手势操作
    return GestureDetector(
      child: image,
      onTap: onTap ??
          () {
            if (widget.unfocusEditorCallback != null) {
              widget.unfocusEditorCallback();
            }
            // 查看图片
            /* Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return new SlidePage(url: url);
            })); */
            Navigator.of(context).push(PageRouteBuilder(
                opaque: false,
                pageBuilder: (_, __, ___) => new SlidePage(url: url)));
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: _buildMessageLine(),
    );
  }

  void _showMenu(BuildContext context, LongPressStartDetails detail) {
    // RenderBox renderBox = anchorKey.currentContext.findRenderObject();
    // var offset = renderBox.localToGlobal(Offset(0.0, renderBox.size.height));
    final RelativeRect position = RelativeRect.fromLTRB(
        detail.globalPosition.dx, // 取点击位置坐弹出x坐标
        detail.globalPosition.dy, // offset.dy取控件高度做弹出y坐标（这样弹出就不会遮挡文本）
        detail.globalPosition.dx,
        detail.globalPosition.dy);
    var pop = _buildPopupMenu();
    if (widget.unfocusEditorCallback != null) {
      widget.unfocusEditorCallback();
    }
    showMenu(
      context: context,
      items: pop.itemBuilder(context),
      position: position, //弹出框位置
    ).then((newValue) {
      if (!mounted) return null;
      if (newValue == null) {
        if (pop.onCanceled != null) pop.onCanceled();
        return null;
      }
      if (pop.onSelected != null) pop.onSelected(newValue);
    });
  }

  PopupMenuButton _buildPopupMenu() {
    return PopupMenuButton(
      itemBuilder: (context) => _buildMenuItems(context),
      onSelected: (value) {
        print('onSelected');
        _menuSelected(value);
      },
      onCanceled: () {
        print('menu.onCanceled');
        // bgColor = Colors.white;
        setState(() {});
      },
    );
  }

  _buildMenuItems(BuildContext context) {
    List<PopupMenuEntry> items = [
      PopupMenuItem(
        value: 'copy',
        child: Text('复制'),
      ),
      PopupMenuItem(
        value: 'reply',
        child: Text('回复'),
      ),
      PopupMenuItem(
        value: 'forward',
        child: Text('转发'),
      ),
      PopupMenuItem(
        value: 'repeat',
        child: Text('+1'),
      ),
      PopupMenuItem(
        value: 'cq',
        child: Text('CQ码'),
      ),
      PopupMenuItem(
        value: 'delete',
        child: Text('删除'),
      ),
    ];

    int insertPos = 2; // 自己的要插入的位置
    if (msg.recalled) {
      // 已经撤回，显示状态
      items.insert(insertPos++,
          PopupMenuItem(value: 'recall', child: Text('已撤回'), enabled: false));
    } else {
      if (msg.senderId == G.ac.myId) {
        // 自己的消息，可以撤回
        items.insert(
            insertPos++,
            PopupMenuItem(
              value: 'recall',
              child: Text('撤回'),
            ));
      }
    }

    if (RegExp(r'^\[CQ:image,[^\]]+\]$').hasMatch(msg.message) ||
        RegExp(r'^\[CQ:face,[^\]]+\]$').hasMatch(msg.message)) {
      items.insert(
          insertPos++, PopupMenuItem(value: 'addEmoji', child: Text('存表情')));
    }

    return items;
  }

  /// 选中项
  /// value 就是每个 item 的 value
  _menuSelected(String value) {
    print('message menu selected: $value');
    if (value == 'copy') {
      Clipboard.setData(ClipboardData(text: G.cs.getMessageDisplay(msg)));
    } else if (value == 'reply') {
      widget.addMessageCallback('[CQ:reply,id=${msg.messageId}] ');
    } else if (value == 'forward') {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Container(
                constraints: BoxConstraints(minWidth: 350, maxHeight: 500),
                child: SearchPage(
                  selectCallback: (m) {
                    G.cs.sendMsg(m, msg.message);
                  },
                ),
              ),
              contentPadding: EdgeInsets.all(5),
            );
          });
    } else if (value == 'repeat') {
      // widget.sendMessageCallback(msg.message);
      widget.addMessageCallback(msg.message);
    } else if (value == 'cq') {
      _showCopyTextDialog(
          'CQ码',
          'id: ' +
              msg.messageId.toString() +
              '\n--------------------\n' +
              msg.message);
    } else if (value == 'delete') {
      widget.deleteMessageCallback(msg);
    } else if (value == 'recall') {
      G.cs.send({
        'action': 'delete_msg',
        'params': {'message_id': msg.messageId},
        'echo': 'msg_recall_friend:${msg.friendId}_${msg.messageId}',
      });
    } else if (value == 'addEmoji') {
      G.st.emojiList.remove(msg.message); // 去掉重复的表情包
      G.st.emojiList.insert(0, msg.message); // 添加到开头
      G.st.setList('emoji/list', G.st.emojiList, split: ';');
      print('存表情：' + msg.message + ', 总数量：' + G.st.emojiList.length.toString());
    }
  }

  _showCopyTextDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: <Widget>[
            TextButton(
              child: Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('复制'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: msg.message));
                Navigator.of(context).pop();
              },
            ),
          ],
          elevation: 0,
          semanticLabel: '哈哈哈哈',
          // 设置成 圆角
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );
      },
    );
  }

  @override
  void deactivate() async {
    if (audioPlayer != null) {
      int result = await audioPlayer.release();
      if (result != 1) {
        print('release audio failed');
      }
    }
    super.deactivate();
  }
}
