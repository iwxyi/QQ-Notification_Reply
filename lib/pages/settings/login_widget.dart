import 'package:flutter/material.dart';
import 'package:qqnotificationreply/global/g.dart';

// ignore: must_be_immutable
class LoginWidget extends StatelessWidget {
  String host = G.st.host;
  String token = G.st.token;
  String server = G.st.server;

  TextEditingController _hostController;
  TextEditingController _tokenController;
  TextEditingController _serverController;

  LoginWidget() {
    _hostController = new TextEditingController(text: host);
    _tokenController = new TextEditingController(text: token);
    _serverController = new TextEditingController(text: server);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('连接服务器'),
          centerTitle: true,
        ),
        body: Center(
            child: Container(
          constraints: BoxConstraints(maxHeight: 480, maxWidth: 400),
          child: Card(
            margin: EdgeInsets.all(24),
            child: ListView(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 48, bottom: 24),
                  alignment: Alignment.center,
                  child: Image(
                      // 头像
                      image: AssetImage("assets/icons/cat_chat.png"),
                      width: 100.0),
                  constraints: BoxConstraints(maxHeight: 80, maxWidth: 80),
                ),
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 30,
                  ),
                  child: TextField(
                    controller: _hostController,
                    decoration: InputDecoration(
                      hintText: 'ws://domain:port',
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
                  margin: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 30,
                  ),
                  child: TextField(
                    controller: _serverController,
                    decoration: InputDecoration(
                      hintText: '后台服务地址 (可空)',
                      labelText: 'server',
                    ),
                    onChanged: (String text) {
                      server = text;
                    },
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
                    child: Container(
                      margin: EdgeInsets.all(12),
                      child: Text(
                        '连接服务器',
                        style: TextStyle(color: Colors.white),
                      ),
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
                        G.st.server = server;
                        G.st.setConfig('account/server', server);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        )));
  }
}
