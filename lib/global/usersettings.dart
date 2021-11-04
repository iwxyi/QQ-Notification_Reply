import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/utils/mysettings.dart';

class UserSettings extends MySettings {
  static int Unimportant = -1; // ignore: non_constant_identifier_names
  static int NormalImportant = 0; // ignore: non_constant_identifier_names
  static int LittleImportant = 1; // ignore: non_constant_identifier_names
  static int VeryImportant = 2; // ignore: non_constant_identifier_names

  String host; // 主机地址
  String token; // 连接秘钥
  bool enableSelfChats = true; // 启用本身的聊天功能
  bool notificationLaunchQQ = false; // 点击通知是打开QQ还是程序本身
  bool enableChatListHistories = true; // 聊天列表多条未读消息
  bool enableChatListReply = true; // 聊天列表点击未读按钮快速回复

  List<int> enabledGroups = []; // 开启通知的群组
  List<int> importantGroups = []; // 设为重要的群组
  Map<int, int> friendImportance = {}; // 好友的重要性
  Map<int, int> groupImportance = {}; // 群组的重要性

  bool enableHeader = true; // 显示头像（稍微增加性能）
  int keepMsgHistoryCount = 100; // 保留多少消息记录
  int loadMsgHistoryCount = 20; // 默认加载多少条消息记录
  double msgFontSize = 16; // 聊天界面字体大小
  Color msgLinkColor = Colors.blue; // 链接的颜色

  UserSettings({@required String iniPath}) : super(iniPath: iniPath) {
    // readFromFile(); // super会调用，原来这是虚继承
  }

  int getFriendImportance(int id) {
    if (friendImportance.containsKey(id)) {
      return friendImportance[id];
    }
    return LittleImportant;
  }

  void setFriendImportance(int id, int im) {
    friendImportance[id] = im;
  }

  int getGroupImportance(int id) {
    if (groupImportance.containsKey(id)) {
      return groupImportance[id];
    }
    return NormalImportant;
  }

  void setGroupImportance(int id, int im) {
    groupImportance[id] = im;
    print(groupImportance.toString());
  }

  void switchEnabledGroup(int id) {
    // 如果 id == 0，则只是单纯的保存全部
    if (id != 0) {
      if (!enabledGroups.contains(id)) {
        enabledGroups.add(id);
      } else {
        enabledGroups.remove(id);
      }
    }

    // 保存
    String text = enabledGroups.join(';');
    setConfig('notification/enabledGroups', text);
  }

  void switchImportantGroup(int id) {
    // 如果 id == 0，则只是单纯的保存全部
    if (id != 0) {
      if (!importantGroups.contains(id)) {
        importantGroups.add(id);
      } else {
        importantGroups.remove(id);
      }
    }

    // 保存
    String text = importantGroups.join(';');
    setConfig('notification/importantGroups', text);
  }

  /// 读取配置文件
  @override
  void readFromFile() {
    host = getStr('account/host', '');
    token = getStr('account/token', '');
    enableSelfChats = getBool('function/selfChats', true);
    notificationLaunchQQ = getBool('notification/launchQQ', false);

    // 读取启用的数组
    String ens = getStr('notification/enabledGroups', '');
    if (ens.isNotEmpty) {
      List<String> sl = ens.split(';');
      sl.forEach((idString) {
        try {
          enabledGroups.add(int.parse(idString));
        } catch (e) {}
      });
    }

    // 读取重要的数组
    ens = getStr('notification/importantGroups', '');
    if (ens.isNotEmpty) {
      List<String> sl = ens.split(';');
      sl.forEach((idString) {
        try {
          importantGroups.add(int.parse(idString));
        } catch (e) {}
      });
    }
  }
}
