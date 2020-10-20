import 'dart:convert';
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ek_asu_opb_mobile/loginPage.dart';
import 'package:ek_asu_opb_mobile/homeScreen.dart';
// import 'package:ek_asu_opb_mobile/planCbtEditScreen.dart';

class PlanCbtScreen extends StatefulWidget {
  @override
  State<PlanCbtScreen> createState() => _PlanCbtScreen();
}

class _PlanCbtScreen extends State<PlanCbtScreen> {
  var _userInfo;
  var _predId;
  var test;
  var _headers = [
    {
      'text': 'Наименование проверяемого филиала, территории железной дорог',
      'flex': 3
    },
    {'text': 'Подразделения, подлежащие проверке', 'flex': 2},
    {'text': 'Вид проверки', 'flex': 2},
    {'text': 'Срок проведения  проверки', 'flex': 2},
    {'text': 'Ответственные за организацию и проведение проверки', 'flex': 2},
    {'text': 'Результаты проведенной проверки', 'flex': 2}
  ];

  var _rows = <Inspection>[
    Inspection(
        inspection_id: 1,
        type_id: 1,
        period_id: 1,
        to_be_inspected_name: 'ДЖВ',
        auditor_name: 'ЦБТ - ЦТР, НЦОП - ТР'),
    Inspection(
        inspection_id: 2,
        type_id: 1,
        period_id: 1,
        to_be_inspected_name: 'ТР',
        auditor_name: 'ЦБТ'),
    Inspection(
        inspection_id: 3,
        type_id: 1,
        period_id: 1,
        to_be_inspected_name:
            'Территория Южно-Уральской железной дороги подразделения всех хозяйств' +
                'ОАО «РЖД» и ДЗО (по согласованию)',
        auditor_name: 'ЦБТ'),
  ];

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

  void editInspection(Inspection inspection, BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/planCbtEdit',
        arguments: inspection);
    Inspection newInspection = result as Inspection;
    setState(() => {test = newInspection.auditor_name});
    Scaffold.of(context)
      ..showSnackBar(SnackBar(content: Text('newInspection.auditor_name')));
  }

  List<Widget> generateTableData(BuildContext context,
      List<Map<String, dynamic>> headers, List<dynamic> rows) {
    List<Widget> tableWidget = new List<Widget>();
    tableWidget.add(generateHeaderRow(headers, context));

    List<Widget> rowsWidget = List<Widget>.generate(
        rows.length, (index) => generateRow(rows[index], context));

    tableWidget.addAll(rowsWidget);
    return tableWidget;
  }

  Widget generateHeaderRow(
      List<Map<String, dynamic>> headers, BuildContext context) {
    List<Widget> headerCells = new List<Widget>();
    headers.forEach((header) {
      headerCells.add(new Expanded(
        child: Container(
            height: 56.0,
            child: Text(header["text"], textAlign: TextAlign.center),
            decoration: BoxDecoration(
                border: Border(
                    left: BorderSide(color: Theme.of(context).accentColor)))),
        flex: header["flex"],
      ));
    });

    return new Container(
        child: new Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: headerCells),
        margin: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            border: Border(
                bottom: BorderSide(color: Theme.of(context).accentColor))));
  }

  Widget getRowCell(String text, int flex,
      {TextAlign textAlign = TextAlign.center}) {
    return Expanded(
        child: new Container(
          child: Text(text, textAlign: textAlign),
          padding: EdgeInsets.symmetric(horizontal: 10.0),
        ),
        flex: flex);
  }

  Widget generateRow(Inspection row, BuildContext context) {
    Widget _row = new Container(
        child: new Row(children: [
          getRowCell(row.to_be_inspected_name, _headers[0]["flex"],
              textAlign: TextAlign.left),
          getRowCell(row.to_be_inspected_name, _headers[1]["flex"]),
          getRowCell(row.type_id.toString(), _headers[2]["flex"]),
          getRowCell(row.period_id.toString(), _headers[3]["flex"]),
          getRowCell(row.auditor_name, _headers[4]["flex"]),
          getRowCell(row.auditor_name, _headers[5]["flex"]),
        ]),
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor))));
    return new GestureDetector(
        onTap: () => {editInspection(row, context)},
        child: Dismissible(
            child: _row,
            key: Key(row.inspection_id.toString()),
            background: Container(color: Colors.red),
            onDismissed: (direction) {
              //setState(() {
              //  items.removeAt(index);
              //});
            }));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
          title: new Text("ЕК АСУ ОПБ"),
          leading: new IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Главное окно',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => HomeScreen()));
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
        onPressed: () => editInspection(new Inspection(), context),
        label: Text('Добавить проверку'),
        icon: Icon(Icons.add_circle_outline),
        backgroundColor: Theme.of(context).accentColor,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('test:$test'),
        Column(children: generateTableData(context, _headers, _rows))
      ]),
    );
  }
}
