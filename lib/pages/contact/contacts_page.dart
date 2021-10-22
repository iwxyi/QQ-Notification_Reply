import 'package:flutter/material.dart';

import '../contact/friend_list_widget.dart';
import '../contact/group_list_widget.dart';

class ContactsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  TabController _tabController;
  var eventBusFn;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 注册监听器，订阅 eventBus
    /* eventBusFn = G.ac.eventBus.on<EventFn>().listen((event) {
      if (event.event == Event.friendList || event.event == Event.groupList) {
        setState(() {});
      }
    }); */
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Color iconColor = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        tabs: <Widget>[
          Tab(
            icon: Icon(Icons.contacts, color: iconColor),
          ),
          Tab(
            icon: Icon(Icons.groups, color: iconColor),
          ),
          Tab(
            icon: Icon(Icons.info, color: iconColor),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          Center(
            child: new FriendListWidget(),
          ),
          Center(
            child: new GroupListWidget(),
          ),
          Center(
            child: Text("待开发"),
          ),
        ],
      ),
    );
  }
}
