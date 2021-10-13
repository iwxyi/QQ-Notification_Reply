import 'package:event_bus/event_bus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

class UserAccount {
  // 账号信息
  String nickname = ''; // QQ昵称
  int qqId = 0; // QQ ID
  int connectState = 0; // 连接状态：0未连接，1已连接，-1已断开

  // 账号数据
  Map<int, String> friendNames = {}; // 好友昵称（优先备注）
  Map<int, String> groupNames = {}; // 群组名称
  Map<int, Map<int, String>> groupMemberNames = {};

  // 消息记录
  List<MsgBean> allMessages = [];
  Map<int, List<MsgBean>> allPrivateMessages = {};
  Map<int, List<MsgBean>> allGroupMessages = {};

  Map<int, int> privateMessageTimes = {}; // 私聊消息时间
  Map<int, int> groupMessageTimes = {}; // 群聊消息时间

  Map<int, List<Message>> unreadPrivateMessages = {}; // 未读私聊消息
  Map<int, List<Message>> unreadGroupMessages = {}; // 未读群聊消息

  // 账号事件
  EventBus eventBus = new EventBus(); // 事件总线

  // 通知ID hash
  // 消息通知
  static var flutterLocalNotificationsPlugin;
  static Map<int, int> notificationIdMap = {};


  // QQ号增加只12位，与QQ群分开
  static int getNotificationId(MsgBean msg) {
    int id = msg.isGroup()
        ? msg.groupId
        : msg.isPrivate()
            ? msg.friendId + 1e12
            : 0;
    if (!notificationIdMap.containsKey(id)) {
      notificationIdMap[id] = notificationIdMap.length + 1;
    }
    id = notificationIdMap[id];
    return id;
  }

  String selfInfo() => nickname + ' (' + qqId.toString() + ')';

  MsgBean getMsgById(int msgId) {
    int index = allMessages.indexWhere((element) => element.messageId == msgId);
    if (index == -1) {
      print('未找到的MessageId: ' + msgId.toString());
      return null;
    }
    return allMessages[index];
  }
}
