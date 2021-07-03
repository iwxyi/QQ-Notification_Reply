import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/gallerybar.dart';

const Color _mariner = const Color(0xFF3B5F8F);
const Color _mediumPurple = const Color(0xFF8266D4);
const Color _tomato = const Color(0xFFF95B57);
const Color _mySin = const Color(0xFFF3A646);

List<CardSection> allSections = <CardSection>[
  CardSection(
      title: '账号信息',
      leftColor: _mediumPurple,
      rightColor: _mariner,
      contentWidget: Center(child: Text('Page One'))),
  CardSection(
      title: '通知设置',
      leftColor: _mariner,
      rightColor: _mySin,
      contentWidget: Center(child: Text('Page Two'))),
  CardSection(
      title: '数据记录',
      leftColor: _mySin,
      rightColor: _tomato,
      contentWidget: Center(child: Text('Page Three'))),
  CardSection(
      title: '辅助功能',
      leftColor: _tomato,
      rightColor: Colors.blue,
      contentWidget: Center(child: Text('Page Four'))),
  CardSection(
      title: '关于程序',
      leftColor: Colors.blue,
      rightColor: _mediumPurple,
      contentWidget: Center(child: Text('Page Five'))),
];

class MainPages extends StatefulWidget {
  @override
  _MainPagesState createState() => _MainPagesState();
}

class _MainPagesState extends State<MainPages> {
  Future<Null> initGlobal() async {
    await G.init();
    setState(() {});
  }

  @override
  void initState() {
    initGlobal();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimateTabNavigation(
      sectionList: allSections,
    );
  }
}
