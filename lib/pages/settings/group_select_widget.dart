import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/global/useraccount.dart';

class GroupSelectWidget extends StatefulWidget {
  @override
  _GroupSelectWidgetState createState() => _GroupSelectWidgetState();
}

class IGroupInfo {
  int id;
  String name;
  int importance; // -1不重要，0默认，1普通通知，2重点通知
  int time;

  IGroupInfo(this.id, this.name, this.importance, this.time);
}

class _GroupSelectWidgetState extends State<GroupSelectWidget> {
  TextEditingController editingController = TextEditingController();
  List<IGroupInfo> groups = [];
  String filterKey = '';
  List<IGroupInfo> showItemList = [];

  @override
  void initState() {
    // 初始化群组内容
    Map<int, GroupInfo> groupList = G.ac.groupList;
    groupList.forEach((id, info) {
      int time = G.ac.groupMessageTimes.containsKey(id)
          ? G.ac.groupMessageTimes[id]
          : 0;
      groups.add(new IGroupInfo(id, info.name, 0, time));
    });
    groups.sort((IGroupInfo a, IGroupInfo b) {
      return b.time.compareTo(a.time);
    });

    // 初始化显示
    for (int i = 0; i < groups.length; i++) {
      showItemList.add(groups[i]);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('选择群组'),
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
                  IGroupInfo info = showItemList[index];
                  return ListTile(
                      title: Row(children: [
                        Text('${info.name}'),
                        Icon(G.st.importantGroups.contains(info.id)
                            ? Icons.star
                            : null)
                      ]),
                      onTap: () {
                        setState(() {
                          G.st.switchEnabledGroup(info.id);
                        });
                      },
                      trailing: Checkbox(
                        onChanged: (bool val) {
                          setState(() {
                            G.st.switchEnabledGroup(info.id);
                          });
                        },
                        value: G.st.enabledGroups.contains(info.id),
                      ),
                      onLongPress: () {
                        setState(() {
                          G.st.switchImportantGroup(info.id);
                        });
                      });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RaisedButton(
                  onPressed: () {
                    G.st.enabledGroups = G.ac.groupList.keys.toList();
                    G.st.switchEnabledGroup(0);
                    setState(() {});
                  },
                  child: new Text('全选'),
                  onLongPress: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('显示所有群组通知')));
                  },
                ),
                RaisedButton(
                  onPressed: () {
                    G.ac.groupList.forEach((id, info) {
                      if (G.st.enabledGroups.contains(id)) {
                        G.st.enabledGroups.remove(id);
                      } else {
                        G.st.enabledGroups.add(id);
                      }
                    });
                    G.st.switchEnabledGroup(0);
                    setState(() {});
                  },
                  child: new Text('反选'),
                  onLongPress: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('反选所有群组通知')));
                  },
                )
              ],
            )
          ],
        ));
  }

  filterSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        showItemList.clear();
        for (int i = 0; i < groups.length; i++) {
          if (groups[i].name.contains(query)) {
            showItemList.add(groups[i]);
          }
        }
      });
      return;
    } else {
      setState(() {
        showItemList.clear();
        for (int i = 0; i < groups.length; i++) {
          showItemList.add(groups[i]);
        }
      });
    }
  }
}
