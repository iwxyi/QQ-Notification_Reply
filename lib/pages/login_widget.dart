import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';

// ignore: must_be_immutable
class LoginWidget extends StatelessWidget {
  String host = G.st.host;
  String token = G.st.token;

  TextEditingController _hostController;
  TextEditingController _tokenController;

  LoginWidget() {
    _hostController = new TextEditingController(text: host);
    _tokenController = new TextEditingController(text: token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('连接服务器'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 80,
                width: 80,
                margin: EdgeInsets.only(top: 50),
                alignment: Alignment.center,
                child: Image(
                    image: AssetImage("assets/icons/cat_chat.png"),
                    width: 100.0),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 0),
                child: Text(
                  'QQ通知',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 20,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 30,
                ),
                child: TextField(
                  controller: _hostController,
                  decoration: InputDecoration(
                    hintText: 'http://domain:port',
                    labelText: 'host',
                  ),
                  onChanged: (String text) {
                    host = text;
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 30,
                ),
                child: TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    hintText: 'access token (可空)',
                    labelText: 'token',
                  ),
                  onChanged: (String text) {
                    token = text;
                  },
                  obscureText: true,
                ),
              ),
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 30,
                ),
                child: RaisedButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '连接服务器',
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.redAccent,
                  onPressed: () {
                    if (host != null && host.isNotEmpty) {
                      G.cs.connect(host, token).then((value) {
                        if (value) {
                          // 连接成功
                          Navigator.pop(context);
                        } else {
                          // 连接失败
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ));
  }
}
