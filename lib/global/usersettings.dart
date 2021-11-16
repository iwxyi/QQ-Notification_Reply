import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/utils/mysettings.dart';

class UserSettings extends MySettings {
  static int Unimportant = -1; // ignore: non_constant_identifier_names
  static int NormalImportant = 0; // ignore: non_constant_identifier_names
  static int LittleImportant = 1; // ignore: non_constant_identifier_names
  static int VeryImportant = 2; // ignore: non_constant_identifier_names

  // 网络参数
  String host; // 主机地址
  String token; // 连接秘钥
  String server; // 后台服务地址

  // 消息选项
  List<int> enabledGroups = []; // 开启通知的群组
  List<int> importantGroups = []; // 设为重要的群组
  Map<int, int> friendImportance = {}; // 好友的重要性
  Map<int, int> groupImportance = {}; // 群组的重要性

  // 功能选项
  bool enableSelfChats = true; // 启用本身的聊天功能
  bool enableChatListHistories = true; // 聊天列表多条未读消息
  bool enableChatListReply = true; // 聊天列表点击未读按钮快速回复
  bool enableHeader = true; // 显示头像（稍微增加性能）
  int keepMsgHistoryCount = 100; // 保留多少消息记录
  int loadMsgHistoryCount = 20; // 默认加载多少条消息记录
  bool showRecursionReply = true; // 回复中允许再显示回复

  // 通知选项
  bool notificationLaunchQQ = false; // 点击通知是打开QQ还是程序本身
  bool notificationAtAll = false; // @全体成员 与 @自己 同一级
  bool groupSmartFocus = false; // 群消息智能聚焦

  // 界面显示
  double msgBubbleRadius = 5; // 气泡圆角
  double msgFontSize = 16; // 聊天界面字体大小
  Color msgLinkColor = Colors.blue; // 链接的颜色
  double replyFontSize = 14; // 回复字体的大小
  Color msgBubbleColor = Color(0xFFEEEEEE); // 消息气泡颜色
  Color msgBubbleColor2 = Color(0xFFE6E6FA); // 自己的消息气泡颜色
  Color replyBubbleColor = Color(0x10000000); // 回复气泡颜色
  Color replyFontColor = Color(0xFF222222); // 回复消息颜色

  UserSettings({@required String iniPath}) : super(iniPath: iniPath) {
    // readFromFile(); // super会调用，原来这是虚继承
  }

  /// 读取配置文件
  @override
  void readFromFile() {
    host = getStr('account/host', '');
    token = getStr('account/token', '');
    server = getStr('account/server', '');
    enableSelfChats = getBool('function/selfChats', true);
    enableChatListReply = getBool('function/chatListReply', true);
    notificationLaunchQQ = getBool('notification/launchQQ', false);
    groupSmartFocus = getBool('notification/groupSmartFocus', false);
    showRecursionReply = getBool('display/showRecursionReply', true);

    // 读取启用的群组数组
    String ens = getStr('notification/enabledGroups', '');
    if (ens.isNotEmpty) {
      List<String> sl = ens.split(';');
      sl.forEach((idString) {
        try {
          enabledGroups.add(int.parse(idString));
        } catch (e) {}
      });
    }

    // 读取重要的群组数组
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

  /// 点击开关后，切换群组状态
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

  /// 点击开关后，切换群组状态
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
}
