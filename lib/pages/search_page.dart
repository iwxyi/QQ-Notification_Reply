import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class FGInfo {
  int id;
  String name;
  int time;
  bool isGroup;

  FGInfo(this.id, this.name, this.time, this.isGroup);
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController editingController = TextEditingController();
  List<FGInfo> items = [];
  String filterKey = '';
  List<FGInfo> showItemList = [];

  @override
  void initState() {
    // 初始化好友内容
    Map<int, FriendInfo> friendList = G.ac.friendList;
    friendList.forEach((id, info) {
      id = MsgBean.privateKeyId(id);
      int time = G.ac.messageTimes.containsKey(id) ? G.ac.messageTimes[id] : 0;
      items.add(new FGInfo(id, info.username(), time, false));
    });

    // 初始化群组内容
    Map<int, GroupInfo> groupList = G.ac.groupList;
    groupList.forEach((id, info) {
      id = MsgBean.groupKeyId(id);
      int time = G.ac.messageTimes.containsKey(id) ? G.ac.messageTimes[id] : 0;
      items.add(new FGInfo(id, info.name, time, true));
    });
    items.sort((FGInfo a, FGInfo b) {
      return b.time.compareTo(a.time);
    });

    // 初始化显示
    for (int i = 0; i < items.length; i++) {
      if (items[i].time > 0) {
        showItemList.add(items[i]);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('搜索'),
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Text(
                '',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            TextField(
              controller: editingController,
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
              ),
              onChanged: (value) {
                filterKey = value;
                filterSearch(filterKey);
              },
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: showItemList.length,
                itemBuilder: (context, index) {
                  FGInfo info = showItemList[index];
                  return ListTile(
                    title: Text('${info.name} (${info.id})'),
                    onTap: () {
                      Navigator.pop(context);
                      MsgBean msg;
                      if (info.isGroup) {
                        msg = MsgBean(groupId: info.id, groupName: info.name);
                      } else {
                        msg = MsgBean(
                            targetId: info.id,
                            friendId: info.id,
                            nickname: info.name);
                      }
                      G.rt.showChatPage(msg);
                    },
                  );
                },
              ),
            ),
          ],
        ));
  }

  filterSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        showItemList.clear();
        for (int i = 0; i < items.length; i++) {
          if (items[i].name.contains(query)) {
            showItemList.add(items[i]);
          }
        }
      });
      return;
    } else {
      setState(() {
        showItemList.clear();
        for (int i = 0; i < items.length; i++) {
          showItemList.add(items[i]);
        }
      });
    }
  }
}
