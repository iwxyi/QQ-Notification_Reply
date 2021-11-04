import 'dart:math';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/slide_images_page.dart';

/// 构造发送的信息
/// 每一条消息显示的复杂对象
class MessageView extends StatefulWidget {
  final MsgBean msg;
  final bool isNext;
  final loadFinishedCallback;

  MessageView(this.msg, this.isNext, this.loadFinishedCallback, Key key)
      : super(key: key);

  @override
  _MessageViewState createState() => _MessageViewState(msg, isNext);
}

class _MessageViewState extends State<MessageView> {
  final bool isNext;
  final MsgBean msg;
  bool hasCompleted = false;

  _MessageViewState(this.msg, this.isNext);

  /// 一整行
  Widget _buildMessageLine() {
    // 判断左右
    bool isSelf = msg.senderId == G.ac.qqId;

    // 消息列的上下控件，是否显示昵称
    List<Widget> vWidgets = [];
    if (!isSelf && !isNext) {
      vWidgets.add(_buildNicknameView());
    }
    vWidgets.add(_buildMessageBubble());

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

    return new Container(
      child: new Row(
          mainAxisAlignment:
              isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: hWidgets),
      padding: EdgeInsets.only(top: isNext ? 0 : 8),
    );
  }

  /// 构建头像控件
  Widget _buildHeaderView() {
    if (isNext) {
      // 24*2 + 12 + 12 = 72
      return SizedBox(width: 72, height: 48);
    }
    String headerUrl = "http://q1.qlogo.cn/g?b=qq&nk=${msg.senderId}&s=100&t=";
    return new Container(
        margin: const EdgeInsets.only(left: 12.0, right: 12.0),
        child: new CircleAvatar(
          backgroundImage: NetworkImage(headerUrl),
          radius: 24.0,
          backgroundColor: Colors.transparent,
        ));
  }

