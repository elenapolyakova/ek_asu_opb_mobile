import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/loginPage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'src/fileStorage.dart';
import 'src/db.dart';
import 'models/dog.dart';
import 'utils/config.dart' as config;

class TestScreen extends StatefulWidget {
  final FileStorage storage = new FileStorage('test.txt');

  @override
  State<TestScreen> createState() => _TestScreen();
}

class _TestScreen extends State<TestScreen> {
  String _email;
  String _password;
  var _userInfo;
  var _predId;
  String _data;
  String _baseUrl;
  final storage = FlutterSecureStorage();
  final _sizeTextBlack = const TextStyle(fontSize: 20.0, color: Colors.black);

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
   
    widget.storage.readData().then((String data) {
      setState(() {
        _data = data;
        _baseUrl = config.getItem("ServiceRootUrl");
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
      storage.read(key: "user_info").then((userInfo) => {
            setState(() {
              _userInfo = jsonDecode(userInfo);
              _predId = _userInfo["pred_id"];
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
        _data = data + 'test';
      });
      return widget.storage.writeData('test');
    });
  }

  testDB() async {
    var fido = Dog(
      id: 3,
      name: 'Fido',
      age: 15,
    );
    await DBProvider.db.insertDog(fido);
    print(await DBProvider.db.dogs());
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
              new Text('data:$_data'),
              new Text('baseUrl:$_baseUrl'),
            ])));
  }
}
