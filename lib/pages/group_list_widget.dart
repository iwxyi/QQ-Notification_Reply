import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

import 'chat_widget.dart';

class GroupListWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _GroupListWidgetState();
}

class GroupInfo {
  int id;
  String name;

  GroupInfo(this.id, this.name);
}

class _GroupListWidgetState extends State<GroupListWidget>
    with AutomaticKeepAliveClientMixin {
  List<GroupInfo> groups = [];
  String filterKey = '';
  List<GroupInfo> showItemList = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // 加载列表
    _loadGroupList();
    super.initState();
  }

  void _loadGroupList() {
    groups.clear();
    Map<int, String> groupNames = G.ac.groupNames;
    groupNames.forEach((id, name) => {groups.add(new GroupInfo(id, name))});
    groups.sort((GroupInfo a, GroupInfo b) => a.name.compareTo(b.name));
  }

  @override
  // ignore: must_call_super
  Widget build(BuildContext context) {
    return new Center(
        child: ListView.builder(
      shrinkWrap: true,
      itemCount: groups.length,
      itemBuilder: (context, index) {
        GroupInfo info = groups[index];
        return ListTile(
          title: Text('${info.name}'),
          onTap: () {
            setState(() {
              G.rt.showChatPage(
                  MsgBean(groupId: info.id, groupName: info.name));
            });
          },
        );
      },
    ));
  }
}
