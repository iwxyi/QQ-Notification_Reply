import 'dart:convert';
import 'package:qqnotificationreply/global/appruntime.dart';
import 'package:qqnotificationreply/global/useraccount.dart';
import 'package:qqnotificationreply/global/usersettings.dart';
import 'package:web_socket_channel/io.dart';

/// WebSocket使用说明：https://zhuanlan.zhihu.com/p/133849780
class CqhttpService {
  IOWebSocketChannel channel;
  AppRuntime rt;
  UserSettings st;
  UserAccount ac;

  CqhttpService({this.rt, this.st, this.ac});

  Future<bool> connect(String host, String token) async {
    print('ws连接: ' + host + ' ' + token);
    Map<String, dynamic> headers = new Map();
    headers['Authorization'] = 'Bearer ' + token;
    channel = IOWebSocketChannel.connect(host, headers: headers);

    // 监听消息
    channel.stream.listen((message) {
      print('ws收到消息:' + message.toString());
      processReceivedData(json.decode(message.toString()));
    });

    st.setConfig('account/host', host);
    st.setConfig('account/token', token);
    
    return true;
  }

  void send(Map<String, dynamic> obj) {
    channel.sink.add(obj);
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
    } else if (postType == 'message') {
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
  
  void parseLifecycle(final obj) {
    int userId = obj['self_id']; // 自己的QQ号
    ac.qqId = userId;
    ac.connectState = 1;
  }
  
  void parseEchoMessage(final obj) {
  
  }
  
  void parsePrivateMessage(final obj) {
  
  }
  
  void parseGroupMessage(final obj) {
  
  }
  
  void parseGroupUpload(final obj) {
  
  }
  
  void parseOfflineFile(final obj) {
  
  }
  
  void parseMessageSent(final obj) {
  
  }
  
  void refreshFriend() {
  
  }
  
  void refreshGroups() {
  
  }
  
  void refreshGroupMembers(int groupId) {
  
  }
  
  void sendUserMessage(int userId, String message) {
  
  }
  
  void sendGroupMessage(int groupId, String message) {
  
  }
}
