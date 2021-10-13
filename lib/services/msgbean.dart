class MsgBean {
  int senderId;
  String nickname;
  String message;
  String rawMessage;
  int messageId;
  String subType;
  String remark; // 好友备注
  int targetId; // 准备发给谁，给对方还是给自己

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
      this.timestamp});

  String username() => (groupCard != null && groupCard.isNotEmpty)
      ? groupCard
      : (remark != null && remark.isNotEmpty)
          ? remark
          : nickname;

  String title() => isGroup() ? groupName : username();

  bool isPrivate() => groupId == null || groupId == 0;

  bool isGroup() => groupId != null && groupId != 0;

  bool isFile() => fileId != null && fileId.isNotEmpty;

  bool isObj(MsgBean msg) {
    if (groupId != 0) {
      return this.groupId == msg.groupId;
    } else {
      return this.targetId == msg.targetId;
    }
  }

  String displayMessage() {
    String text = message;

    text = text.replaceAll(RegExp(r"\[CQ:face,id=(\d+)\]"), '[表情]');
    text = text.replaceAll(RegExp(r"\[CQ:image,type=flash,.+?\]"), '[闪照]');
    text = text.replaceAll(RegExp(r"\[CQ:image,.+?\]"), '[图片]');
    text = text.replaceAll(RegExp(r"\[CQ:reply,.+?\]"), '[回复]');
    text = text.replaceAll(RegExp(r"\[CQ:at,qq=all\]"), '@全体成员');
    text = text.replaceAllMapped(
        RegExp(r"\[CQ:at,qq=(\d+)\]"), (match) => '@${match[1]}');
    text = text.replaceAllMapped(
        RegExp(r'\[CQ:json,data=.+"prompt":"(.+?)".*\]'),
        (match) => '${match[1]}');
    text = text.replaceAll(RegExp(r"\[CQ:json,.+?\]"), '[JSON]');
    text = text.replaceAll(RegExp(r"\[CQ:video,.+?\]"), '[视频]');
    text = text.replaceAllMapped(
        RegExp(r"\[CQ:([^,]+),.+?\]"), (match) => '@${match[1]}');
    text = text.replaceAll('&#91;', '[').replaceAll('&#93;', ']');

    return text;
  }

  String simpleString() {
    String showed = message;
    //    showed = showed.replaceAll(RegExp(r"\[CQ:(\w+),.*\]"), '1');
    showed = showed.replaceAllMapped(
        RegExp(r"\[CQ:(\w+),.*\]"), (match) => "[${match[1]}]");
    if (isPrivate()) {
      return "$nickname: $showed";
    } else if (isGroup()) {
      return "[$groupName] $nickname: $showed";
    } else {
      return "unknow message";
    }
  }
}
