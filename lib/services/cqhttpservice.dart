import 'dart:convert';
import 'package:qqnotificationreply/global/appruntime.dart';
import 'package:qqnotificationreply/global/usersettings.dart';
import 'package:web_socket_channel/io.dart';

/// WebSocket使用说明：https://zhuanlan.zhihu.com/p/133849780
class CqhttpService {
  IOWebSocketChannel channel;
  AppRuntime rt;
  UserSettings st;

  CqhttpService({this.rt, this.st});

  Future<bool> connect(String host, String token) async {
    print('ws.connect: ' + host + ' ' + token);
    Map<String, dynamic> headers = new Map();
    headers['Authorization'] = 'Bearer ' + token;
    channel = IOWebSocketChannel.connect(host, headers: headers);

    // 监听消息
    channel.stream.listen((message) {
      print('ws.message:' + message.toString());
      final Map<String, dynamic> msgJson = json.decode(message.toString());
      // msgJson.text;
    });

    return true;
  }

/*  WebSocket _webSocket;
  Future<bool> link(String host, String token) async {
    if (!host.startsWith('ws://')) {
      host = 'ws://' + host;
    }
    _webSocket = await WebSocket.connect(host);
    _webSocket.listen((data) {
      print('WS收到消息：' + data);
    }, onError: (err) {
      print('WS.Error:' + err);
    }, onDone: () {
      print('WS.onDone');
    });
    return true;
  }*/
}
