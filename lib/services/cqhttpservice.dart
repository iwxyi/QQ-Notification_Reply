import 'dart:convert';
import 'package:qqnotificationreply/global/appruntime.dart';
import 'package:qqnotificationreply/global/event_bus.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/global/usersettings.dart';
import 'package:qqnotificationreply/services/msgbean.dart';
import 'package:web_socket_channel/io.dart';

/// WebSocket使用说明：https://zhuanlan.zhihu.com/p/133849780
class CqhttpService {
  final debugMode = true;
  AppRuntime rt;
  UserSettings st;
  UserAccount ac;
  
  IOWebSocketChannel channel;
  List<String> wsReceives = [];
  
  CqhttpService({this.rt, this.st, this.ac});
  
  Future<bool> connect(String host, String token) async {
    ac.allMessages.clear();
    wsReceives.clear();
    
    print('ws连接: ' + host + ' ' + token);
    if (!host.contains('://')) {
      host = 'ws://' + host;
    }
    Map<String, dynamic> headers = new Map();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer ' + token;
    }
    
    // 旧的 channel 还在时依旧连接的话，会导致重复接收到消息
    if (channel != null && channel.innerWebSocket != null) {
      channel.innerWebSocket.close();
    }
    
    try {
      channel = IOWebSocketChannel.connect(host, headers: headers);
    } catch (e) {
      print('ws连接错误');
      return false;
    }
    
    // 监听消息
    channel.stream.listen((message) {
      if (debugMode) {
        print('ws收到数据:' + message.toString());
        wsReceives.insert(0, message.toString());
      }
      
      processReceivedData(json.decode(message.toString()));
    });
    
    st.setConfig('account/host', host);
    st.setConfig('account/token', token);
    
