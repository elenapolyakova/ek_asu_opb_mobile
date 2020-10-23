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
  String _data;

  @override
  void initState() {
    super.initState();

    widget.storage.readData().then((String data) {
      setState(() {
        _data = data;
      });
    });
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
          onPressed: () => {},
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
            ])));
  }
}
