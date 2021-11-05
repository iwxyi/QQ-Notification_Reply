import 'dart:async';
import 'dart:convert';
import 'package:qqnotificationreply/global/appruntime.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/global/usersettings.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket使用说明：https://zhuanlan.zhihu.com/p/133849780
class CqhttpService {
  bool debugMode = false;
  AppRuntime rt;
  UserSettings st;
  UserAccount ac;

  String host = "";
  String token = "";

  IOWebSocketChannel channel;
  int lastHeartTime = 0; // 最后心跳的时间戳（毫秒）
  List<String> wsReceives = []; // 收到的所有数据，用于调试（仅消息的日志）

  num _reconnectCount = 0; // 重连次数，并且影响每次重连的时间间隔
  Timer _reconnectTimer;

  Map<String, String> CQCodeMap = {
    'face': '表情',
    'image': '图片',
    'video': '视频',
    'reply': '回复',
    'forward': '转发',
    'redbag': '红包'
  };

  CqhttpService({this.rt, this.st, this.ac});

  /// 连接Socket
  Future<bool> connect(String host, String token) async {
    // 清理之前的数据
    wsReceives.clear();

    // 预处理输入
    if (!host.contains('://')) {
      host = 'ws://' + host;
    }
    st.setConfig('account/host', this.host = host);
    st.setConfig('account/token', this.token = token);

    return _openSocket(host, token);
  }

  bool isConnected() {
    return channel != null && channel.innerWebSocket != null;
  }

  bool _openSocket(String host, String token) {
    Map<String, dynamic> headers = new Map();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer ' + token;
    }

    // 旧的 channel 还在时依旧连接的话，会导致重复接收到消息
    if (isConnected()) {
      print(log('关闭旧的ws连接'));
      channel.innerWebSocket.close();
      channel = null;
    }

    // 开始连接
    try {
      // 如果网络有问题，这里会产生错误
      print(log('ws连接: ' + host));
      channel = IOWebSocketChannel.connect(host, headers: headers);
    } catch (e) {
      print(log('ws连接错误'));
      return false;
    }

    // 连接成功，监听消息
    channel.stream.listen((message) {
      if (debugMode) {
        print(log('ws收到数据:' + message.toString().substring(0, 1000)));
        wsReceives.insert(0, message.toString());
      }

      _processReceivedData(json.decode(message.toString()));
    }, onError: (e) {
      WebSocketChannelException ex = e;
      print(log('ws错误: ' + ex.message));
    }, onDone: () {
      // 实际上是 onClose？连接结束，即关闭
      print(log('ws断开，等待重连...'));
      if (channel.innerWebSocket != null) {
        channel.innerWebSocket.close();
        channel = null;
      }
      reconnect(host, token);
    });

    // 关闭定时连接
    _reconnectCount = 0;
    if (_reconnectTimer != null) {
      _reconnectTimer.cancel();
      _reconnectTimer = null;
    }

