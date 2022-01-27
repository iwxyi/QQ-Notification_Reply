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

  // ignore: non_constant_identifier_names
  Map<String, String> CQCodeMap = {
    'face': '表情',
    'image': '图片',
    'video': '视频',
    'reply': '回复',
    'record': '语音',
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
      if (st.debugMode) {
        int length = message.toString().length;
        if (length > 1000) length = 1000;
        print(log('ws收到数据:' + message.toString().substring(0, length)));
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
    if (_reconnectTimer != null) {
      _reconnectTimer.cancel();
      _reconnectTimer = null;
    }

    return true;
  }

  /// 发送socket
  void send(Map<String, dynamic> obj) {
    String text = json.encode(obj);
    print('ws发送数据：' + text);
    channel.sink.add(text);
  }

  /// 群组或者私聊通用的发送消息
  /// msg 发送对象
  /// 都是自己手动发送的
  void sendMsg(MsgBean chatObj, String text) {
    if (text == null) {
      return;
    }
    if (chatObj.isGroup()) {
      _sendGroupMessage(chatObj.groupId, text);

      // 群消息智能聚焦
      if (st.groupSmartFocus) {
        if (text.endsWith('?') ||
            text.endsWith('？') ||
            RegExp(r'问|谁|何|什么|哪儿|哪里|几|多少|怎|吗|难道|岂|居然|竟然|究竟|简直|难怪|how|what|when|who|which')
                .hasMatch(text)) {
          ac.groupList[chatObj.groupId]?.focusAsk = true;
          print('智能聚焦.疑问?');
        }
        Iterable<RegExpMatch> matches =
            RegExp(r'\[CQ:at,qq=(\d+)\]').allMatches(text);
        if (matches.length > 0) {
          if (ac.groupList[chatObj.groupId].focusAt == null) {
            ac.groupList[chatObj.groupId].focusAt = {};
          }
          for (int i = 0; i < matches.length; i++) {
            RegExpMatch match = matches.elementAt(i);
            int id = int.parse(match.group(1));
            ac.groupList[chatObj.groupId].focusAt.add(id);
            print('智能聚焦.@$id');
          }
        }
      }

      // 群消息动态重要性
      ac.messageMyTimes[chatObj.keyId()] =
          DateTime.now().millisecondsSinceEpoch;
    } else if (chatObj.isPrivate()) {
      _sendPrivateMessage(chatObj.friendId, text);
    } else {
      print('无法判断的发送对象');
    }

    ac.receivedCountAfterMySent[chatObj.keyId()] = 0;
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

    _reconnectTimer = new Timer.periodic(
        Duration(seconds: _reconnectCount * _reconnectCount), (timer) {
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
      // print(obj); // 输出所有消息
      // 自己发送的群消息是 message_sent 类型
      String messageType = obj['message_type'];
      if (messageType == 'private') {
        // 私聊消息
        parsePrivateMessage(obj);
      } else if (messageType == 'group') {
        // 群聊消息
        parseGroupMessage(obj);
      } else {
        print('未处理的消息：' + obj.toString());
      }
    } else if (postType == 'notice') {
      String noticeType = obj['notice_type'];
      if (noticeType == 'group_upload') {
        // 群文件上传
        _parseGroupUpload(obj);
      } else if (noticeType == 'group_increase') {
        _parseGroupIncrease(obj);
      } else if (noticeType == 'group_decrease') {
        _parseGroupDecrease(obj);
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
    } else if (postType == 'request') {
      String requestType = obj['request_type'];
      if (requestType == 'friend') {
        _parseRequestFriend(obj);
      } else {
        print('未处理类型的请求：' + obj.toString());
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
    // 清空旧的数据
    ac.gettingChatObjColor.clear();
    ac.gettingGroupMembers.clear();
    ac.gettingGroupHistories.clear();

    // 自己的信息
    int userId = obj['self_id']; // 自己的QQ号
    ac.myId = userId;

    // 发送获取登录号信息
    send({'action': 'get_login_info', 'echo': 'get_login_info'});
    getFriendList();
    getGroupList();
    ac.eventBus.fire(EventFn(Event.loginSuccess, {}));

    _reconnectCount = 0; // 登录完成才重置重连次数
  }

  void _parseEchoMessage(final obj) {
    String echo = obj['echo'];
    if (echo == 'get_login_info') {
      // 登录信息
      var data = obj['data'];
      ac.myId = data['user_id'];
      ac.myNickname = data['nickname'];
      print(log('登录账号：' + ac.myNickname + "  " + ac.myId.toString()));
      ac.eventBus.fire(EventFn(
          Event.loginInfo, {'qqId': ac.myId, 'nickname': ac.myNickname}));
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
        print('加载群成员：${data.length}');
        ac.eventBus.fire(EventFn(Event.groupMember, {'group_id': groupId}));
      } else {
        print('无法识别的群成员echo: ' + echo);
      }
    } else if (echo.startsWith('msg_recall_group')) {
      // 群消息撤回，有对应的事件，就不处理了
    } else if (echo.startsWith('msg_recall_friend')) {
      // 好友消息撤回
      RegExp re = RegExp(r'^msg_recall_friend:(\d+)_(-?\d+)$');
      Match match;
      if ((match = re.firstMatch(echo)) != null) {
        int friendId = int.parse(match.group(1));
        int messageId = int.parse(match.group(2));
        MsgBean msg = new MsgBean(
            senderId: ac.myId, friendId: friendId, messageId: messageId);
        _markRecalled(msg);
      } else {
        print('无法识别的撤回echo: ' + echo);
      }
    } else if (echo.startsWith('get_user_info')) {
      // 获取用户信息
      print(obj['data']);
      ac.eventBus.fire(EventFn(Event.userInfo, obj['data']));
    } else if (echo.startsWith('get_group_msg_history')) {
      // 获取群组，echo字段格式为：get_group_msg_history:123456
      RegExp re = RegExp(r'^get_group_msg_history:(\d+)$');
      Match match;
      if ((match = re.firstMatch(echo)) != null) {
        int groupId = int.parse(match.group(1));
        ac.gettingGroupHistories.remove(groupId);
        if (!ac.groupList.containsKey(groupId)) {
          print('群组列表未包含：' + groupId.toString() + '，无法设置群成员');
          return;
        }
        int keyId = MsgBean(groupId: groupId).keyId();
        List<MsgBean> list = ac.allMessages[keyId];
        if (list == null) {
          ac.allMessages[keyId] = [];
          list = ac.allMessages[keyId];
        }

        // 获取当前最旧seqId
        int earliestId = 0;
        {
          int i = -1;
          while (++i < list.length) {
            if (list[i].action == MessageType.Message) {
              earliestId = list[i].messageSeq;
              break;
            }
          }
        }

        // 插入历史数据
        List data = obj['data']['messages']; // 消息数组
        int insertPos = 0;
        for (int i = 0; i < data.length; i++) {
          var messageObj = data[i];
          // 插入到list的开头
          MsgBean msg = createGroupMsgFromJson(messageObj);
          if (msg.messageSeq == earliestId) {
            // print('遇到重复ID，已退出：$i in ${data.length}');
            // 一般拿到20条，第19条的时候就重复了，实际上多了18条
            break;
          }
          list.insert(insertPos++, msg);
        }
        print('加载云端群消息历史：${data.length}');
        ac.eventBus
            .fire(EventFn(Event.groupMessageHistories, {'group_id': groupId}));
      } else {
        print('无法识别的群成员echo: ' + echo);
      }
    } else {
      print('未处理类型的echo: ' + echo);
    }
  }

  void parsePrivateMessage(final obj) {
    String subType = obj['sub_type']; // friend
    String message = obj['message'];
    String rawMessage = obj['raw_message'];
    int messageId = obj['message_id'];
    int targetId = obj['target_id'];
    int messageSeq = obj['message_seq']; // 私聊是nullptr

    var sender = obj['sender'];
    int senderId = sender['user_id']; // 发送者QQ，大概率是别人，也可能是自己
    String nickname = sender['nickname'];

    int friendId = (senderId == ac.myId ? targetId : senderId);

    MsgBean msg = new MsgBean(
        subType: subType,
        senderId: senderId,
        targetId: targetId,
        message: message,
        rawMessage: rawMessage,
        messageId: messageId,
        messageSeq: messageSeq,
        nickname: nickname,
        remark: ac.friendList.containsKey(friendId)
            ? ac.friendList[friendId].username()
            : null,
        friendId: friendId,
        timestamp: DateTime.now().millisecondsSinceEpoch);

    print('收到私聊消息：${msg.username()} : $message');

    _notifyOuter(msg);
  }

  void parseGroupMessage(final obj) {
    MsgBean msg = createGroupMsgFromJson(obj);
    print('收到群消息：${msg.groupName ?? ''} - ${msg.nickname}  : ${msg.message}');
    _notifyOuter(msg);
  }

  MsgBean createGroupMsgFromJson(final obj) {
    String subType = obj['sub_type'];
    String message = obj['message'];
    String rawMessage = obj['raw_message'];
    int groupId = obj['group_id'];
    int messageId = obj['message_id'];
    int messageSeq = obj['message_seq'];

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

    String groupName = getGroupName(groupId);

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
        messageSeq: messageSeq,
        targetId: groupId,
        remark: ac.friendList.containsKey(senderId)
            ? ac.friendList[senderId].username()
            : null,
        role: role,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    return msg;
  }

  void _parseGroupUpload(final obj) {
    int groupId = obj['group_id'];
    int userId = obj['user_id'];

    var file = obj['file'];
    String fileId = file['id'];
    String fileName = file['name'];
    int fileSize = file['size'];

    String groupName = getGroupName(groupId);
    String nickname = ac.getGroupMemberName(userId, groupId);

    print('收到群文件：$groupName - $nickname  : $fileName');
    MsgBean msg = new MsgBean(
        groupId: groupId,
        groupName: groupName,
        senderId: userId,
        nickname: nickname,
        fileId: fileId,
        fileName: fileName,
        fileSize: fileSize,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    _notifyOuter(msg);
  }

  void _parseOfflineFile(final obj) {
    int userId = obj['user_id'];

    var file = obj['file'];
    String fileName = file['name'];
    int fileSize = file['size'];
    String fileUrl = file['url'];

    String nickname = ac.getGroupMemberName(userId, null);

    print('收到离线文件：$nickname  : $fileName');
    MsgBean msg = new MsgBean(
        senderId: userId,
        nickname: nickname,
        fileName: fileName,
        fileSize: fileSize,
        fileUrl: fileUrl,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    _notifyOuter(msg);
  }

  void _parseMessageSent(final obj) {}

  void _parseGroupRecall(final obj) {
    int groupId = obj['group_id'];
    int messageId = obj['message_id'];
    int userId = obj['user_id']; // 发送者ID
    int operatorId = obj['operator_id']; // 操作者ID（发送者或者群管理员）

    String groupName = getGroupName(groupId);

    print('群消息撤回：[$groupId] $messageId($userId)');
    MsgBean msg = new MsgBean(
        groupId: groupId,
        groupName: groupName,
        messageId: messageId,
        senderId: operatorId);
    _markRecalled(msg);
  }

  /// 这是私聊的好友消息撤回
  /// 自己撤回的接收不到，只能监听撤回自己消息的回调
  void _parseFriendRecall(final obj) {
    int messageId = obj['message_id'];
    int userId = obj['user_id']; // 好友ID

    print('私聊消息撤回：$messageId($userId)');
    MsgBean msg =
        new MsgBean(messageId: messageId, senderId: userId, friendId: userId);
    _markRecalled(msg);
  }

  void _parseGroupIncrease(final obj) {
    String subType = obj['sub_type']; // approve / invite
    int groupId = obj['group_id'];
    int operatorId = obj['operator_id']; // 操作者
    int userId = obj['user_id']; // 用户ID

    String nickname = getGroupMemberName(userId, groupId);
    String groupName = getGroupName(groupId);
    String message = "{{username}} 加入本群";
    if (subType == "invite") {
      message = "{{username}} 被邀请入群";
    }

    print("新成员进入：$userId");
    MsgBean msg = new MsgBean(
        nickname: nickname,
        groupId: groupId,
        groupName: groupName,
        operatorId: operatorId,
        senderId: userId,
        subType: subType,
        action: MessageType.Action,
        message: message,
        messageId: DateTime.now().millisecondsSinceEpoch,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    _notifyOuter(msg);
  }

  void _parseGroupDecrease(final obj) {
    String subType = obj['sub_type']; // 退群leave/被踢kick/登录号被踢kick_me
    int groupId = obj['group_id'];
    int operatorId = obj['operator_id']; // 操作者（如果主动退群，则和userId相同）
    int userId = obj['user_id']; // 用户ID

    String nickname = getGroupMemberName(userId, groupId);
    String groupName = getGroupName(groupId);
    String message = "{{username}} 退出本群";
    if (subType == "leave") {
      message = "{{username}} 退出本群";
    } else {
      message = "{{username}} 被 {{operator_name}} 踢出本群";
    }

    print("成员退群：$userId");
    MsgBean msg = new MsgBean(
        nickname: nickname,
        groupId: groupId,
        groupName: groupName,
        operatorId: operatorId,
        senderId: userId,
        subType: subType,
        action: MessageType.Action,
        message: message,
        messageId: DateTime.now().millisecondsSinceEpoch,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    _notifyOuter(msg);
  }

  /// 修改群名片（不保证时效性，且名片任意时刻都有可能为空）
  void _parseGroupCard(final obj) {
    String subType = obj['sub_type']; // 退群leave/被踢kick/登录号被踢kick_me
    int groupId = obj['group_id'];
    int userId = obj['user_id']; // 用户ID
    String cardNew = obj['card_new'];
    // ignore: unused_local_variable
    String cardOld = obj['card_old'];

    String nickname = getGroupMemberName(userId, groupId);
    String groupName = getGroupName(groupId);

    print("修改群名片：$cardOld -> $cardNew");
    MsgBean msg = new MsgBean(
        nickname: nickname,
        groupId: groupId,
        groupName: groupName,
        senderId: userId,
        subType: subType,
        action: MessageType.Action,
        message: "{{username}} 修改名片为 $cardNew",
        messageId: DateTime.now().millisecondsSinceEpoch,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    _notifyOuter(msg);
  }

  /// 群禁言
  void _parseGroupBan(final obj) {
    String subType = obj['sub_type']; // 禁言ban/解除禁言lift_ban
    int groupId = obj['group_id'];
    int operatorId = obj['operator_id']; // 操作者
    int userId = obj['user_id']; // 用户ID
    int duration = obj['duration']; // 禁言几秒

    String nickname = getGroupMemberName(userId, groupId);
    String groupName = getGroupName(groupId);

    String message;
    if (subType == "lift_ban") {
      // 解除禁言
      message = "{{username}} 被 {{operator_name}} 解除禁言";
      print("$userId 被解除禁言");
    } else {
      // 禁言
      String time = "$duration 秒";
      if (duration > 60) {
        duration ~/= 60;
        time = "$duration 分钟";
      }
      if (duration > 60) {
        duration ~/= 60;
        time = "$duration 小时";
      }
      if (duration > 24) {
        duration ~/= 24;
        time = "$duration 天";
      }
      message = "{{username}} 被 {{operator_name}} 禁言 $time";
      print("$userId 被禁言 $time");
    }

    MsgBean msg = new MsgBean(
        nickname: nickname,
        groupId: groupId,
        groupName: groupName,
        operatorId: operatorId,
        senderId: userId,
        subType: subType,
        action: MessageType.Action,
        message: message,
        messageId: DateTime.now().millisecondsSinceEpoch,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    _notifyOuter(msg);
  }

  /// 加好友请求
  void _parseRequestFriend(final obj) {}

  void refreshFriend() {}

  void refreshGroups() {}

  void refreshGroupMembers(int groupId, {int userId}) {
    if (ac.gettingGroupMembers.contains(groupId)) {
      // 有其他线程获取了
      // print('已经有线程在获取群 $groupId 成员了');
      return;
    }
    if (userId != null) {
      if (ac.groupList[groupId].ignoredMembers == null) {
        ac.groupList[groupId].ignoredMembers = {};
      } else if (ac.groupList[groupId].ignoredMembers.contains(userId)) {
        // 已经获取过这个用户了
        // print('已经获取过这个群 $groupId 的成员 $userId 了');
        return;
      }
      ac.groupList[groupId].ignoredMembers.add(userId);
    }

    // print('刷新群成员：$groupId');
    ac.gettingGroupMembers.add(groupId);
    send({
      'action': 'get_group_member_list',
      'params': {'group_id': groupId},
      'echo': 'get_group_member_list:' + groupId.toString()
    });
  }

  void getGroupMessageHistories(int groupId, int messageSeq) {
    if (ac.gettingGroupHistories.contains(groupId)) {
      print("正在获取该群历史消息：$groupId");
      return;
    }
    ac.gettingGroupMembers.add(groupId);
    send({
      'action': 'get_group_msg_history',
      'params': {'message_seq': messageSeq, 'group_id': groupId},
      'echo': 'get_group_msg_history:$groupId'
    });
  }

  void getFriendList() {
    send({'action': 'get_friend_list', 'echo': 'get_friend_list'});
  }

  void getGroupList() {
    send({'action': 'get_group_list', 'echo': 'get_group_list'});
  }

  void _sendPrivateMessage(int userId, String message) {
    if (message == null || message.isEmpty) {
      return;
    }
    send({
      'action': 'send_private_msg',
      'params': {'user_id': userId, 'message': message},
      'echo': 'send_private_msg'
    });
  }

  void _sendGroupMessage(int groupId, String message) {
    if (message == null || message.isEmpty) {
      return;
    }
    send({
      'action': 'send_group_msg',
      'params': {'group_id': groupId, 'message': message},
      'echo': 'send_group_msg'
    });
  }

  void _markRecalled(MsgBean msg) {
    if (ac.allMessages.containsKey(msg.keyId())) {
      int index = ac.allMessages[msg.keyId()]
          .lastIndexWhere((element) => element.messageId == msg.messageId);
      if (index > -1) {
        // 设置为撤回
        ac.allMessages[msg.keyId()][index].recalled = true;
      }
      ac.eventBus.fire(EventFn(Event.messageRecall, msg));
    }
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
      if (msg.action == MessageType.Action) {
        // 一些不显示消息的群，却显示了进退群，没必要
        return;
      }
      ac.allMessages[msg.keyId()] = [];
    } else {
      // 去除重复消息，可能是bug，有时候会发两遍一样的消息
      bool repeat = false;
      ac.allMessages[msg.keyId()].forEach((element) {
        if (element.messageId != null &&
            element.messageId != 0 &&
            element.messageId == msg.messageId) repeat = true;
      });
      if (repeat) {
        print('warning: 去除重复消息');
        return;
      }
    }

    ac.allMessages[msg.keyId()].add(msg);
    if (ac.allMessages[msg.keyId()].length > st.keepMsgHistoryCount) {
      ac.allMessages[msg.keyId()].removeAt(0);
    }

    // 刷新收到消息的时间（用于简单选择时的排序）
    // 以及未读消息的数量
    int time = DateTime.now().millisecondsSinceEpoch;
    ac.messageTimes[msg.keyId()] = time;
    if (msg.senderId == ac.myId) {
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

    // 自己发送消息后收到的消息数量（包括当前自己的一条）
    if (msg.senderId != null) {
      int count = ac.receivedCountAfterMySent[msg.keyId()] ?? 0;
      ac.receivedCountAfterMySent[msg.keyId()] = count + 1;
    }

    // 通知界面
    ac.eventBus.fire(EventFn(Event.messageRaw, msg));
  }

  /// 添加一个日志
  String log(String text) {
    ac.allLogs.add(new MsgBean(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        message: text,
        action: MessageType.SystemLog));
    return text;
  }

  String getGroupName(int groupId) {
    return ac.groupList.containsKey(groupId)
        ? ac.groupList[groupId].name
        : groupId.toString();
  }

  String getUserName(int userId) {
    return st.getLocalNickname(
        userId,
        ac.friendList.containsKey(userId)
            ? ac.friendList[userId].remark ?? ac.friendList[userId].nickname
            : "$userId");
  }

  String getGroupMemberName(int userId, int groupId) {
    if (groupId == null || groupId == 0) {
      return getUserName(userId);
    }
    String name = ac.getGroupMemberName(userId, groupId);
    if (name != null) {
      return name;
    }
    refreshGroupMembers(groupId, userId: userId);
    return "$userId";
  }

  /// 简易版数据展示
  /// 替换所有CQ标签
  String getMessageDisplay(MsgBean msg) {
    String text = msg.message ?? '';
    switch (msg.action) {
      case MessageType.Message:
        if (msg.isFile()) {
          text = '[${msg.fileName}]';
        } else {
          text = text.replaceAll(
              RegExp(r"\[CQ:reply,.+?\]\s*(\[CQ:at,qq=\d+?\])?"), '[回复]');
          text =
              text.replaceAll(RegExp(r"\[CQ:image,type=flash,.+?\]"), '[闪照]');
          text = text.replaceAll(RegExp(r"\[CQ:at,qq=all\]"), '@全体成员');
          text = text.replaceAllMapped(RegExp(r"\[CQ:at,qq=(\d+)\]"), (match) {
            var id = int.parse(match[1]);
            String username = ac.getGroupMemberName(id, msg.groupId);
            username = st.getLocalNickname(id, username);
            if (username != null) return '@' + username;
            // 未获取到昵称
            if (msg.isGroup()) {
              // 获取群成员
              refreshGroupMembers(msg.groupId, userId: id);
            }
            return '@' + match[1];
          });
          text = text.replaceAllMapped(RegExp(r'\[CQ:redbag,title=(.+?)\]'),
              (match) => '[红包: ${match[1]}]');
          Match mat = RegExp(r'\[CQ:json,data=.+?"(?:prompt)":"(.+?)".*?\]')
              .firstMatch(text);
          if (mat != null) {
            text = mat[1];
          }
          // 中文名字
          text = text.replaceAllMapped(RegExp(r"\[CQ:([^,]+),.+?\]"), (match) {
            if (CQCodeMap.containsKey(match[1])) {
              return "[${CQCodeMap[match[1]]}]";
            }
            return '[${match[1]}]';
          });
          // 其他类型
          text = text.replaceAllMapped(
              RegExp(r"\[CQ:([^,]+),.+?\]"), (match) => '[${match[1]}]');
          text = text
              .replaceAll('&#91;', '[')
              .replaceAll('&#93;', ']')
              .replaceAll('\n\n', '\n')
              .replaceAll('&amp;', '&');
        }
        break;
      case MessageType.Action:
        {
          String format = msg.message ?? "Error Message Format";
          text = format
              .replaceAll(
                  "{{username}}", getGroupMemberName(msg.senderId, msg.groupId))
              .replaceAll("{{operator_name}}",
                  getGroupMemberName(msg.operatorId, msg.groupId));
        }
        break;
      case MessageType.SystemLog:
        {
          text = '${msg.simpleString()}';
        }
        break;
    }

    return text;
  }
}
