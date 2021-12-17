import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/api.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';

class UserProfileWidget extends StatefulWidget {
  final userId;
  final nickname;

  const UserProfileWidget({Key key, this.userId, this.nickname})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _UserProfileWidgetState();
}

class _UserProfileWidgetState extends State<UserProfileWidget> {
  var eventBusFn;

  // 陌生人也会有的
  int userId;
  String nickname;
  String sex; // male/demale/unknow
  int age;
  String qid;
  int level;
  int loginDays;

  // 群成员信息
  String area; // 地区
  int joinTime;
  int lastSentTime;
  String role; // owner/admin/member
  bool unfriendly; // 是否不良记录成员
  String title; // 专属头衔
  bool cardChangeable; // 是否允许修改群名片
  int shutUpTimestamp; // 禁言到期时间

  @override
  void initState() {
    super.initState();

    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.userInfo) {
        if (mounted) {
          setState(() {
            _readJson(event.data);
          });
        }
      }
    });

    this.userId = widget.userId;
    this.nickname = widget.nickname;
    G.cs.send({
      'action': 'get_stranger_info',
      'params': {'user_id': widget.userId},
      'echo': 'get_user_info:${widget.userId}'
    });
  }

  void _readJson(data) {
    userId = data['user_id'];
    nickname = data['nickname'];
    sex = data['sex'];
    age = data['age'];
    qid = data['qid'];
    level = data['level'];
    loginDays = data['login_days'];
    area = data['area'];
    joinTime = data['join_time'];
    lastSentTime = data['last_sent_time'];
    role = data['role'];
    unfriendly = data['unfriendly'];
    title = data['title'];
    cardChangeable = data['card_changeable'];
    shutUpTimestamp = data['shut_up_timestamp'];
  }

  @override
  Widget build(BuildContext context) {
    // 头信息
    Widget headerView = Row(children: [
      Container(
          margin: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: new CircleAvatar(
            backgroundImage: NetworkImage(API.userHeader(userId)),
            radius: 32.0,
            backgroundColor: Colors.transparent,
          )),
      Column(children: [
        Text(nickname, style: TextStyle(fontSize: 25)),
        Text(userId.toString())
      ], crossAxisAlignment: CrossAxisAlignment.start)
    ]);

    // 列表
    List<Widget> columns = [headerView];
    return Container(
        child: Column(
          children: columns,
        ),
        margin: EdgeInsets.only(top: 16));
  }
}
