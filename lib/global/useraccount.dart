import 'package:event_bus/event_bus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  GroupInfo(this.groupId, this.name) {
    this.members = {};
  }
}

class UserAccount {
  // 账号信息
  String nickname = ''; // QQ昵称
  int qqId = 0; // QQ ID

  // 账号数据
  Map<int, FriendInfo> friendList = {}; // 好友列表
  Map<int, GroupInfo> groupList = {}; // 群组列表

  // 消息记录
  List<MsgBean> allLogs = []; // 所有消息记录
  Map<int, List<MsgBean>> allMessages = {}; // 所有消息记录
  Map<int, int> messageTimes = {}; // 消息事件
  Map<int, List<Message>> unreadMessages = {}; // 未读消息（通知）
  Map<int, int> unreadMessageCount = {}; // 未读消息数量
  Map<int, bool> chatListShowReply = {}; // 聊天记录显示回复框

  // 账号事件
  EventBus eventBus = new EventBus(); // 事件总线

  // 通知ID hash
  // 消息通知
  static var flutterLocalNotificationsPlugin;
  static Map<int, int> notificationIdMap = {};

  // 多线程Flag
  Map<int, bool> gettingGroupMembers = {};

  // QQ号增加至11位，与QQ群分开
  static int getNotificationId(MsgBean msg) {
    int id = msg.keyId();
    if (!notificationIdMap.containsKey(id)) {
      notificationIdMap[id] = notificationIdMap.length + 1;
    }
    return notificationIdMap[id];
  }

  String selfInfo() => nickname + ' (' + qqId.toString() + ')';

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
    if (unreadMessages.containsKey(msg.keyId())) {
      unreadMessages.remove(msg.keyId());
    }
  }

  String getGroupMemberName(int userId, int groupId) {
    if (groupId != null && groupId != 0) {
      // 艾特群成员
      if (groupList.containsKey(groupId)) {
        if (groupList[groupId].members.containsKey(userId)) {
          return groupList[groupId].members[userId].username();
        }
      }
    } else {
      // 艾特私聊
      if (friendList.containsKey(userId)) {
        return friendList[userId].username();
      }
    }
    return null;
  }
}
