import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoWidget extends StatefulWidget {
  final url;

  const VideoWidget({Key key, this.url}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController videoPlayerController;
  ChewieController chewieController;
  Chewie playerWidget;

  Future<bool> initVideo() async {
    videoPlayerController = VideoPlayerController.network(widget.url);

    // Windows 上会卡在这一步
    await videoPlayerController.initialize();

    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      looping: true,
    );

    playerWidget = Chewie(
      controller: chewieController,
    );
    setState(() {});
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
      future: initVideo(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.data == null) {
          return Center(
            child: Text("加载中"),
          );
        }
        return playerWidget;
      },
    ));
  }

  @override
  void dispose() {
    if (VideoPlayerController != null) videoPlayerController.dispose();
    if (chewieController != null) chewieController.dispose();
    super.dispose();
  }
}
