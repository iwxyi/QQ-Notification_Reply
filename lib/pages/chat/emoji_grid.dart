import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:qqnotificationreply/global/g.dart';

class EmojiGrid extends StatefulWidget {
  final sendEmojiCallback;

  const EmojiGrid({Key key, this.sendEmojiCallback}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EmojiGridState();
}

class _EmojiGridState extends State<EmojiGrid> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final twidth = size.width / 2;
    const int bsize = 64; // 图片边长（正方形）
    return StaggeredGridView.countBuilder(
      crossAxisCount: twidth ~/ bsize, //横轴单元格数量
      itemCount: G.st.emojiList.length, //元素数量
      itemBuilder: (context, i) {
        String cq = G.st.emojiList[i];
        bool local = false;
        String url;

        Match mat = RegExp(r'\[CQ:face,id=(\d+)\]$').firstMatch(cq);
        if (mat != null) {
          local = true;
          String id = mat[1];
          url = "assets/qq_face/$id.gif";
        }
        if (!local) {
          mat = RegExp(r'url=([^,]+)').firstMatch(cq);
          if (mat == null) {
            return Text(cq);
          }
          url = mat[1];
        }
        ImageProvider itemWidget =
            local ? Image.asset(url) : CachedNetworkImageProvider(url);
        return new Card(
          elevation: 8.0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Ink(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: itemWidget,
                    fit: BoxFit.contain,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    if (_editing) {
                      setState(() {
                        _editing = false;
                      });
                      return;
                    }
                    Navigator.pop(context);
                    widget.sendEmojiCallback(cq);
                  },
                  onLongPress: () {
                    setState(() {
                      _editing = !_editing;
                    });
                  },
                ),
              ),
              !_editing
                  ? Text('')
                  : Positioned(
                      right: 0,
                      child: Container(
                          clipBehavior: Clip.antiAlias,
                          constraints: BoxConstraints(
                              minHeight: 32,
                              maxHeight: 32,
                              minWidth: 32,
                              maxWidth: 32),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16))),
                          child: IconButton(
                              icon: Icon(Icons.close),
                              color: Colors.white,
                              iconSize: 16,
                              onPressed: () {
                                setState(() {
                                  G.st.emojiList.removeAt(i);
                                });
                              })),
                    )
            ],
          ),
        );
      },
      staggeredTileBuilder: (index) {
        String cq = G.st.emojiList[index];
        bool isFace = cq.contains('[CQ:face,');
        return StaggeredTile.count(
            isFace ? 1 : 2, isFace ? 1 : 2); //第一个参数是横轴所占的单元数，第二个参数是主轴所占的单元数
      },
      padding: EdgeInsets.all(0),
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
    );
  }
}
