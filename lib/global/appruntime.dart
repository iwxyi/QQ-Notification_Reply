import 'package:flutter/cupertino.dart';

class AppRuntime {
  String dataPath; // 应用数据目录（带斜杠）
  String cachePath; // 缓存路径
  String storagePath; // 外部存储目录（没用）

  AppRuntime({@required this.dataPath, this.cachePath, this.storagePath});

  String cache(String path) => cachePath + path;
}
