import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

class FriendListWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _FriendListWidgetState();
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
    Map<int, FriendInfo> friendList = G.ac.friendList;
    friendList.forEach((id, info) => {friends.add(info)});
    friends.sort(
        (FriendInfo a, FriendInfo b) => a.username().compareTo(b.username()));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return new Center(
        child: ListView.builder(
      shrinkWrap: true,
      itemCount: friends.length,
      itemBuilder: (context, index) {
        FriendInfo info = friends[index];
        return ListTile(
          title: Text('${info.username()}'),
          onTap: () {
            setState(() {
              G.rt.showChatPage(
                  MsgBean(targetId: info.userId, nickname: info.username()));
            });
          },
        );
      },
    ));
  }
}
