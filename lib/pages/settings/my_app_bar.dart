import 'package:flutter/material.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget child;

  MyAppBar(this.child, Key key) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  State<StatefulWidget> createState() => _MyAppBarState();
}

class _MyAppBarState extends State<MyAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        child: widget.child,
      ),
    );
  }
}
