import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qqnotificationreply/pages/accountwidget.dart';

import '../widgets/gallerybar.dart';

const Color _mariner = const Color(0xFF3B5F8F);
const Color _mediumPurple = const Color(0xFF8266D4);
const Color _tomato = const Color(0xFFF95B57);
const Color _mySin = const Color(0xFFF3A646);

List<CardSection> allSections;

class MainPages extends StatefulWidget {
  MainPages() {
    
    allSections = <CardSection>[
      CardSection(
        title: '账号信息',
        leftColor: _mediumPurple,
        rightColor: _mariner,
        contentWidget: AccountWidget(),
      ),
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
  }

  @override
  _MainPagesState createState() => _MainPagesState();
}

class _MainPagesState extends State<MainPages> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimateTabNavigation(
      sectionList: allSections,
    );
  }
}
