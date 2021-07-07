import 'package:flutter/cupertino.dart';
import 'package:qqnotificationreply/utils/file_util.dart';

class AppRuntime {
  String dataPath; // 应用数据目录（带斜杠）
  String cachePath; // 缓存路径
  String storagePath; // 外部存储目录（没用）

  AppRuntime({@required this.dataPath, this.cachePath, this.storagePath}) {
    FileUtil.createDir(dataPath);
  }

  String cache(String path) => cachePath + path;
}
