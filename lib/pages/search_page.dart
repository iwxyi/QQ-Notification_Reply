import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class FGInfo {
  int keyId;
  int id;
  String name;
  int time;
  bool isGroup;

  FGInfo(this.keyId, this.id, this.name, this.time, this.isGroup);
}

class _SearchPageState extends State<SearchPage> {
  List<FGInfo> items = []; // 所有内容
  String filterKey = ''; // 过滤的关键字
  List<FGInfo> showItemList = []; // 显示的内容
  List<int> searchHistories = [];

  TextEditingController editingController = TextEditingController();

  @override
  void initState() {
    // 初始化好友内容
    Map<int, FriendInfo> friendList = G.ac.friendList;
    friendList.forEach((id, info) {
      int keyId = MsgBean.privateKeyId(id);
      int time =
          G.ac.messageTimes.containsKey(keyId) ? G.ac.messageTimes[keyId] : 0;
      items.add(new FGInfo(keyId, id, info.username(), time, false));
    });

    // 初始化群组内容
    Map<int, GroupInfo> groupList = G.ac.groupList;
    groupList.forEach((id, info) {
      int keyId = MsgBean.groupKeyId(id);
      int time =
          G.ac.messageTimes.containsKey(keyId) ? G.ac.messageTimes[keyId] : 0;
      items.add(new FGInfo(keyId, id, info.name, time, true));
    });
    items.sort((FGInfo a, FGInfo b) {
      return b.time.compareTo(a.time);
    });

    // 初始化搜索记录
    searchHistories = G.st.getIntList('recent/search');
    print(searchHistories);
    items.forEach((element) {
      if (searchHistories.contains(element.keyId)) {
        showItemList.add(element);
      }
    });

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
              // 搜索框
              autofocus: true,
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
              onSubmitted: (text) {
                if (showItemList.length > 0) {
                  openChat(showItemList.first);
                }
              },
            ),
            Expanded(
              child: ListView.builder(
                // 列表
                shrinkWrap: true,
                itemCount: showItemList.length,
                itemBuilder: (context, index) {
                  FGInfo info = showItemList[index];
                  return ListTile(
                      title: Text('${info.name} (${info.id})'),
                      onTap: () {
                        openChat(info);
                      },
                      onLongPress: () {
                        // 封装为对象
                        MsgBean msg;
                        if (info.isGroup) {
                          msg = MsgBean(groupId: info.id, groupName: info.name);
                        } else {
                          msg = MsgBean(
                              targetId: info.id,
                              friendId: info.id,
                              nickname: info.name);
                        }

                        // 取消搜索记录
                        setState(() {
                          searchHistories.remove(msg.keyId());
                          G.st.setList('recent/search', searchHistories);
                          showItemList.remove(info);
                        });
                      });
                },
              ),
            ),
          ],
        ));
  }

  void openChat(FGInfo info) {
    // 封装为对象
    MsgBean msg;
    if (info.isGroup) {
      msg = MsgBean(groupId: info.id, groupName: info.name);
    } else {
      msg = MsgBean(targetId: info.id, friendId: info.id, nickname: info.name);
    }

    // 保存搜索记录
    searchHistories.remove(msg.keyId());
    searchHistories.insert(0, msg.keyId());
    G.st.setList('recent/search', searchHistories);

    // 在聊天界面上显示
    msg.timestamp = DateTime.now().millisecondsSinceEpoch;
    G.ac.messageTimes[msg.keyId()] = msg.timestamp;
    G.ac.eventBus.fire(EventFn(Event.newChat, msg));

    // 打开聊天框
    Navigator.pop(context);
    G.rt.showChatPage(msg);
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
