import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qqnotificationreply/global/appruntime.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/global/usersettings.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:web_socket_channel/io.dart';

/// WebSocket使用说明：https://zhuanlan.zhihu.com/p/133849780
class CqhttpService {
  AppRuntime rt;
  UserSettings st;
  UserAccount ac;

  IOWebSocketChannel channel;

  CqhttpService({this.rt, this.st, this.ac});

  Future<bool> connect(String host, String token) async {
    print('ws连接: ' + host + ' ' + token);
    Map<String, dynamic> headers = new Map();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer ' + token;
    }
    channel = IOWebSocketChannel.connect(host, headers: headers);

    // 监听消息
    channel.stream.listen((message) {
      // print('ws收到消息:' + message.toString());
      processReceivedData(json.decode(message.toString()));
      ac.eventBus.fire(EventFn(Event.loginSuccess, {}));
    });

    st.setConfig('account/host', host);
    st.setConfig('account/token', token);

    return true;
  }

  void send(Map<String, dynamic> obj) {
    String text = json.encode(obj);
    print('发送数据：' + text);
    channel.sink.add(text);
  }

  void processReceivedData(Map<String, dynamic> obj) {
    // 先判断是不是自己主动获取消息的echo
    if (obj.containsKey('echo')) {
      // 解析返回的数据
      parseEchoMessage(obj);
      return;
    }

    String postType = obj['post_type'];
    if (postType == 'meta_event') {
      // 心跳，忽略
      String subType = obj['sub_type'];
      if (subType == 'connect') {
        // 第一次连接上
        parseLifecycle(obj);
      }
    } else if (postType == 'message') {
      String messageType = obj['message_type'];
      if (messageType == 'private') {
        // 私聊消息
        parsePrivateMessage(obj);
      } else if (messageType == 'group') {
        // 群聊消息
        parseGroupMessage(obj);
      } else {
        print('未处理的消息：' + obj.toString());
      }
    } else if (postType == 'notice') {
      String noticeType = obj['notice_type'];
      if (noticeType == 'group_upload') {
        // 群文件上传
        parseGroupUpload(obj);
      } else if (noticeType == 'offline_file') {
        // 私聊文件上传
        parseOfflineFile(obj);
      } else {
        print('未处理类型的通知：' + obj.toString());
      }
    } else if (postType == 'message_sent') {
      // 自己发的消息
      parseMessageSent(obj);
    } else {
      print('未处理类型的数据：' + obj.toString());
    }
  }

  /// 连接上，必定会触发这个
  void parseLifecycle(final obj) {
    int userId = obj['self_id']; // 自己的QQ号
    ac.qqId = userId;
    ac.connectState = 1;

    // 发送获取登录号信息
    send({'action': 'get_login_info', 'echo': 'get_login_info'});
    getFriendList();
    getGroupList();
  }

  void parseEchoMessage(final obj) {
    String echo = obj['echo'];
    if (echo == 'get_login_info') {
      var data = obj['data'];
      ac.qqId = data['user_id'];
      ac.nickname = data['nickname'];
      print('登录账号：' + ac.nickname + "  " + ac.qqId.toString());
      ac.eventBus.fire(
          EventFn(Event.loginInfo, {'qqId': ac.qqId, 'nickname': ac.nickname}));
    } else if (echo == 'get_friend_list') {
      ac.friendNames.clear();
      List data = obj['data']; // 好友数组
      print('好友数量: ' + data.length.toString());
      data.forEach((friend) {
        int userId = friend['user_id'];
        String nickname = friend['nickname'];
        if (friend.containsKey('remark')) nickname = friend['remark'];
        ac.friendNames[userId] = nickname;
      });
      ac.eventBus.fire(EventFn(Event.friendList, {}));
    } else if (echo == 'get_group_list') {
      ac.groupNames.clear();
      List data = obj['data']; // 好友数组
      print('群组数量: ' + data.length.toString());
      data.forEach((friend) {
        int groupId = friend['group_id'];
        String groupName = friend['group_name'];
        ac.groupNames[groupId] = groupName;
      });
      ac.eventBus.fire(EventFn(Event.groupList, {}));
    } else if (echo == 'send_private_msg' || echo == 'send_group_msg') {
      // 发送消息的回复，不做处理
    } else if (echo.startsWith('get_group_member_list')) {
      // TODO: 获取群组，echo字段格式为：get_group_member_list:123456
    } else {
      print('未处理类型的echo: ' + echo);
    }
  }

  void parsePrivateMessage(final obj) {}

  void parseGroupMessage(final obj) {
    String subType = obj['sub_type'];
    String message = obj['message'];
    String rawMessage = obj['raw_message'];
    int groupId = obj['group_id'];
    int messageId = obj['message_id'];

    var sender = obj['sender'];
    int userId = sender['user_id']; // 发送者QQ，大概率是别人，也可能是自己
    String nickname = sender['nickname'];
    String card = sender['card']; // 群名片，可能为空
    String role = sender['role']; // 角色：owner/admin/member

    if (subType == 'anonymous') {
      // 匿名消息，不作处理
    }

    String groupName =
        ac.groupNames.containsKey(groupId) ? ac.groupNames[groupId] : '';
    if (ac.friendNames.containsKey(userId)) nickname = ac.friendNames[userId];

    print(
        '收到群消息：' + ac.groupNames[groupId] + " - " + nickname + " : " + message);

    MsgBean msg = MsgBean(
        subType: subType,
        groupId: groupId,
        groupName: groupName,
        senderId: userId,
        nickname: nickname,
        groupCard: card,
        messageId: messageId,
        message: message,
        role: role);
    showNotification(msg);
  }

  void parseGroupUpload(final obj) {}

  void parseOfflineFile(final obj) {}

  void parseMessageSent(final obj) {}

  void refreshFriend() {}

  void refreshGroups() {}

  void refreshGroupMembers(int groupId) {}

  void getFriendList() {
    send({'action': 'get_friend_list', 'echo': 'get_friend_list'});
  }

  void getGroupList() {
    send({'action': 'get_group_list', 'echo': 'get_group_list'});
  }

  void sendUserMessage(int userId, String message) {}

  void sendGroupMessage(int groupId, String message) {}

  void showNotification(MsgBean msg) {
    ac.eventBus.fire(EventFn(Event.message, msg));
  }
}
