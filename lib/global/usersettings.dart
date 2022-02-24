import 'package:flutter/material.dart';
import 'package:qqnotificationreply/utils/mysettings.dart';

class UserSettings extends MySettings {
  static int Unimportant = -1; // ignore: non_constant_identifier_names
  static int NormalImportant = 0; // ignore: non_constant_identifier_names
  static int LittleImportant = 1; // ignore: non_constant_identifier_names
  static int VeryImportant = 2; // ignore: non_constant_identifier_names
  static String strSplit = "-_-_-_-";

  // 网络参数
  String host; // 主机地址
  String token; // 连接秘钥
  String server; // 后台服务地址

  // 消息选项
  Map<int, String> localNickname = {}; // 本地昵称
  List<int> enabledGroups = []; // 开启通知的群组
  List<int> importantGroups = []; // 设为重要的群组
  Map<int, int> friendImportance = {}; // 好友的重要性
  Map<int, int> groupImportance = {}; // 群组的重要性
  List<int> specialUsers = []; // 群内特别关注（全部群）
  List<int> blockedUsers = []; // 屏蔽的成员

  // 功能选项
  bool enableSelfChats = true; // 启用本身的聊天功能
  bool enableChatListHistories = true; // 会话列表多条未读消息
  int chatListHistoriesCount = 3; // 显示多少未读消息
  bool enableChatListReply = false; // 会话列表点击未读按钮快速回复
  bool chatListReplySendHide = true; // 快速回复后自动隐藏
  bool enableHeader = true; // 显示头像（稍微消耗性能）
  int keepMsgHistoryCount = 100; // 保留多少消息记录
  int loadMsgHistoryCount = 20; // 默认加载多少条消息记录
  bool showRecursionReply = true; // 回复中允许再显示回复
  bool enableQuickSwitcher = false; // 页面底部显示聊天对象快速切换
  bool enableNonsenseMode = false; // 启用胡说八道模式
  bool debugMode = false; // 调试模式
  bool enableEmojiToImage = false; // 群消息表情包转网络图片格式
  bool disableDangerousAction = false; // 禁止有风险的操作，避免账号被冻结
  bool enableHorizontalSwitch = false; // 左右滑动切换消息
  bool enableNotificationSleep = true; // 启用暂停通知功能

  // 通知选项
  bool notificationLaunchQQ = false; // 点击通知是打开QQ还是程序本身
  bool groupSmartFocus = false; // 群消息智能聚焦
  bool notificationAtAll = false; // @全体成员 与 @自己 同一级
  bool groupDynamicImportance = false; // 群消息动态重要性
  int chatTopMsgDisplayMSecond = 5000; // 聊天界面顶部消息显示

  // 界面显示
  bool inputEnterSend = false;
  double msgBubbleRadius = 5; // 气泡圆角
  double msgFontSize = 16; // 聊天界面字体大小
  Color msgLinkColor = Colors.blue; // 链接的颜色
  double replyFontSize = 14; // 回复字体的大小
  double cardRadiusS = 5;
  double cardRadiusM = 10;
  double cardRadiusL = 15;
  Color msgNicknameColor = Colors.grey; // 昵称颜色
  Color msgBubbleColor = Color(0xFFEEEEEE); // 消息气泡颜色
  Color msgBubbleColor2 = Color(0xFFE6E6FA); // 自己的消息气泡颜色
  Color replyBubbleColor = Color(0x10000000); // 回复气泡颜色
  Color replyFontColor = Color(0xFF222222); // 回复消息颜色
  bool enableColorfulChatList = false; // 会话列表使用头像颜色作为背景
  double colorfulChatListBg = 0.93;
  double colorfulChatListSelecting = 0.5;
  bool enableColorfulChatName = false; // 使用彩色昵称
  double colorfulChatNameFont = 0.5;
  bool enableColorfulChatBubble = false; // 使用彩色气泡
  double colorfulChatBubbleBg = 0.94;
  bool enableColorfulReplyBubble = false; // 使用彩色回复
  double colorfulReplyBubbleBg = 0.9;
  bool enableColorfulBackground = false; // 使用彩色窗口背景
  double colorfulBackgroundBg = 0.05;
  bool enableChatListRoundedRect = true; // 会话列表使用圆角矩形
  bool enableChatListLoose = true; // 会话列表更加宽松（一般和上面一起用）
  bool enableChatWidgetRoundedRect = false; // 聊天界面使用大圆角矩形
  bool enableChatBubbleLoose = false; // 气泡之间的距离更加宽松
  bool enableMessagePreviewSingleLine = false; // 预览的消息单行显示（会话列表、跳转）

