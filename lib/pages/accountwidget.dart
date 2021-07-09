import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/pages/loginwidget.dart';

class AccountWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AccountWidgetState();
}

class _AccountWidgetState extends State<AccountWidget> {
  var eventBusFn;

  @override
  void initState() {
    super.initState();

    // 注册监听器，订阅 eventBus
    eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.loginInfo) {
        print('event.data:' + event.data.toString());
        setState(() {});
      }
      // print(event.obj);
    });
  }

  @override
  void dispose() {
    super.dispose();
    //取消订阅
    eventBusFn.cancel();
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
              '登录',
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
                  title: Text(G.ac.connectState > 0 ? G.ac.selfInfo() : '点击登录'),
                  trailing: Icon(Icons.arrow_right),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (context) {
                      return LoginWidget();
                    })).then((value) {
                      // 可能登录了，刷新一下界面
                      setState(() {});
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '列表',
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
                  title: Text('好友数量：' + G.ac.friendNames.length.toString()),
                  trailing: Icon(Icons.arrow_right),
                ),
                ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: Colors.blue,
                  ),
                  title: Text('群组数量：' + G.ac.groupNames.length.toString()),
                  trailing: Icon(Icons.arrow_right),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
