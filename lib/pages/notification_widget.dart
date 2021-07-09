import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '群组',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Card(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: Colors.red,
                  ),
                  title: Text('开启通知的群组'),
                  trailing: Icon(Icons.arrow_right),
                  onTap: selectEnabledGroup,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '通知',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Card(
            color: Colors.white,
            elevation: 4.0,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(
                    Icons.phone,
                    color: Colors.blue,
                  ),
                  title: Text('还没想好……'),
                  trailing: Icon(Icons.arrow_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 选择开启通知的群组
  void selectEnabledGroup() {
    // TODO: 多选对话框
  }
}
