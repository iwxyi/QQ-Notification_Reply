import 'package:flutter/cupertino.dart';
import 'package:qqnotificationreply/utils/mysettings.dart';

class UserSettings extends MySettings {
  static int Unimportant = -1; // ignore: non_constant_identifier_names
  static int NormalImportant = 0; // ignore: non_constant_identifier_names
  static int LittleImportant = 1; // ignore: non_constant_identifier_names
  static int VeryImportant = 2; // ignore: non_constant_identifier_names

  String host; // 主机地址
  String token; // 连接秘钥

  List<int> enabledGroups = []; // 开启通知的群组
  Map<int, int> friendImportance = {}; // 好友的重要性
  Map<int, int> groupImportance = {}; // 群组的重要性

  UserSettings({@required String iniPath}) : super(iniPath: iniPath) {
    // readFromFile(); // super会调用读取，原来这是虚继承
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
    setConfig('notification/enabledGroup', text);
  }

  /// 读取配置文件
  @override
  void readFromFile() {
    host = getStr('account/host', '');
    token = getStr('account/token', '');

    // 读取重要的数组
    String ens = getStr('notification/enabledGroup', '');
    if (ens.isNotEmpty) {
      List<String> sl = ens.split(';');
      sl.forEach((idString) {
        try {
          enabledGroups.add(int.parse(idString));
        } catch (e) {}
      });
    }
  }
}
