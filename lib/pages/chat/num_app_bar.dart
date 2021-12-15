import 'package:flutter/material.dart';

class NumAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget child;

  NumAppBar(this.child, Key key) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<StatefulWidget> createState() => _NumAppBarState();
}

class _NumAppBarState extends State<NumAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        // 整个区域，包括leading等
        child: widget.child,
      ),
      title: widget.child,
    );
  }
}
