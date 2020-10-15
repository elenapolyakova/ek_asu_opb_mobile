import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/loginPage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'src/fileStorage.dart';
import 'src/db.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;

class HomeScreen extends StatefulWidget {
  final FileStorage storage = new FileStorage('test.txt');
  final DB db = new DB();
  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  var _user_info;
  var _pred_id;
  final storage = FlutterSecureStorage();
  final _sizeTextBlack = const TextStyle(fontSize: 20.0, color: Colors.black);

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  checkLoginStatus() async {
    String value = await storage.read(key: 'auth_token');
    if (value == null) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
          (Route<dynamic> route) => false);
    } else {
      storage.read(key: "user_info").then((user_info) => {
            setState(() {
              _user_info = jsonDecode(user_info);
              _pred_id = _user_info["pred_id"];
            })
          });
    }
  }

  void LogOut() {
    storage.delete(key: 'user_info');
    storage.delete(key: 'auth_token');
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (BuildContext context) => LoginPage()),
        (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
            title: new Text("ЕК АСУ ОПБ"),
            leading: new IconButton(
              icon: const Icon(Icons.home),
              tooltip: 'Главное окно',
              onPressed: () {},
            ),
            actions: <Widget>[
              new IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Рабочая документация',
                  onPressed: () => {}),
              new IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Выход',
                  onPressed: LogOut),
            ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => UrlLauncher.launch("tel://1234567"),
          label: Text('Служба поддержки'),
          icon: Icon(Icons.phone),
          backgroundColor: Theme.of(context).accentColor,
        ),
        body: new Padding(
            padding: new EdgeInsets.only(top: 25.0), child: Text("")));
  }
}
