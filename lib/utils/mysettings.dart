import 'package:flutter/material.dart';
import 'package:ini/ini.dart';

import 'file_util.dart';

class MySettings {
  Config config;
  String iniPath;

  MySettings({@required this.iniPath}) {
    if (FileUtil.isFileExists(iniPath)) {
      String content = FileUtil.readText(iniPath);
      config = Config.fromString(content);
    } else {
      config = new Config();
    }

    readFromFile();
  }

  void readFromFile() {}

  /// 保存设置到文件
  void setConfig(String key, value) {
    if (key.contains('/')) {
      int pos = key.indexOf('/');
      String name = key.substring(0, pos);
      String option = key.substring(pos + 1);
      if (!config.hasSection(name)) {
        config.addSection(name);
      }
      /*if (value is int) {
		        value = value.toString();
		      } else if (value is bool) {
		        value = value ? 'true' : 'false';
		      } else if (value is Color) {
		        value = value.toString();
		      }*/
      config.set(name, option, value.toString());
    } else {
      config.set('', key, value);
    }
    FileUtil.writeText(iniPath, config.toString());
  }

  bool getBool(String key, bool def) {
    var s = getConfig(key, def);
    if (s is String)
      return !(s == '0' || s == '' || s.toLowerCase() == 'false');
    return s;
  }

  int getInt(String key, int def) {
    var s = getConfig(key, def);
    if (s is String) return int.parse(s);
    return s;
  }

  String getStr(String key, String def) {
    var s = getConfig(key, def);
    return s.toString();
  }

  /// 读取设置，不存在则为空
  dynamic getValue(String key) {
    if (key.contains('/')) {
      int pos = key.indexOf('/');
      String name = key.substring(0, pos);
      String option = key.substring(pos + 1);
      return config.get(name, option);
    } else {
      return config.get('', key);
    }
  }

  /// 读取设置，不存在则返回默认值
  dynamic getConfig(String key, def) {
    if (key.contains('/')) {
      int pos = key.indexOf('/');
      String name = key.substring(0, pos);
      String option = key.substring(pos + 1);
      if (config.hasOption(name, option)) {
        return config.get(name, option);
      } else {
        return def;
      }
    } else {
      if (config.hasOption('', key)) {
        return config.get('', key);
      } else {
        return def;
      }
    }
  }
}
