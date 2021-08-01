import 'package:event_bus/event_bus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qqnotificationreply/services/msgbean.dart';

class UserAccount {
  // 账号信息
  String nickname = ''; // QQ昵称
  int qqId = 0; // QQ ID
  int connectState = 0; // 连接状态：0未连接，1已连接，-1已断开

  // 账号数据
  Map<int, String> friendNames = {};
  Map<int, String> groupNames = {};
  Map<int, Map<int, String>> groupMemberNames = {};

  // 消息记录
  List<MsgBean> allMessages = [];
  Map<int, int> privateMessageTimes = {};
  Map<int, int> groupMessageTimes = {};

  // 账号事件
  EventBus eventBus = new EventBus(); // 事件总线

  // 通知ID hash
  // 消息通知
  static var flutterLocalNotificationsPlugin;
  static Map<int, int> notificationIdMap = {};

  Map<int, List<Message>> unreadPrivateMessages = {};
  Map<int, List<Message>> unreadGroupMessages = {};

  // QQ号增加只12位，与QQ群分开
  static int getNotificationId(MsgBean msg) {
    int id = msg.isGroup()
        ? msg.groupId
        : msg.isPrivate()
            ? msg.friendId + 1e2
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
