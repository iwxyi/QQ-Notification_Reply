import 'dart:ui';

import 'package:event_bus/event_bus.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

class FriendInfo {
  int userId;
  String nickname;
  String remark;

  FriendInfo(this.userId, this.nickname, this.remark);

  String username() {
    return remark != null && remark != "" ? remark : nickname;
  }
}

class GroupInfo {
  int groupId;
  String name;
  Map<int, FriendInfo> members;

  Set<int> ignoredMembers; // 需要这些群成员时不进行刷新
  bool focusAsk = false; // 提问聚焦
  Set<int> focusAt; // 艾特聚焦

  GroupInfo(this.groupId, this.name) {
    this.members = {};
  }
}

class UserAccount {
  // 账号信息
  String myNickname = ''; // QQ昵称
  int myId = 0; // QQ ID

  // 账号数据
  Map<int, FriendInfo> friendList = {}; // 好友列表
  Map<int, GroupInfo> groupList = {}; // 群组列表

  // 消息记录
  List<MsgBean> allLogs = []; // 所有日志记录
  Map<int, List<MsgBean>> allMessages = {}; // 所有消息记录
  Map<int, int> messageTimes = {}; // 消息时间（毫秒）
  Map<int, int> messageMyTimes = {}; // 自己在本设备发送的消息时间（毫秒），用来提升动态重要性
  Map<int, int> unreadMessageCount = {}; // 未读消息数量（仅显示需要通知的）
  Map<int, int> receivedCountAfterMySent = {}; // 自自己发送消息后收到了多少未读通知，用来提升动态重要性

  // 聊天对象的变量
  Map<int, bool> chatListShowReply = {}; // 聊天记录显示回复框
  Map<int, Color> chatObjColor = {};

  // 账号事件
  EventBus eventBus = new EventBus(); // 事件总线

  // 通知ID hash
  // 消息通知
  static var flutterLocalNotificationsPlugin;
  static Map<int, int> notificationIdMap = {};

  // 多线程Flag
  Set<int> gettingGroupMembers = {};
  Set<int> gettingChatObjColor = {};

  // QQ号增加至11位，与QQ群分开
  static int getNotificationId(MsgBean msg) {
    int id = msg.keyId();
    if (!notificationIdMap.containsKey(id)) {
      notificationIdMap[id] = notificationIdMap.length + 1;
    }
    return notificationIdMap[id];
  }

  bool isLogin() => myId != null && myId != 0;

  String selfInfo() => myNickname + ' (' + myId.toString() + ')';

  MsgBean getMsgById(int msgId) {
    int index = allLogs.indexWhere((element) => element.messageId == msgId);
    if (index == -1) {
      print('未找到的MessageId: ' + msgId.toString());
      return null;
    }
    return allLogs[index];
  }

  void clearUnread(MsgBean msg) {
    if (unreadMessageCount.containsKey(msg.keyId())) {
      unreadMessageCount.remove(msg.keyId());
    }
//    if (unreadMessages.containsKey(msg.keyId())) {
//      unreadMessages.remove(msg.keyId());
//    }
  }

  String getGroupMemberName(int userId, int groupId) {
    if (groupId != null && groupId != 0) {
      // 艾特群成员
      if (groupList.containsKey(groupId)) {
        if (groupList[groupId].members.containsKey(userId)) {
          return groupList[groupId].members[userId].username();
        }
      }
    }
    // 艾特私聊或者群成员没有
    if (friendList.containsKey(userId)) {
      return friendList[userId].username();
    }
    return null;
  }
}
