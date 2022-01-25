import 'package:date_format/date_format.dart';

enum MessageType {
  Message,
  Action,
  SystemLog,
}

class MsgBean {
  int senderId;
  String nickname; // 用户昵称
  String message; // 消息内容，或者显示格式
  String rawMessage;
  int messageId;
  String subType;
  String remark; // 好友备注
  int targetId; // 准备发给谁，给对方还是给自己
  MessageType action = MessageType.Message;

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
  int timestamp; // 毫秒级时间戳
  bool recalled = false; // 是否已撤回
  int operatorId; // 操作者ID

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
      this.timestamp = 0,
      this.operatorId,
      this.action = MessageType.Message});

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
          : nickname ?? "$senderId";

  String usernameSimplify() {
    String s = nickname;
    if (groupCard != null && groupCard.isNotEmpty) {
      s = groupCard;
    } else if (remark != null && remark.isNotEmpty) {
      s = remark;
    }
    if (s == null) {
      return "$senderId";
    }
    s = s.replaceAllMapped(RegExp(r'(.+)（.+?）$'), (match) => match[1]);
    s = s.replaceAllMapped(
        RegExp(r'^(?:id|Id|ID)[:：](.+)'), (match) => match[1]);
    return s ?? senderId;
  }

  int keyId() => groupId != null && groupId != 0 ? -groupId : friendId;

  int senderKeyId() => senderId;

  static int privateKeyId(int id) => id;

  static int groupKeyId(int id) => -id;

  String title() => isGroup() ? groupName : username();

  bool isPrivate() => groupId == null || groupId == 0;

  bool isGroup() => groupId != null && groupId != 0;

  bool isFile() => fileId != null && fileId.isNotEmpty;

  bool isMessage() => action == MessageType.Message;

  bool isPureMessage() => isMessage() && message != null;

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
    if (action == MessageType.SystemLog) {
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
