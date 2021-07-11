import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';

class GroupListWidget extends StatefulWidget {
  @override
  _GroupListWidgetState createState() => _GroupListWidgetState();
}

class GroupInfo {
  int id;
  String name;
  int importance; // -1不重要，0默认，1普通通知，2重点通知

  GroupInfo(this.id, this.name, this.importance);
}

class _GroupListWidgetState extends State<GroupListWidget> {
  TextEditingController editingController = TextEditingController();
  List<GroupInfo> groups = [];
  String filterKey = '';
  List<GroupInfo> showItemList = [];

  @override
  void initState() {
    // 初始化群组内容
    Map<int, String> groupNames = G.ac.groupNames;
    groupNames.forEach((key, value) {
      groups.add(new GroupInfo(key, value, 0));
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
              keyboardType: TextInputType.number,
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
                  GroupInfo info = showItemList[index];
                  return ListTile(
                    title: Text('${info.name}'),
                    onTap: () {
                      setState(() {
                        G.st.switchEnabledGroup(info.id);
                      });
                    },
                    trailing: Checkbox(
                      onChanged: (bool val) {
                        G.st.switchEnabledGroup(info.id);
                      },
                      value: G.st.enabledGroups.contains(info.id),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RaisedButton(
                  onPressed: () {
                    G.st.enabledGroups = G.ac.groupNames.keys.toList();
                    setState(() {});
                  },
                  child: new Text('全选'),
                ),
                RaisedButton(
                  onPressed: () {
                    G.ac.groupNames.forEach((id, name) {
                      if (G.st.enabledGroups.contains(id)) {
                        G.st.enabledGroups.remove(id);
                      } else {
                        G.st.enabledGroups.add(id);
                      }
                    });
                    setState(() {});
                  },
                  child: new Text('反选'),
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