  // 表情包
  List<String> emojiList = []; // 表情包的CQ码（理论上可以是任意消息），但只显示face或image

  UserSettings({@required String iniPath}) : super(iniPath: iniPath) {
    // readFromFile(); // super会调用，原来这是虚继承
  }

  /// 读取配置文件
  @override
  void readFromFile() {
    host = getStr('account/host', '');
    token = getStr('account/token', '');
    server = getStr('account/server', '');

    // 功能
    enableSelfChats = getBool('function/selfChats', enableSelfChats);
    enableChatListHistories =
        getBool('function/chatListHistories', enableChatListHistories);
    enableChatListReply =
        getBool('function/chatListReply', enableChatListReply);
    enableSelfChats = getBool('function/selfChats', enableSelfChats);
    chatListReplySendHide =
        getBool('function/chatListReplySendHide', chatListReplySendHide);
    notificationLaunchQQ =
        getBool('notification/launchQQ', notificationLaunchQQ);
    groupSmartFocus = getBool('notification/groupSmartFocus', groupSmartFocus);
    groupDynamicImportance =
        getBool('notification/groupDynamicImportance', groupDynamicImportance);
    notificationAtAll = getBool('notification/atAll', notificationAtAll);
    showRecursionReply =
        getBool('display/showRecursionReply', showRecursionReply);
    inputEnterSend = getBool('display/inputEnterSend', inputEnterSend);
    enableQuickSwitcher =
        getBool('function/enableQuickSwitcher', enableQuickSwitcher);
    enableNonsenseMode =
        getBool('function/enableNonsenseMode', enableNonsenseMode);
    debugMode = getBool('function/enableDebugMode', debugMode);
    enableEmojiToImage =
        getBool('function/enableEmojiToImage', enableEmojiToImage);
    disableDangerousAction =
        getBool('function/disableDangerousAction', disableDangerousAction);
    enableHorizontalSwitch =
        getBool('function/enableHorizontalSwitch', enableHorizontalSwitch);

    // 显示
    enableColorfulChatList =
        getBool('display/enableColorfulChatList', enableColorfulChatList);
    enableColorfulChatName =
        getBool('display/enableColorfulChatName', enableColorfulChatName);
    enableColorfulChatBubble =
        getBool('display/enableColorfulChatBubble', enableColorfulChatBubble);
    enableColorfulReplyBubble =
        getBool('display/enableColorfulReplyBubble', enableColorfulReplyBubble);
    enableColorfulBackground =
        getBool('display/enableColorfulBackground', enableColorfulBackground);
    enableNotificationSleep =
        getBool('display/enableNotificationSleep', enableNotificationSleep);
    enableChatListRoundedRect =
        getBool('display/enableChatListRoundedRect', enableChatListRoundedRect);
    enableChatListLoose =
        getBool('display/enableChatListLoose', enableChatListLoose);
    enableChatBubbleLoose =
        getBool('display/enableChatBubbleLoose', enableChatBubbleLoose);
    enableMessagePreviewSingleLine = getBool(
        'display/enableMessagePreviewSingleLine',
        enableMessagePreviewSingleLine);

    // 读取启用的群组数组
    enabledGroups = getIntList('notification/enabledGroups');
    // 读取重要的群组数组
    importantGroups = getIntList('notification/importantGroups');
    // 读取群内特别关注
    specialUsers = getIntList('notification/specialUsers');

    // 读取本地名字
    List<String> sl = getStringList('display/localNickname', strSplit);
    sl.forEach((idNameString) {
      Match match;
      if (idNameString.isEmpty ||
          (match = RegExp(r'^(-?\d+):(.+)$').firstMatch(idNameString)) ==
              null) {
        print('无法识别的本地昵称表达式：' + idNameString);
        return;
      }

      int id = int.parse(match[1]);
      String name = match[2];
      localNickname[id] = name;
    });

    // 读取屏蔽的用户
    blockedUsers = getIntList('notification/blockedUsers');

    // 读取表情包
    emojiList = getStringList('emoji/list', ';');
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

  void setLocalNickname(int id, String name) {
    if (name.trim().isEmpty) {
      localNickname.remove(id);
    } else {
      localNickname[id] = name;
    }

    List<String> ss = [];
    localNickname.forEach((key, value) {
      ss.add(key.toString() + ":" + value);
    });
    setList('display/localNickname', ss, split: strSplit);
  }

  String getLocalNickname(int id, String def) {
    if (localNickname.containsKey(id)) {
      return localNickname[id];
    }
    return def;
  }
}