    return true;
  }

  void send(Map<String, dynamic> obj) {
    String text = json.encode(obj);
    print('ws发送数据：' + text);
    channel.sink.add(text);
  }

  void reconnect(String host, String token) {
    _reconnectCount++;
    if (_reconnectTimer != null) {
      _reconnectTimer.cancel();
      _reconnectTimer = null;
    }

    if (this.host != host || this.token != token) {
      // 账号密码修改了，那么之前的尝试重连就不需要了
      return;
    }

    _reconnectTimer =
        new Timer.periodic(Duration(seconds: _reconnectCount * 2), (timer) {
      print(log('重连检测$_reconnectCount：' + (isConnected() ? '已连接' : '尝试重连...')));
      // 已经连接上了
      if (isConnected()) {
        if (_reconnectTimer != null) {
          _reconnectTimer.cancel();
          _reconnectTimer = null;
        }
        return;
      }
      // 尝试连接
      _openSocket(host, token);
    });
  }

  void _processReceivedData(Map<String, dynamic> obj) {
    // 先判断是不是自己主动获取消息的echo
    if (obj.containsKey('echo')) {
      // 解析返回的数据
      _parseEchoMessage(obj);
      return;
    }

    String postType = obj['post_type'];
    if (postType == 'meta_event') {
      // 心跳，忽略
      String subType = obj['sub_type'];
      if (subType == 'connect') {
        // 第一次连接上
        _parseLifecycle(obj);
      }
      lastHeartTime = DateTime.now().millisecondsSinceEpoch;
    } else if (postType == 'message' || postType == 'message_sent') {
      // 自己发送的群消息是 message_sent 类型
      String messageType = obj['message_type'];
      if (messageType == 'private') {
        // 私聊消息
        _parsePrivateMessage(obj);
      } else if (messageType == 'group') {
        // 群聊消息
        _parseGroupMessage(obj);
      } else {
        print('未处理的消息：' + obj.toString());
      }
    } else if (postType == 'notice') {
      String noticeType = obj['notice_type'];
      if (noticeType == 'group_upload') {
        // 群文件上传
        _parseGroupUpload(obj);
      } else if (noticeType == 'offline_file') {
        // 私聊文件上传
        _parseOfflineFile(obj);
      } else if (noticeType == 'group_recall') {
        // 撤销群消息
        _parseGroupRecall(obj);
      } else if (noticeType == 'friend_recall') {
        // 撤销私聊消息
        _parseFriendRecall(obj);
      } else if (noticeType == 'group_card') {
        // 修改群名片
        _parseGroupCard(obj);
      } else if (noticeType == 'group_ban') {
        // 群禁言
        _parseGroupBan(obj);
      } else {
        print('未处理类型的通知：' + obj.toString());
      }
    } else if (postType == 'message_sent') {
      // 自己发的消息
      _parseMessageSent(obj);
    } else {
      print('未处理类型的数据：' + obj.toString());
    }
  }

  /// 连接上，必定会触发这个
  void _parseLifecycle(final obj) {
    int userId = obj['self_id']; // 自己的QQ号
    ac.qqId = userId;

    // 发送获取登录号信息
    send({'action': 'get_login_info', 'echo': 'get_login_info'});
    getFriendList();
    getGroupList();
    ac.eventBus.fire(EventFn(Event.loginSuccess, {}));
  }

  void _parseEchoMessage(final obj) {
    String echo = obj['echo'];
    if (echo == 'get_login_info') {
      // 登录信息
      var data = obj['data'];
      ac.qqId = data['user_id'];
      ac.nickname = data['nickname'];
      print(log('登录账号：' + ac.nickname + "  " + ac.qqId.toString()));
      ac.eventBus.fire(
          EventFn(Event.loginInfo, {'qqId': ac.qqId, 'nickname': ac.nickname}));
    } else if (echo == 'get_friend_list') {
      // 好友列表
      ac.friendList.clear();
      List data = obj['data']; // 好友数组
      print('好友数量: ' + data.length.toString());
      data.forEach((friend) {
        int userId = friend['user_id'];
        String nickname = friend['nickname'];
        String remark;
        if (friend.containsKey('remark')) remark = friend['remark'];
        ac.friendList[userId] = new FriendInfo(userId, nickname, remark);
      });
      ac.eventBus.fire(EventFn(Event.friendList, {}));
    } else if (echo == 'get_group_list') {
      // 群组列表
      ac.groupList.clear();
      List data = obj['data']; // 好友数组
      print('群组数量: ' + data.length.toString());
      data.forEach((friend) {
        int groupId = friend['group_id'];
        String groupName = friend['group_name'];
        ac.groupList[groupId] = new GroupInfo(groupId, groupName);
      });
      ac.eventBus.fire(EventFn(Event.groupList, {}));
    } else if (echo == 'send_private_msg' || echo == 'send_group_msg') {
      // 发送消息的回复，不做处理
    } else if (echo.startsWith('get_group_member_list')) {
      // 获取群组，echo字段格式为：get_group_member_list:123456
      RegExp re = RegExp(r'^get_group_member_list:(\d+)$');
      Match match;
      if ((match = re.firstMatch(echo)) != null) {
        int groupId = int.parse(match.group(1));
        ac.gettingGroupMembers.remove(groupId);
        if (!ac.groupList.containsKey(groupId)) {
          print('群组列表未包含：' + groupId.toString() + '，无法设置群成员');
          return;
        }
        ac.groupList[groupId].members = {};
        List data = obj['data']; // 群成员数组
        data.forEach((member) {
          int userId = member['user_id'];
          String nickname = member['nickname'];
          String card = member['card'];
          ac.groupList[groupId].members[userId] =
              new FriendInfo(userId, nickname, card);
        });
        ac.eventBus.fire(EventFn(Event.groupMember, {'group_id': groupId}));
      } else {
        print('无法识别的群成员echo: ' + echo);
      }
    } else {
      print('未处理类型的echo: ' + echo);
    }
  }

  void _parsePrivateMessage(final obj) {
    String subType = obj['sub_type'];
    String message = obj['message'];
    String rawMessage = obj['raw_message'];
    int messageId = obj['message_id'];
    int targetId = obj['target_id'];

    var sender = obj['sender'];
    int senderId = sender['user_id']; // 发送者QQ，大概率是别人，也可能是自己
    String nickname = sender['nickname'];

    int friendId = (senderId == ac.qqId ? targetId : senderId);

    MsgBean msg = new MsgBean(
        subType: subType,
        senderId: senderId,
        targetId: targetId,
        message: message,
        rawMessage: rawMessage,
        messageId: messageId,
        nickname: nickname,
        remark: ac.friendList.containsKey(friendId)
            ? ac.friendList[friendId].username()
            : null,
        friendId: friendId,
        timestamp: DateTime.now().millisecondsSinceEpoch);

    print('收到私聊消息：' + msg.username() + " : " + message);

    _notifyOuter(msg);
  }

  void _parseGroupMessage(final obj) {
    String subType = obj['sub_type'];
    String message = obj['message'];
    String rawMessage = obj['raw_message'];
    int groupId = obj['group_id'];
    int messageId = obj['message_id'];

    var sender = obj['sender'];
    int senderId = sender['user_id']; // 发送者QQ，大概率是别人，也可能是自己
    String nickname = sender['nickname'];
    String card = sender['card']; // 群名片，可能为空
    String role = sender['role']; // 角色：owner/admin/member

    if (subType == 'anonymous') {
      // 匿名消息，不想作处理
      var anonymous = obj['anonymous'];
      senderId = anonymous['id'];
      nickname = anonymous['name'];
    }

    String groupName = ac.groupList.containsKey(groupId)
        ? ac.groupList[groupId].name
        : groupId.toString();

    print('收到群消息：' +
        ac.groupList[groupId].name +
        " - " +
        nickname +
        " : " +
        message);

    MsgBean msg = MsgBean(
        subType: subType,
        groupId: groupId,
        groupName: groupName,
        senderId: senderId,
        nickname: nickname,
        groupCard: card,
        messageId: messageId,
        message: message,
        rawMessage: rawMessage,
        targetId: groupId,
        remark: ac.friendList.containsKey(senderId)
            ? ac.friendList[senderId].username()
            : null,
        role: role,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    _notifyOuter(msg);
  }

  void _parseGroupUpload(final obj) {}

  void _parseOfflineFile(final obj) {}

  void _parseMessageSent(final obj) {}

  void _parseGroupRecall(final obj) {
    int groupId = obj['group_id'];
    int messageId = obj['message_id'];
    int userId = obj['user_id']; // 发送者ID
    int operatorId = obj['operator_id']; // 操作者ID（发送者或者群管理员）

    print('群消息撤回：[$groupId] $messageId($userId)');
  }

  void _parseFriendRecall(final obj) {}

  void _parseGroupCard(final obj) {}

  void _parseGroupBan(final obj) {}

  void refreshFriend() {}

  void refreshGroups() {}

  void refreshGroupMembers(int groupId) {
    if (ac.gettingGroupMembers.containsKey(groupId)) {
      // 有其他线程获取了
      return;
    }
    ac.gettingGroupMembers[groupId] = true;
    send({
      'action': 'get_group_member_list',
      'params': {'group_id': groupId},
      'echo': 'get_group_member_list:' + groupId.toString()
    });
  }

  void getFriendList() {
    send({'action': 'get_friend_list', 'echo': 'get_friend_list'});
  }

  void getGroupList() {
    send({'action': 'get_group_list', 'echo': 'get_group_list'});
  }

  void sendPrivateMessage(int userId, String message) {
    send({
      'action': 'send_private_msg',
      'params': {'user_id': userId, 'message': message},
      'echo': 'send_private_msg'
    });
  }

  void sendGroupMessage(int groupId, String message) {
    send({
      'action': 'send_group_msg',
      'params': {'group_id': groupId, 'message': message},
      'echo': 'send_group_msg'
    });
  }

  /// 发送消息到界面
  /// 有多个接收槽：
  /// - main_pages 通知
  /// - chats_page 消息列表
  /// - account_widget 消息数量（包括所有）
  void _notifyOuter(MsgBean msg) {
    // 保存所有 msg 记录
    // ac.allLogs.add(msg);
    /* if (ac.allMessages.length > st.keepMsgHistoryCount) {
      ac.allMessages.removeAt(0);
    } */

    // 保留每个对象的消息记录
    if (!ac.allMessages.containsKey(msg.keyId())) {
      ac.allMessages[msg.keyId()] = [];
    }
    ac.allMessages[msg.keyId()].add(msg);
    if (ac.allMessages[msg.keyId()].length > st.keepMsgHistoryCount) {
      ac.allMessages[msg.keyId()].removeAt(0);
    }

    // 刷新收到消息的时间（用于简单选择时的排序）
    // 以及未读消息的数量
    int time = DateTime.now().millisecondsSinceEpoch;
    ac.messageTimes[msg.keyId()] = time;
    if (msg.senderId == ac.qqId) {
      // 自己发的，清空未读
      ac.unreadMessageCount.remove(msg.keyId());
    } else if (rt.currentChatPage != null &&
        rt.currentChatPage.chatObj.isObj(msg)) {
      // 正在显示这个聊天界面，则不进行操作
    } else {
      // 添加未读
      ac.unreadMessageCount[msg.keyId()] =
          (ac.unreadMessageCount.containsKey(msg.keyId())
                  ? ac.unreadMessageCount[msg.keyId()]
                  : 0) +
              1;
    }

    // 通知界面
    ac.eventBus.fire(EventFn(Event.messageRaw, msg));
  }

  /// 添加一个日志
  String log(String text) {
    ac.allLogs.add(new MsgBean(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        message: text,
        action: ActionType.SystemLog));
    return text;
  }

  /// 简易版数据展示
  /// 替换所有CQ标签
  String getMessageDisplay(MsgBean msg) {
    String text = msg.message;

    text = text.replaceAll(RegExp(r"\[CQ:image,type=flash,.+?\]"), '[闪照]');
    text = text.replaceAll(
        RegExp(r"\[CQ:reply,.+?\](\[CQ:at,qq=\d+?\])?"), '[回复]');
    text = text.replaceAll(RegExp(r"\[CQ:at,qq=all\]"), '@全体成员');
    text = text.replaceAllMapped(RegExp(r"\[CQ:at,qq=(\d+)\]"), (match) {
      var id = int.parse(match[1]);
      String username = ac.getGroupMemberName(id, msg.groupId);
      if (username != null) return '@' + username;
      // 未获取到昵称
      if (msg.isGroup()) {
        // 获取群成员
        refreshGroupMembers(msg.groupId);
      }
      return '@' + match[1];
    });
    text = text.replaceAllMapped(
        RegExp(r'^\[CQ:json,data=.+?"prompt":"(.+?)".*?\]'),
        (match) => '[${match[1]}]');
    text = text.replaceAllMapped(RegExp(r"\[CQ:([^,]+),.+?\]"), (match) {
      if (CQCodeMap.containsKey(match[1])) {
        return "[${CQCodeMap[match[1]]}]";
      }
      return match[1];
    });
    text = text.replaceAllMapped(
        RegExp(r"\[CQ:([^,]+),.+?\]"), (match) => '[${match[1]}]');
    text = text.replaceAll('&#91;', '[').replaceAll('&#93;', ']');

    return text;
  }
}
