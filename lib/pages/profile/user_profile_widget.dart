import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qqnotificationreply/global/api.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

enum UserMenuItems { SpecialAttention, LocalNickname, MessageHistory }

class UserProfileWidget extends StatefulWidget {
  final MsgBean chatObj;

  const UserProfileWidget({Key key, this.chatObj}) : super(key: key);

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
  var level; // 因为我也不确定是string还是int
  int loginDays;

  // 群成员信息
  String card;
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

    this.userId = widget.chatObj.friendId ??
        widget.chatObj.senderId ??
        widget.chatObj.targetId;
    this.nickname = widget.chatObj.nickname;
    if (widget.chatObj.groupId != null && widget.chatObj.groupId != 0) {
      G.cs.send({
        'action': 'get_group_member_info',
        'params': {'user_id': userId, 'group_id': widget.chatObj.groupId},
        'echo': 'get_user_info:$userId'
      });
    } else {
      G.cs.send({
        'action': 'get_stranger_info',
        'params': {'user_id': userId},
        'echo': 'get_user_info:$userId'
      });
    }
  }

  void _readJson(data) {
    userId = data['user_id'];
    nickname = data['nickname'];
    sex = data['sex'];
    age = data['age'];
    qid = data['qid'];
    level = data['level'];
    loginDays = data['login_days'];

    card = data['card'];
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
    List<Widget> headerWidgets = [
      Text(nickname, style: TextStyle(fontSize: 25)),
      GestureDetector(
          child: Text(userId.toString()),
          onTap: () {
            Clipboard.setData(ClipboardData(text: userId.toString()));
            Fluttertoast.showToast(
                msg: "已复制QQ号：$userId",
                gravity: ToastGravity.CENTER,
                textColor: Colors.grey);
          }),
    ];

    if (title != null && title != "") {
      headerWidgets.insert(1, Text("【$title】"));
    }

    // 头像昵称等基础信息
    Widget headerView = Row(children: [
      new CircleAvatar(
        backgroundImage: NetworkImage(API.userHeader(userId)),
        radius: 32.0,
        backgroundColor: Colors.transparent,
      ),
      SizedBox(
        width: 16,
      ),
      Column(
          children: headerWidgets,
          crossAxisAlignment: CrossAxisAlignment.start),
      Expanded(child: SizedBox(width: 16)),
      _buildMenu(context)
    ]);

    // 列表
    List<Widget> columns = [headerView];
    // 基本信息
    {
      List<String> infos = [];

      // 群身份
      if (role == 'owner') {
        infos.add('【群主】');
      } else if (role == 'admin') {
        infos.add('【管理员】');
      }

      // 性别
      if (sex != null) {
        if (sex == 'male') {
          infos.add('男');
        } else if (sex == 'female') {
          infos.add('女');
        }
      }
      // 年龄
      if (age != null && age > 0) {
        infos.add('$age岁');
      }
      // 地区
      if (area != null && area != "") {
        infos.add(area);
      }

      if (infos.length > 0) {
        columns.add(Text(infos.join('  ')));
      }
    }

    if (card != null) {
      columns.add(Text('群昵称：' + card));
    }

    if (joinTime != null && joinTime > 0) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(joinTime * 1000);
      String s =
          formatDate(dt, ['yyyy', '-', 'mm', '-', 'dd', ' ', 'HH', ':', 'nn']);
      columns.add(Text(s + ' 加入本群'));
    }

    /* if (lastSentTime != null && lastSentTime > 0) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(lastSentTime * 1000);
      String s =
          formatDate(dt, ['yyyy', '-', 'mm', '-', 'dd', ' ', 'HH', ':', 'nn']);
      columns.add(Text('最后发言：' + s));
    } */

    if (shutUpTimestamp != null &&
        shutUpTimestamp > DateTime.now().millisecondsSinceEpoch) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(lastSentTime * 1000);
      String s =
          formatDate(dt, ['yyyy', '-', 'mm', '-', 'dd', ' ', 'HH', ':', 'nn']);
      columns.add(Text('禁言至：' + s));
    }

    // 动作
    columns.add(SizedBox(height: 16));
    // columns.add(Expanded(child: SizedBox(height: 16)));
    columns.add(Row(children: [
      MaterialButton(
        child: Text(
          '发消息',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        onPressed: () {
          Navigator.of(context).pop();
          G.rt.showChatPage(
              MsgBean(friendId: userId, targetId: userId, nickname: nickname));
        },
        color: Theme.of(context).primaryColor,
      )
    ], mainAxisAlignment: MainAxisAlignment.center));

    return Container(
      margin:
          const EdgeInsets.only(left: 16.0, right: 16.0, top: 16, bottom: 16),
      child: Column(
        children: columns,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    List<PopupMenuEntry<UserMenuItems>> menus = [
      PopupMenuItem<UserMenuItems>(
        value: UserMenuItems.SpecialAttention,
        child: Text(
            G.st.specialGroupMember.contains(userId) ? '取消群内特别关注' : '设为群内特别关注'),
        enabled: widget.chatObj.isGroup(),
      ),
      PopupMenuItem<UserMenuItems>(
        value: UserMenuItems.LocalNickname,
        child: Text('本地昵称'),
      ),
      PopupMenuItem<UserMenuItems>(
        value: UserMenuItems.MessageHistory,
        child: Text('消息历史'),
        enabled: false,
      )
    ];

    return PopupMenuButton<UserMenuItems>(
      icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
      tooltip: '菜单',
      itemBuilder: (BuildContext context) => menus,
      onSelected: (UserMenuItems result) {
        switch (result) {
          case UserMenuItems.SpecialAttention:
            setState(() {
              if (G.st.specialGroupMember.contains(userId)) {
                G.st.specialGroupMember.remove(userId);
              } else {
                G.st.specialGroupMember.add(userId);
              }
              G.st.setList(
                  'notification/specialGroupMember', G.st.specialGroupMember);
              print('群内特别关注人数：${G.st.specialGroupMember.length}');
            });
            break;
          case UserMenuItems.LocalNickname:
            editCustomName();
            break;
          case UserMenuItems.MessageHistory:
            // TODO:用户消息历史
            break;
        }
      },
    );
  }

  void editCustomName() {
    int keyId = widget.chatObj.senderKeyId();
    String curName = G.st.getLocalNickname(keyId, widget.chatObj.username());

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
}
