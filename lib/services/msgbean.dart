import 'package:date_format/date_format.dart';

enum ActionType {
  Message,
  JoinAction,
  ExitAction,
  SystemLog,
}

class MsgBean {
  int senderId;
  String nickname;
  String message;
  String rawMessage;
  int messageId;
  String subType;
  String remark; // 好友备注
  int targetId; // 准备发给谁，给对方还是给自己
  ActionType action = ActionType.Message;

  int friendId;
  int groupId;
  String groupName;
  String groupCard; // 群昵称

  String fileId;
  String fileName;
  int fileSize;
  String fileUrl;

  String role; // 角色：owner/admin/member
  String imageId; // 显示唯一图片（经常不一定有）
  String display; // 显示的纯文本
  int timestamp = 0; // 毫秒级时间戳
  bool recalled = false; // 是否已撤回

  MsgBean(
      {this.senderId,
      this.nickname,
      this.message,
      this.messageId,
      this.rawMessage,
      this.subType,
      this.remark,
      this.targetId,
      this.friendId,
      this.groupId,
      this.groupName,
      this.groupCard,
      this.fileId,
      this.fileName,
      this.fileSize,
      this.fileUrl,
      this.role,
      this.timestamp,
      this.action});

  MsgBean deepCopy() {
    return new MsgBean(
        senderId: this.senderId,
        nickname: this.nickname,
        message: this.message,
        messageId: this.messageId,
        rawMessage: this.rawMessage,
        subType: this.subType,
        remark: this.remark,
        targetId: this.targetId,
        friendId: this.friendId,
        groupId: this.groupId,
        groupName: this.groupName,
        groupCard: this.groupCard,
        fileId: this.fileId,
        fileName: this.fileName,
        fileSize: this.fileSize,
        fileUrl: this.fileUrl,
        role: this.role,
        timestamp: this.timestamp,
        action: this.action);
  }

  String username() => (groupCard != null && groupCard.isNotEmpty)
      ? groupCard
      : (remark != null && remark.isNotEmpty)
          ? remark
          : nickname;

  int keyId() => groupId != null && groupId != 0 ? -groupId : friendId;

  static int privateKeyId(int id) => id;

  static int groupKeyId(int id) => -id;

  String title() => isGroup() ? groupName : username();

  bool isPrivate() => groupId == null || groupId == 0;

  bool isGroup() => groupId != null && groupId != 0;

  bool isFile() => fileId != null && fileId.isNotEmpty;

  bool isObj(MsgBean msg) {
    if (groupId != null && groupId != 0) {
      return this.groupId == msg.groupId;
    } else {
      return this.friendId == msg.friendId;
    }
  }

  String simpleString() {
    String showed = message;
    showed = showed.replaceAllMapped(
        RegExp(r"\[CQ:(\w+),.*\]"), (match) => "[${match[1]}]");
    String ts = formatDate(DateTime.fromMillisecondsSinceEpoch(timestamp),
        ['HH', ':', 'nn', ':', 'ss']);
    if (action == ActionType.SystemLog) {
      return "$ts $showed";
    } else {
      if (isPrivate()) {
        return "$ts $nickname: $showed";
      } else if (isGroup()) {
        return "$ts [$groupName] $nickname: $showed";
      } else {
        return "$ts unknow message";
      }
    }
  }
}
