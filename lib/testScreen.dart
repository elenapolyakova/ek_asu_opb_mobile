import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/loginPage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'src/fileStorage.dart';
import 'src/db.dart';
import 'models/dog.dart';

class HomeScreen extends StatefulWidget {
  final FileStorage storage = new FileStorage('test.txt');
  final DB db = new DB();
  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  String _email;
  String _password;
  var _user_info;
  var _pred_id;
  String _data;
  final storage = FlutterSecureStorage();
  final _sizeTextBlack = const TextStyle(fontSize: 20.0, color: Colors.black);

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    widget.storage.readData().then((String data) {
      setState(() {
        _data = data;
      });
    });
  }

  checkLoginStatus() async {
    String value = await storage.read(key: 'auth_token');
    if (value == null) {
      /* Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );*/
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

  Future<File> writeFile() {
    widget.storage.readData().then((String data) {
      setState(() {
        _data = data + '28.09.2017';
      });
      return widget.storage.writeData('28.09.2017');
    });
  }

  testDB() async {

    var fido = Dog(
      id: 3,
      name: 'Fid1o',
      age: 135,
    );
    await widget.db.insertDog(fido);
    print(await widget.db.dogs());
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("ЕК АСУ ОПБ"),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: LogOut,
          label: Text('Выход'),
          icon: Icon(Icons.logout),
          backgroundColor: Theme.of(context).accentColor,
        ),
        body: new Padding(
            padding: new EdgeInsets.only(top: 25.0),
            child: new Row(children: <Widget>[
              new MaterialButton(
                  onPressed: writeFile,
                  color: Theme.of(context).accentColor,
                  height: 50.0,
                  minWidth: 150.0,
                  child: new Text("Записать в файл")),
              new MaterialButton(
                  onPressed: testDB,
                  color: Theme.of(context).accentColor,
                  height: 50.0,
                  minWidth: 150.0,
                  child: new Text("testDB")),
              new Text('data:$_data')
            ])));
  }
}
