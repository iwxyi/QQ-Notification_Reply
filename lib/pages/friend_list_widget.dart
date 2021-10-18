import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

import 'chat_widget.dart';

class FriendListWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _FriendListWidgetState();
}

class FriendInfo {
  int id;
  String name;

  FriendInfo(this.id, this.name);
}

class _FriendListWidgetState extends State<FriendListWidget>
    with AutomaticKeepAliveClientMixin {
  List<FriendInfo> friends = [];
  String filterKey = '';
  List<FriendInfo> showItemList = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // 加载列表
    _loadFriendList();
    super.initState();
  }

  void _loadFriendList() {
    friends.clear();
    Map<int, String> friendNames = G.ac.friendNames;
    friendNames.forEach((id, name) => {friends.add(new FriendInfo(id, name))});
    friends.sort((FriendInfo a, FriendInfo b) => a.name.compareTo(b.name));
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
        child: ListView.builder(
      shrinkWrap: true,
      itemCount: friends.length,
      itemBuilder: (context, index) {
        FriendInfo info = friends[index];
        return ListTile(
          title: Text('${info.name}'),
          onTap: () {
            setState(() {
              G.rt.showChatPage(MsgBean(targetId: info.id, nickname: info.name));
            });
          },
        );
      },
    ));
  }
}
