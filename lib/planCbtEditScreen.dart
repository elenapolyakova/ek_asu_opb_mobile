import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/loginPage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ek_asu_opb_mobile/planCbtScreen.dart';
import 'package:ek_asu_opb_mobile/models/models.dart';
//import 'package:ek_asu_opb_mobile/models/inspection.dart';

class PlanCbtEditScreen extends StatefulWidget {
  static const routeName = '/planCbtEdit';

  @override
  State<PlanCbtEditScreen> createState() => _PlanCbtEditScreen();
}

class _PlanCbtEditScreen extends State<PlanCbtEditScreen> {
  var _userInfo;
  var _predId;

  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  checkLoginStatus() async {
    String value = await storage.read(key: 'auth_token');
    if (value == null) {
      LogOut();
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

  @override
  Widget build(BuildContext context) {
    final Inspection _inspection = ModalRoute.of(context).settings.arguments;
    Inspection newInspection = new Inspection(
        inspection_id: _inspection.inspection_id,
        auditor_name: 'newInspection');

    return new Scaffold(
        appBar: new AppBar(
            title: new Text("ЕК АСУ ОПБ"),
            leading: new IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Главное окно',
              onPressed: () {
                Navigator.pop(context, _inspection);
              },
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
          onPressed: () => {Navigator.pop(context, newInspection)},
          label: Text('Сохранить'),
          icon: Icon(Icons.save_outlined),
          backgroundColor: Colors.green,
        ),
        body: new Text(_inspection.inspection_id.toString()));
  }
}
