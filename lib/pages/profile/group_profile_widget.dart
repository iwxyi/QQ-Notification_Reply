import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qqnotificationreply/global/api.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

enum GroupMenuItems { ImportantGroup, LocalNickname, GroupMembers }

class GroupProfileWidget extends StatefulWidget {
  final MsgBean chatObj;
  final showGroupMembers;

  const GroupProfileWidget({Key key, this.chatObj, this.showGroupMembers})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupProfileWidgetState();
}

class _GroupProfileWidgetState extends State<GroupProfileWidget> {
  var eventBusFn;

  int groupId;
  String groupName;
  String groupMemo; // 群备注
  int groupCreateTime;
  int groupLevel; // 群等级
  int memberCount; // 群员数量
  int maxMemberCount; // 最大成员数

  @override
  void initState() {
    super.initState();

    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.groupInfo) {
        if (mounted) {
          setState(() {
            _readJson(event.data);
          });
        }
      }
    });

    this.groupId = widget.chatObj.groupId;
    this.groupName = widget.chatObj.groupName;

    G.cs.send({
      'action': 'get_group_info',
      'params': {'group_id': groupId},
      'echo': 'get_group_info:$groupId'
    });
  }

  void _readJson(data) {
    groupName = data['group_name'];
    groupMemo = data['group_memo'];
    groupCreateTime = data['group_create_time'];
    groupLevel = data['group_level'];
    memberCount = data['member_count'];
    maxMemberCount = data['max_member_count'];
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> headerWidgets = [
      Text(
        groupName,
        style: TextStyle(fontSize: 20),
        overflow: TextOverflow.ellipsis,
      ),
      GestureDetector(
          child: Text(groupId.toString()),
          onTap: () {
            Clipboard.setData(ClipboardData(text: groupId.toString()));
            Fluttertoast.showToast(
                msg: "已复制群号：$groupId",
                gravity: ToastGravity.CENTER,
                textColor: Colors.grey);
          }),
    ];

    // 头像昵称等基础信息
    Widget headerView = Row(children: [
      new CircleAvatar(
        backgroundImage: NetworkImage(API.groupHeader(groupId)),
        radius: 32.0,
        backgroundColor: Colors.transparent,
      ),
      SizedBox(
        width: 16,
      ),
      Expanded(
          child: Column(
              children: headerWidgets,
              crossAxisAlignment: CrossAxisAlignment.start)),
      _buildMenu(context)
    ]);

    // 列表
    List<Widget> columns = [headerView];

    if (groupMemo != null && groupMemo.isNotEmpty) {
      columns.add(Text(groupMemo));
    }

    columns.add(Text('成员数：$memberCount / $maxMemberCount'));

    if (groupCreateTime != null && groupCreateTime > 0) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(groupCreateTime * 1000);
      String s =
          formatDate(dt, ['yyyy', '-', 'mm', '-', 'dd', ' ', 'HH', ':', 'nn']);
      columns.add(Text('创建时间：' + s));
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
          String name = groupName;
          if (G.ac.groupList.containsKey(groupId)) {
            name = G.ac.groupList[groupId].name;
          }
          name = G.st.getLocalNickname(MsgBean(groupId: groupId).keyId(), name);
          G.rt.showChatPage(MsgBean(groupId: groupId, nickname: name));
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
    List<PopupMenuEntry<GroupMenuItems>> menus = [
      PopupMenuItem<GroupMenuItems>(
        value: GroupMenuItems.ImportantGroup,
        child:
            Text(G.st.importantGroups.contains(groupId) ? '取消重要群组' : '设为重要群组'),
      ),
      PopupMenuItem<GroupMenuItems>(
        value: GroupMenuItems.GroupMembers,
        child: Text('查看群成员'),
      ),
      PopupMenuItem<GroupMenuItems>(
        value: GroupMenuItems.LocalNickname,
        child: Text('本地昵称'),
      ),
    ];

    return PopupMenuButton<GroupMenuItems>(
      icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
      tooltip: '菜单',
      itemBuilder: (BuildContext context) => menus,
      onSelected: (GroupMenuItems result) {
        switch (result) {
          case GroupMenuItems.ImportantGroup:
            setState(() {
              if (G.st.importantGroups.contains(groupId)) {
                G.st.importantGroups.remove(groupId);
              } else {
                G.st.importantGroups.add(groupId);
              }
              G.st.setList(
                  'notification/importantGroups', G.st.importantGroups);
              print('重要群组数量：${G.st.importantGroups.length}');
            });
            break;
          case GroupMenuItems.LocalNickname:
            editCustomName();
            break;
          case GroupMenuItems.GroupMembers:
            if (widget.showGroupMembers != null) {
              widget.showGroupMembers();
            }
            break;
        }
      },
    );
  }

  void editCustomName() {
    int keyId = MsgBean.groupKeyId(widget.chatObj.groupId);
    String curName = G.st.getLocalNickname(keyId, widget.chatObj.groupName);
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
            title: Text('请输入本地群名'),
            content: TextField(
              decoration: InputDecoration(
                hintText: '不影响真实群名',
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
