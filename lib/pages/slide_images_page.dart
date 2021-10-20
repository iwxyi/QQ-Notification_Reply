import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_saver/image_picker_saver.dart';
import 'package:qqnotificationreply/widgets/hero.dart';
import 'package:share/share.dart';

class SlideImagePage extends StatefulWidget {
  @override
  _SlideImagePageState createState() => _SlideImagePageState();
}

class _SlideImagePageState extends State<SlideImagePage> {
  List<String> images = <String>[
    'https://photo.tuchong.com/14649482/f/601672690.jpg',
    'https://photo.tuchong.com/17325605/f/641585173.jpg',
    'https://photo.tuchong.com/3541468/f/256561232.jpg',
    'https://photo.tuchong.com/16709139/f/278778447.jpg',
    'This is an video',
    'https://photo.tuchong.com/5040418/f/43305517.jpg',
    'https://photo.tuchong.com/3019649/f/302699092.jpg'
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SlidePage'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (BuildContext context, int index) {
            final String url = images[index];
            return GestureDetector(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Hero(
                  tag: url,
                  child: url == 'This is an video'
                      ? Container(
                          alignment: Alignment.center,
                          child: const Text('This is an video'),
                        )
                      : ExtendedImage.network(
                          url,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return SlidePage(url: url);
                }));
              },
            );
          },
          itemCount: images.length,
        ),
      ),
    );
  }
}

class SlidePage extends StatefulWidget {
  const SlidePage({this.url});
  final String url;
  @override
  _SlidePageState createState() => _SlidePageState();
}

class _SlidePageState extends State<SlidePage> {
  GlobalKey<ExtendedImageSlidePageState> slidePagekey =
      GlobalKey<ExtendedImageSlidePageState>();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // 设置透明好像都不管用？
      child: ExtendedImageSlidePage(
        key: slidePagekey,
        child: GestureDetector(
            child: widget.url == 'This is an video'
                ? ExtendedImageSlidePageHandler(
                    child: Material(
                      child: Container(
                        alignment: Alignment.center,
                        color: Colors.yellow,
                        child: const Text('This is an video'),
                      ),
                    ),

                    ///make hero better when slide out
                    heroBuilderForSlidingPage: (Widget result) {
                      return Hero(
                        tag: widget.url,
                        child: result,
                        flightShuttleBuilder: (BuildContext flightContext,
                            Animation<double> animation,
                            HeroFlightDirection flightDirection,
                            BuildContext fromHeroContext,
                            BuildContext toHeroContext) {
                          final Hero hero =
                              (flightDirection == HeroFlightDirection.pop
                                  ? fromHeroContext.widget
                                  : toHeroContext.widget) as Hero;

                          return hero.child;
                        },
                      );
                    },
                  )
                : HeroWidget(
                    child: ExtendedImage.network(widget.url,
                        enableSlideOutPage: true,
                        loadStateChanged: (ExtendedImageState state) {
                      if (state.extendedImageLoadState ==
                          LoadState.completed) {}
                      return null;
                    }),
                    tag: widget.url,
                    slideType: SlideType.onlyImage,
                    slidePagekey: slidePagekey,
                  ),
            onTap: () {
              slidePagekey.currentState.popPage();
              Navigator.pop(context);
            },
            onLongPress: () {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return new Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        new ListTile(
                          leading: new Icon(Icons.save),
                          title: new Text("保存到本地"),
                          onTap: () async {
                            saveNetworkImageToPhoto(widget.url)
                                .then((String filePath) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('保存到：' + filePath)));
                            });
                            Navigator.pop(context);
                          },
                        ),
                        new ListTile(
                          leading: new Icon(Icons.share),
                          title: new Text("分享"),
                          onTap: () async {
                            saveNetworkImageToPhoto(widget.url)
                                .then((String filePath) {
                              Share.shareFiles([filePath], text: '保存的文件');
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  });
            }),
        slideAxis: SlideAxis.both,
        slideType: SlideType.onlyImage,
      ),
    );
  }

  ///save network image to photo
  Future<String> saveNetworkImageToPhoto(String url,
      {bool useCache: true}) async {
    var data = await getNetworkImageData(url, useCache: useCache);
    var filePath = await ImagePickerSaver.saveFile(fileData: data);
    // return filePath != null && filePath != "";
    return filePath;
  }
}