  /// 构建昵称控件
  /// 自己发的没有昵称
  Widget _buildNicknameView() {
    return new Container(
      margin: const EdgeInsets.only(top: 5.0),
      child: new Text(
        msg.username(), // 用户昵称
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  /// 构建消息控件
  Widget _buildMessageBubble() {
    EdgeInsets bubblePadding = EdgeInsets.all(8.0); // 消息内部间距
    EdgeInsets bubbleMargin = EdgeInsets.only(top: 3.0, bottom: 3.0);
    Color bubbleColor = Color(0xFFEEEEEE);
    Widget bubbleContent;

    String text = msg.message;
    Match match;
    RegExp imageRE = RegExp(r'^\[CQ:image,file=.+?,url=(.+?)(,.+?)?\]$');
    if ((match = imageRE.firstMatch(text)) != null) {
      // 如果是图片
      String url = match.group(1);
      bubbleContent = _buildImageWidget(url);
      bubblePadding = EdgeInsets.only();
    } else {
      // 纯文本或者富文本
      bubbleContent = _buildRichWidget(msg);
    }

    return new Container(
      child: bubbleContent,
      padding: bubblePadding,
      margin: bubbleMargin, // 上限间距
      decoration: new BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
      ),
    );
  }

  /// 构建富文本消息框
  Widget _buildRichWidget(MsgBean msg) {
    List<InlineSpan> spans = [];
    RegExp re =
        new RegExp(r"\[CQ:(\w+),?([^\]]*)\]|https?://\S+|\d{5,}|\w+@[\w\.]+");
    var originText = msg.message;
    Iterable<RegExpMatch> matches = re.allMatches(originText);
    if (matches.length == 0) {
      // 纯文本
      return _buildSimpleTextWidget(msg);
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
      bool insertFirst = false; // 一些图片是否插入到前面

      if (match.group(0).startsWith("[CQ:")) {
        // 是CQ码，挨个判断匹配到的内容
        String cqCode = match.group(1); // CQ码
        String params = match.group(2); // 参数字符串

        // 判断CQ码
        Match mat;
        if (cqCode == 'face') {
          // 替换成表情
          RegExp re = RegExp(r'^id=(\d+)$');
          if ((mat = re.firstMatch(params)) != null) {
            String id = mat[1];
            span = new WidgetSpan(
                child: Image.asset("assets/qq_face/$id.gif",
                    scale: 2, height: 28));
          }
        } else if (cqCode == 'image') {
          // 替换成图片
          RegExp imageRE = RegExp(r'^file=.+?,url=([^,]+)$');
          if ((mat = imageRE.firstMatch(params)) != null) {
            String url = mat[1];
            span = new WidgetSpan(child: _buildImageWidget(url));
          }
        } else if (cqCode == 'reply') {
          span = new TextSpan(
              text: "[回复]",
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  print('TODO: 回复');
                },
              style: TextStyle(fontSize: G.st.msgFontSize));
          replyEndPos = match.end; // 用来取消后面的at
        } else if (cqCode == 'bag') {
          span = new WidgetSpan(child: Image.asset("assets/icons/redbag.png"));
        } else if (cqCode == 'at') {
          RegExp re = RegExp(r'^qq=(\w+)$');
          if ((mat = re.firstMatch(params)) != null) {
            String id = mat[1];
            if (id == 'all') {
              // @全体成员
              span = new TextSpan(
                  text: "@全体成员",
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      print('TODO: @全体成员');
                    },
                  style: TextStyle(fontSize: G.st.msgFontSize));
            } else if (match.start != replyEndPos) {
              // @qq，已经判断了不是reply自带的at
              String username =
                  G.ac.getGroupMemberName(int.parse(id), msg.groupId);
              if (username == null) {
                username = id;
                if (msg.isGroup()) {
                  G.cs.refreshGroupMembers(msg.groupId);
                }
              }
              span = new TextSpan(
                  text: "@$username",
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      print('TODO: @$username');
                    },
                  style: TextStyle(fontSize: G.st.msgFontSize));
            }
          }
        } else if (cqCode == 'json') {
          // JSON卡片
          params = params
              .replaceAll("&#44;", ",")
              .replaceAll("&amp;", ";")
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
          re = RegExp(r'"(jumpUrl|qqdocurl|preview)":\s*"(.+?)"');
          Iterable<RegExpMatch> mates = re.allMatches(params);
          print(mates);
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

          TapGestureRecognizer tap;
          if (jumpUrl.isNotEmpty) {
            tap = TapGestureRecognizer()
              ..onTap = () {
                print('launch url: $jumpUrl');
                launch(jumpUrl);
              };
          }

          if (preview.isNotEmpty) {
            span = new WidgetSpan(
                child: _buildImageWidget(preview, onTap: () {
              print('launch url: $jumpUrl');
              launch(jumpUrl);
            }));
            insertFirst = true;
          }

          spans.clear(); // 清空，JSON应该是不带有其他消息的
          spans.add(new TextSpan(
              text: prompt ?? "[json]",
              recognizer: tap,
              style: TextStyle(
                  fontSize: G.st.msgFontSize, color: G.st.msgLinkColor)));
        } else {
          // 未处理的格式
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
                print('launch url: $matchedText');
                // TODO
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
                // TODO
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

  InlineSpan _buildPureTextSpan(String text) {
    // 替换实体
    text = text
        .replaceAll("&#44;", ",")
        .replaceAll("&amp;", ";")
        .replaceAll("&#91;", "[")
        .replaceAll("&#93;", "]");
    return TextSpan(text: text, style: TextStyle(fontSize: G.st.msgFontSize));
  }

  /// 构建一个最简单的纯文本消息框
  Widget _buildSimpleTextWidget(MsgBean msg) {
    return new Text(
      G.cs.getMessageDisplay(msg),
      style: TextStyle(color: Colors.black, fontSize: G.st.msgFontSize),
    );
  }

  /// 构建一个纯图片消息框
  Widget _buildImageWidget(String url, {var onTap}) {
    return GestureDetector(
      child: Hero(
          tag: url,
          child: ExtendedImage.network(
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
                  }

                  return Container(
                    child: ExtendedRawImage(
                      image: image,
                      fit: BoxFit.contain,
                      scale: scale,
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height / 2,
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
          )),
      onTap: onTap ??
          () {
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
}
