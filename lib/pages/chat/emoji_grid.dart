import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:qqnotificationreply/global/g.dart';
import 'package:qqnotificationreply/widgets/slide_images_page.dart';

class EmojiGrid extends StatefulWidget {
  final sendEmojiCallback;

  const EmojiGrid({Key key, this.sendEmojiCallback}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _EmojiGridState();
}

class _EmojiGridState extends State<EmojiGrid> {
  String searchKey;
  TextEditingController editingController = TextEditingController();

  bool _editing = false;
  List<String> emojiList = []; // 数据源
  bool _searching = false;

  @override
  void initState() {
    emojiList.addAll(G.st.emojiList);
    super.initState();
  }

  Widget _buildGride(BuildContext context) {
    // 尺寸
    final size = MediaQuery.of(context).size;
    final twidth = size.width / 2;
    const int bsize = 48; // 图片边长（正方形）

    return StaggeredGridView.countBuilder(
      crossAxisCount: twidth ~/ bsize, //横轴单元格数量
      itemCount: emojiList.length, //元素数量
      itemBuilder: (context, i) {
        String cq = emojiList[i];
        bool local = false;
        String url;

        Match mat = RegExp(r'\[CQ:face,id=(\d+)\]$').firstMatch(cq);
        if (mat != null) {
          local = true;
          String id = mat[1];
          url = "assets/qq_face/$id.gif";
        }
        if (!local) {
          mat = RegExp(r'url=([^,\]]+)').firstMatch(cq);
          if (mat != null) {
            url = mat[1];
          }
        }
        if (url == null) {
          // 图片搜索结果只有file，没有url
          mat = RegExp(r'file=([^,\]]+)').firstMatch(cq);
          if (mat != null) {
            url = mat[1];
          }
        }
        if (url == null) {
          return Text(cq);
        }
        ImageProvider itemWidget =
            local ? AssetImage(url) : CachedNetworkImageProvider(url);

        Widget imageInk = Ink(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: itemWidget,
              fit: BoxFit.contain,
            ),
          ),
          child: InkWell(
            // child: Hero(tag: url, child: ExtendedImage.network(url)),
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
                if (_searching) {
                  // 放大网络图片
                  Navigator.of(context).push(PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) => new SlidePage(url: url)));
                } else {
                  // 编辑删除本地图片
                  _editing = !_editing;
                }
              });
            },
          ),
        );

        Widget redPoint = Positioned(
          right: 0,
          child: Container(
              clipBehavior: Clip.antiAlias,
              constraints: BoxConstraints(
                  minHeight: 24, maxHeight: 24, minWidth: 24, maxWidth: 24),
              decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              child: IconButton(
                  icon: Icon(Icons.close),
                  color: Colors.white,
                  iconSize: 16,
                  padding: EdgeInsets.all(2),
                  onPressed: () {
                    setState(() {
                      emojiList.removeAt(i);
                      G.st.emojiList.removeAt(i);
                    });
                  })),
        );

        if (_searching) {
          imageInk = Hero(tag: url, child: imageInk);
        }

        return new Card(
          elevation: 8.0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [imageInk, !_editing ? Text('') : redPoint],
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
            controller: editingController,
            decoration: InputDecoration(
              isDense: true,
              hintText: '表情包',
              prefixIcon: Icon(Icons.search),
              suffix: IconButton(
                icon: Icon(Icons.close_sharp),
                onPressed: () {
                  editingController.text = "";
                  searchImage(null);
                },
                padding: EdgeInsets.all(0),
                constraints: BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                color: Theme.of(context).primaryColor,
              ),
            ),
            onChanged: (value) {
              if (searchKey != null &&
                  value != null &&
                  searchKey.startsWith(value)) {
                // 表示是逐字删除
                searchImage(null);
                return;
              }

              String val = "";
              val += value;
              Timer(Duration(milliseconds: 500), () {
                if (val == editingController.text) {
                  searchImage(value);
                }
              });
            },
            onSubmitted: (value) {
              searchImage(value);
            }),
        Expanded(child: _buildGride(context))
      ],
    );
  }

  void searchImage(String key) {
    searchKey = key;
    if (key == null || key.trim().isEmpty) {
      setState(() {
        emojiList.clear();
        emojiList.addAll(G.st.emojiList);
      });
      _searching = false;
      return;
    }

    print('搜索图片：$key');
    String token = "7hF09Osx9p9sltak"; // 改成你自己的
    int page = 1;
    String apiUrl =
        "https://v2.alapi.cn/api/doutu?token=$token&keyword=$key&page=$page&type=7";
    print('搜索图片：' + apiUrl);
    try {
      Dio dio = new Dio();
      Future<Response<String>> response = dio.get<String>(apiUrl);
      response.then((Response<String> value) {
        if (searchKey != searchKey) {
          print('忽略旧的搜索结果');
          return;
        }
        if (value.statusCode != 200) {
          print('获取图片失败：' + key);
          return;
        }

        _searching = true;
        _editing = false;

        var data = json.decode(value.data);
        var list = data['data'];
        if (list == null) {
          return;
        }
        emojiList.clear();
        for (String imgUrl in list) {
          String cq = "[CQ:image,file=$imgUrl]";
          print(cq);
          emojiList.add(cq);
          setState(() {});
        }
      });
    } catch (e) {
      print(e);
    }
  }
}
