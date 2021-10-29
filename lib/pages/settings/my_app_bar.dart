import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget child;

  MyAppBar(this.child);

  @override
  Size get preferredSize => const Size.fromHeight(50);
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        child: child,
      ),
    );
  }
}
