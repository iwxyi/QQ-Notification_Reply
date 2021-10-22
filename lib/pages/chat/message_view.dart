import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

import '../../widgets/slide_images_page.dart';

/// 构造发送的信息
/// 每一条消息显示的复杂对象
class MessageView extends StatefulWidget {
  final MsgBean msg;
  final bool isNext;
  final loadFinishedCallback;

  MessageView(this.msg, this.isNext, this.loadFinishedCallback);

  @override
  _MessageViewState createState() => _MessageViewState(msg, isNext);
}

class _MessageViewState extends State<MessageView> {
  final bool isNext;
  final MsgBean msg;

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
    vWidgets.add(_buildMessageTypeView());

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
  Widget _buildMessageTypeView() {
    String text = msg.message;
    Match match;
    RegExp imageRE = RegExp(r'^\[CQ:image,file=.+?,url=(.+?)(,.+?)?\]$');
    if ((match = imageRE.firstMatch(text)) != null) {
      // 如果是图片
      String url = match.group(1);
      return _buildImageWidget(url);
    } else {
      // 未知，当做纯文本了
      return new Card(
        child: new Container(
            margin: const EdgeInsets.all(8.0), child: _buildTextWidget(msg)),
        color: Color(0xFFEEEEEE),
        elevation: 0.0,
      );
    }
  }

  /// 构建富文本消息框
  Widget _buildTextWidget(MsgBean msg) {
    List<Widget> spans = [];
    // 先解析文本
    return _buildSimpleTextWidget(msg);
  }

  /// 构建一个最简单的纯文本消息框
  Widget _buildSimpleTextWidget(MsgBean msg) {
    return new Text(
      G.cs.getMessageDisplay(msg),
      style: TextStyle(color: Colors.black, fontSize: 16),
    );
  }

  /// 构建一个纯图片消息框
  Widget _buildImageWidget(String url) {
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
                    shape: BoxShape.rectangle,
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
                          return Image.asset(
                            "assets/images/loading.gif",
                            fit: BoxFit.fill,
                          );

                        ///if you don't want override completed widget
                        ///please return null or state.completedWidget
                        //return null;
                        //return state.completedWidget;
                        case LoadState.completed:
                          if (widget.loadFinishedCallback != null) {
                            widget.loadFinishedCallback();
                          }
                          return ExtendedRawImage(
                            image: state.extendedImageInfo?.image,
                            fit: BoxFit.contain,
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
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: _buildMessageLine(),
    );
  }
}
