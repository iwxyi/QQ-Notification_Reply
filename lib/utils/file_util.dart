import 'dart:io';

import 'package:flutter/services.dart';

class FileUtil {
  static createDir(String path) {
    var dir = Directory(path);
    if (dir.existsSync()) return;
    dir.createSync(recursive: true);
  }

  static deleteDir(String path) {
    var dir = Directory(path);
    if (!dir.existsSync()) return;
    dir.deleteSync();
  }

  static renameDir(String oldPath, String newName, {bool override = false}) {
    var oldDir = Directory(oldPath);
    if (!oldDir.existsSync()) return;

    var directory = new Directory(oldPath);
    String pDir = directory.parent.path;
    if (!pDir.endsWith('/')) pDir += '/';

    var newDir = Directory(pDir + newName);
    if (newDir.existsSync()) {
      if (!override) return;
      newDir.deleteSync();
    }

    directory.renameSync(pDir + newName);
  }

  static moveDir(String oldPath, String newPath, {bool override = false}) {
    var oldDir = Directory(oldPath);
    if (!oldDir.existsSync()) return;
    var newDir = Directory(newPath);
    if (newDir.existsSync()) {
      if (!override) return;
      newDir.deleteSync();
    }

    var directory = new Directory(oldPath);
    directory.renameSync(newPath);
  }

  static copyDir(String oldPath, String newPath, {bool override = false}) {
    var oldDir = Directory(oldPath);
    if (!oldDir.existsSync()) return;
    var newDir = Directory(newPath);
    if (newDir.existsSync()) {
      if (!override) return;
      newDir.deleteSync();
    }

    var directory = new Directory(oldPath);
    // TODO: 递归复制文件
  }

  static bool isDirExists(String path) {
    return Directory(path).existsSync();
  }

  static bool isDirNotExists(String path) {
    return !isDirExists(path);
  }

  // ------------------------------------------------------------

  static createFile(String path) {
    var file = File(path);
    if (file.existsSync()) return;
    file.createSync(recursive: true);
  }

  static renameFile(String oldPath, String newName, {bool override = false}) {
    var oldFile = File(oldPath);
    if (!oldFile.existsSync()) return;

    var file = new File(oldPath);
    var d = file.parent.path;
    if (!d.endsWith('/')) d += '/';

    var newFile = File(d + newName);
    if (newFile.existsSync()) {
      if (!override) return;
      newFile.deleteSync();
    }
    file.renameSync(d + newName);
  }

  static moveFile(String oldPath, String newPath, {bool override = false}) {
    var oldFile = File(oldPath);
    if (!oldFile.existsSync()) return;
    var newFile = File(newPath);
    if (newFile.existsSync()) {
      if (!override) return;
      newFile.deleteSync();
    }
    return oldFile.renameSync(newPath);
  }

  static copyFile(String oldPath, String newPath, {bool override = false}) {
    var oldFile = File(oldPath);
    if (!oldFile.existsSync()) return;
    var newFile = File(newPath);
    if (newFile.existsSync()) {
      if (!override) return;
      newFile.deleteSync();
    }
    return oldFile.copySync(newPath);
  }

  static deleteFile(String path) {
    var file = new File(path);
    if (!file.existsSync()) return;
    File(path).deleteSync();
  }

  static bool isFileExists(String path) {
    return File(path).existsSync();
  }

  static bool isFileNotExist(String path) {
    return !isFileExists(path);
  }

  // -------------------------------------------------------------

  /// 保存纯文本文件
  /// 如果文件不存在，自动创建
  static writeText(String path, String content) {
    File(path).writeAsStringSync(content);
  }

  /// 读取纯文本文件
  /// 如果文件不存在，返回空文本
  static String readText(String path) {
    var file = File(path);
    if (!file.existsSync()) return "";
    return file.readAsStringSync();
  }

  /// 读取资产文件
  /// 只有异步的。。。
  /// Future.sync 完全无效！！！
  static Future<String> loadAsset(String path) {
//    return Future.sync(() => rootBundle.loadString(path));
    return rootBundle.loadString(path);
  }

  /// 贼鸡儿操蛋，怎么阻塞async啊！！！
  static String readAsset(String path) {
    Future.sync(() => rootBundle.loadString(path)).then((value) => print('111111'));
    return '';
  }

  // -------------------------------------------------------------

  static List<String> entityDirPaths(String path) {
    var pDir = Directory(path);
    List<String> files = [];
    if (!pDir.existsSync()) return files;
    List<FileSystemEntity> entityList =
        pDir.listSync(recursive: false, followLinks: false);
    for (FileSystemEntity entity in entityList) {
      if (FileSystemEntity.isFileSync(entity.path)) continue;
      files.add(entity.path);
    }
    return files;
  }

  static List<String> entityDirNames(String path) {
    var pDir = Directory(path);
    List<String> files = [];
    if (!pDir.existsSync()) return files;
    List<FileSystemEntity> entityList =
        pDir.listSync(recursive: false, followLinks: false);
    for (FileSystemEntity entity in entityList) {
      if (FileSystemEntity.isFileSync(entity.path)) continue;
      var fullPath = entity.path;
      var xie = fullPath.lastIndexOf('/');
      if (xie == -1)
        files.add(fullPath);
      else
        files.add(fullPath.substring(xie + 1, fullPath.length));
    }
    return files;
  }

  static List<String> entityFilePaths(String path) {
    var pDir = Directory(path);
    List<String> files = [];
    if (!pDir.existsSync()) return files;
    List<FileSystemEntity> entityList =
        pDir.listSync(recursive: false, followLinks: false);
    for (FileSystemEntity entity in entityList) {
      if (!FileSystemEntity.isFileSync(entity.path)) continue;
      files.add(entity.path);
    }
    return files;
  }

  static List<String> entityFileNames(String path) {
    var pDir = Directory(path);
    List<String> files = [];
    if (!pDir.existsSync()) return files;
    List<FileSystemEntity> entityList =
        pDir.listSync(recursive: false, followLinks: false);
    for (FileSystemEntity entity in entityList) {
      if (!FileSystemEntity.isFileSync(entity.path)) continue;
      var fullPath = entity.path;
      var xie = fullPath.lastIndexOf('/');
      if (xie == -1)
        files.add(fullPath);
      else
        files.add(fullPath.substring(xie + 1, fullPath.length));
    }
    return files;
  }
}
