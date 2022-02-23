import 'package:flutter/widgets.dart';
import 'package:qqnotificationreply/utils/file_util.dart';

class AppRuntime {
  String dataPath; // 应用数据目录（带斜杠）
  String cachePath; // 缓存路径
  String storagePath; // 外部存储目录（没用）

  var currentChatPage; // 当前聊天页面
  var showChatPage; // 显示当前聊天页面的函数
  var mainContext; // 当前上下文
  var chatObjList; // 所有会话列表
  var updateChatPageUnreadCount; // 刷新未读计数
  var showUserInfo;
  var showGroupInfo;
  var currentAudioFile; // 当前正在播放音频的file（默认为null）

  bool horizontal = false;
  double chatListFixedWidth = 400; // 横屏时左边聊天列表的固定宽度

  bool enableNotification = true;
  bool runOnForeground = true;
  bool thisDeviceSleep = false; // 非本设备聊天，不显示通知，直到重新打开
  bool thisDeviceSend = false; // 自己发送消息，表示是自己发的

  AppRuntime({@required this.dataPath, this.cachePath, this.storagePath}) {
    FileUtil.createDir(dataPath);
    FileUtil.createDir(cachePath);
    FileUtil.createDir(cachePath + 'user_header');
    FileUtil.createDir(cachePath + 'group_header');
  }

  String userHeader(int id) =>
      cachePath + "user_header/" + id.toString() + ".png";

  String groupHeader(int id) =>
      cachePath + "group_header/" + id.toString() + ".png";

  String cache(String path) => cachePath + path;
}
