class MsgBean {
  int senderId;
  String nickname;
  String message;
  int messageId;
  String subType;
  String remark; // 好友备注
  int targetId; // 准备发给谁，给对方还是给自己

  int groupId;
  String groupName;
  String groupCard; // 群昵称

  String fileId;
  String fileName;
  int fileSize;
  String fileUrl;

  String imageId; // 显示唯一图片（经常不一定有）

  String display; // 显示的纯文本
  int timestamp; // 毫秒级时间戳

  MsgBean(
      {this.senderId,
      this.nickname,
      this.message,
      this.messageId,
      this.subType,
      this.remark,
      this.targetId,
      this.groupId,
      this.groupName,
      this.groupCard,
      this.fileId,
      this.fileName,
      this.fileSize,
      this.fileUrl,
      this.timestamp});

  bool isPrivate() => groupId == 0;

  bool isGroup() => groupId != 0;
}
