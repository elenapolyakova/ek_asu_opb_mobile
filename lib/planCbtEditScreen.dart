import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;


class PlanCbtEditScreen extends StatefulWidget {
  static const routeName = '/planCbtEdit';

  @override
  State<PlanCbtEditScreen> createState() => _PlanCbtEditScreen();
}

class _PlanCbtEditScreen extends State<PlanCbtEditScreen> {

 @override
  void initState() {
    super.initState();
    auth.checkLoginStatus(context).then((isLogin) => {
          if (isLogin)
            {
             
            }
        });
  }

  void LogOut(context) {
    auth.LogOut(context);
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
                  onPressed: () => LogOut(context)),
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
