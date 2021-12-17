import 'package:flutter/material.dart';

// ignore: must_be_immutable
class UserProfileWidget extends StatelessWidget {
  final json;

  // 陌生人也会有的
  int userId;
  String nickname;
  String sex; // male/demale/unknow
  int age;
  String qid;
  int level;
  int loginDays;

  // 群成员信息
  String area; // 地区
  int joinTime;
  int lastSentTime;
  String role; // owner/admin/member
  bool unfriendly; // 是否不良记录成员
  String title; // 专属头衔
  bool cardChangeable; // 是否允许修改群名片
  int shutUpTimestamp; // 禁言到期时间

  UserProfileWidget({Key key, this.json}) : super(key: key) {
    // 解析JSON
    userId = json['user_id'];
    nickname = json['nickname'];
    sex = json['sex'];
    age = json['age'];
    qid = json['qid'];
    level = json['level'];
    loginDays = json['login_days'];
  }

  @override
  Widget build(BuildContext context) {
    return Text(nickname);
  }
}