    return true;
  }
  
  void send(Map<String, dynamic> obj) {
    String text = json.encode(obj);
    print('ws发送数据：' + text);
    channel.sink.add(text);
  }
  
  void processReceivedData(Map<String, dynamic> obj) {
    // 先判断是不是自己主动获取消息的echo
    if (obj.containsKey('echo')) {
      // 解析返回的数据
      parseEchoMessage(obj);
      return;
    }
    
    String postType = obj['post_type'];
    if (postType == 'meta_event') {
      // 心跳，忽略
      String subType = obj['sub_type'];
      if (subType == 'connect') {
        // 第一次连接上
        parseLifecycle(obj);
      }
    } else if (postType == 'message' || postType == 'message_sent') {
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
        parseGroupUpload(obj);
      } else if (noticeType == 'offline_file') {
        // 私聊文件上传
        parseOfflineFile(obj);
      } else {
        print('未处理类型的通知：' + obj.toString());
      }
    } else if (postType == 'message_sent') {
      // 自己发的消息
      parseMessageSent(obj);
    } else {
      print('未处理类型的数据：' + obj.toString());
    }
  }
  
  /// 连接上，必定会触发这个
  void parseLifecycle(final obj) {
    int userId = obj['self_id']; // 自己的QQ号
    ac.qqId = userId;
    ac.connectState = 1;
    
    // 发送获取登录号信息
    send({'action': 'get_login_info', 'echo': 'get_login_info'});
    getFriendList();
    getGroupList();
    ac.eventBus.fire(EventFn(Event.loginSuccess, {}));
  }
  
  void parseEchoMessage(final obj) {
    String echo = obj['echo'];
    if (echo == 'get_login_info') {
      var data = obj['data'];
      ac.qqId = data['user_id'];
      ac.nickname = data['nickname'];
      print('登录账号：' + ac.nickname + "  " + ac.qqId.toString());
      ac.eventBus.fire(
          EventFn(Event.loginInfo, {'qqId': ac.qqId, 'nickname': ac.nickname}));
    } else if (echo == 'get_friend_list') {
      ac.friendNames.clear();
      List data = obj['data']; // 好友数组
      print('好友数量: ' + data.length.toString());
      data.forEach((friend) {
        int userId = friend['user_id'];
        String nickname = friend['nickname'];
        if (friend.containsKey('remark')) nickname = friend['remark'];
        ac.friendNames[userId] = nickname;
      });
      ac.eventBus.fire(EventFn(Event.friendList, {}));
    } else if (echo == 'get_group_list') {
      ac.groupNames.clear();
      List data = obj['data']; // 好友数组
      print('群组数量: ' + data.length.toString());
      data.forEach((friend) {
        int groupId = friend['group_id'];
        String groupName = friend['group_name'];
        ac.groupNames[groupId] = groupName;
      });
      ac.eventBus.fire(EventFn(Event.groupList, {}));
    } else if (echo == 'send_private_msg' || echo == 'send_group_msg') {
      // 发送消息的回复，不做处理
    } else if (echo.startsWith('get_group_member_list')) {
      // TODO: 获取群组，echo字段格式为：get_group_member_list:123456
    } else {
      print('未处理类型的echo: ' + echo);
    }
  }
  
  void parsePrivateMessage(final obj) {
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
        remark: ac.friendNames.containsKey(friendId)
            ? ac.friendNames[friendId]
            : null,
        friendId: friendId,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    
    print('收到私聊消息：' + msg.username() + " : " + message);
    
    notifyOutter(msg);
  }
  
  void parseGroupMessage(final obj) {
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
    
    String groupName = ac.groupNames.containsKey(groupId)
        ? ac.groupNames[groupId]
        : groupId.toString();
    
    print(
        '收到群消息：' + ac.groupNames[groupId] + " - " + nickname + " : " + message);
    
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
        remark: ac.friendNames.containsKey(senderId)
            ? ac.friendNames[senderId]
            : null,
        role: role,
        timestamp: DateTime.now().millisecondsSinceEpoch);
    notifyOutter(msg);
  }
  
  void parseGroupUpload(final obj) {}
  
  void parseOfflineFile(final obj) {}
  
  void parseMessageSent(final obj) {}
  
  void refreshFriend() {}
  
  void refreshGroups() {}
  
  void refreshGroupMembers(int groupId) {}
  
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
  void notifyOutter(MsgBean msg) {
    // 保存所有 msg 记录
    ac.allMessages.add(msg);
    /* if (ac.allMessages.length > st.keepMsgHistoryCount) {
      ac.allMessages.removeAt(0);
    } */
    
    // 保留每个对象的消息记录
    if (msg.isPrivate()) {
      if (!ac.allPrivateMessages.containsKey(msg.friendId)) {
        ac.allPrivateMessages[msg.friendId] = [];
      }
      ac.allPrivateMessages[msg.friendId].add(msg);
      if (ac.allPrivateMessages[msg.friendId].length > st.keepMsgHistoryCount) {
        ac.allPrivateMessages[msg.friendId].removeAt(0);
      }
    } else if (msg.isGroup()) {
      if (!ac.allGroupMessages.containsKey(msg.groupId)) {
        ac.allGroupMessages[msg.groupId] = [];
      }
      ac.allGroupMessages[msg.groupId].add(msg);
      if (ac.allGroupMessages[msg.groupId].length > st.keepMsgHistoryCount) {
        ac.allGroupMessages[msg.groupId].removeAt(0);
      }
    }
    
    // 刷新收到消息的时间（用于简单选择时的排序）
    int time = DateTime.now().millisecondsSinceEpoch;
    if (msg.isPrivate()) {
      ac.privateMessageTimes[msg.friendId] = time;
    } else if (msg.isGroup()) {
      ac.groupMessageTimes[msg.groupId] = time;
      // 判断群组是否通知
      if (!st.enabledGroups.contains(msg.groupId)) {
        return;
      }
    }
    
    // 通知界面
    ac.eventBus.fire(EventFn(Event.messageRaw, msg));
  }
  
  /// 简易版数据展示
  /// 替换所有CQ标签
  String getMessageDisplay(MsgBean msg) {
    String text = msg.message;
    
    text = text.replaceAll(RegExp(r"\[CQ:face,id=(\d+)\]"), '[表情]');
    text = text.replaceAll(RegExp(r"\[CQ:image,type=flash,.+?\]"), '[闪照]');
    text = text.replaceAll(RegExp(r"\[CQ:image,.+?\]"), '[图片]');
    text = text.replaceAll(RegExp(r"\[CQ:reply,.+?\]"), '[回复]');
    text = text.replaceAll(RegExp(r"\[CQ:at,qq=all\]"), '@全体成员');
    text = text.replaceAllMapped(
        RegExp(r"\[CQ:at,qq=(\d+)\]"), (match) => '@${match[1]}');
    text = text.replaceAllMapped(
        RegExp(r'\[CQ:json,data=.+"prompt":"(.+?)".*?\]'),
            (match) => '${match[1]}');
    text = text.replaceAll(RegExp(r"\[CQ:json,.+?\]"), '[JSON]');
    text = text.replaceAll(RegExp(r"\[CQ:video,.+?\]"), '[视频]');
    text = text.replaceAllMapped(
        RegExp(r"\[CQ:([^,]+),.+?\]"), (match) => '@${match[1]}');
    text = text.replaceAll('&#91;', '[').replaceAll('&#93;', ']');
    
    return text;
  }
}