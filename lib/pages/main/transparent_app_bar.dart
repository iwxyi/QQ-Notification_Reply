import 'package:flutter/material.dart';

class TransparentAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget child;

  TransparentAppBar(this.child, Key key) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<StatefulWidget> createState() => _TransparentAppBarState();
}

class _TransparentAppBarState extends State<TransparentAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      /* flexibleSpace: Container( // 整个区域，包括leading等
        child: widget.child,
      ), */
      title: widget.child,
      leading: Builder(builder: (BuildContext context) {
        // 自定义Drawer按钮
        return IconButton(
          icon: Icon(Icons.menu,
              color: Theme.of(context).textTheme.bodyText2.color),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        );
      }),
    );
  }
}
