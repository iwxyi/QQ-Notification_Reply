import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

class AllMessageListWidget extends StatefulWidget {
  @override
  _AllMessageListWidgetState createState() => _AllMessageListWidgetState();
}

class _AllMessageListWidgetState extends State<AllMessageListWidget> {
  List<String> initList = [];
  TextEditingController editingController = TextEditingController();
  var showItemList = List<String>();

  @override
  void initState() {
    G.ac.allLogs.reversed.forEach((element) {
      if (element.action == MessageType.SystemLog) {
        initList.add(element.simpleString());
      }
    });
    showItemList.addAll(initList);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('日志历史'),
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
              labelText: '过滤',
              hintText: '过滤',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ),
            onChanged: (value) {
              filterSearch(value);
            },
          ),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: showItemList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${showItemList[index]}'),
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  filterSearch(String query) {
    List<String> searchList = List<String>();
    searchList.addAll(initList);
    if (query.isNotEmpty) {
      List<String> resultListData = List<String>();
      searchList.forEach((item) {
        if (item.contains(query)) {
          resultListData.add(item);
        }
      });
      setState(() {
        showItemList.clear();
        showItemList.addAll(resultListData);
      });
      return;
    } else {
      setState(() {
        showItemList.clear();
        showItemList.addAll(initList);
      });
    }
  }
}
