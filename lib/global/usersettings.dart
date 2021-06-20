import 'package:flutter/cupertino.dart';
import 'package:qqnotificationreply/utils/mysettings.dart';

class UserSettings extends MySettings {
  String host; // 主机地址
  String token; // 连接秘钥
  
  UserSettings({@required String iniPath}) : super(iniPath: iniPath);
  
  /// 读取配置文件
  @override
  void readFromFile() {
    host = getStr('account/host', '');
    token = getStr('account/token', '');
  }
  
  
}
