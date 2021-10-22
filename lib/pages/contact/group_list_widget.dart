import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

class GroupListWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _GroupListWidgetState();
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
    Map<int, GroupInfo> groupList = G.ac.groupList;
    groupList.forEach((id, info) => {groups.add(info)});
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
                  MsgBean(groupId: info.groupId, groupName: info.name));
            });
          },
        );
      },
    ));
  }
}
