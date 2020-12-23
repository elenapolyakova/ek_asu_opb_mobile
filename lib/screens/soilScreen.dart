import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter/services.dart';

class SoilScreen extends StatefulWidget {
  GlobalKey key;
  int faultId;

  SoilScreen(this.faultId, this.key);

  @override
  State<SoilScreen> createState() => _SoilScreen();
}

class _SoilScreen extends State<SoilScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  List<Map<String, dynamic>> _rows = [];
  List<double> values = List(6);

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;

          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});

      _rows = [
        {
          'name': 'Размер вреда в результате загрязнения почв',
          'shortName': UnderlineIndex('УЩ', 'загр'),
          'rowIndex': 0
        },
        {
          'name': 'Размер вреда в результате порчи почв при их захламлении',
          'shortName': UnderlineIndex('УЩ', 'отх'),
          'rowIndex': 1
        },
        {
          'name':
              'Размер вреда в результате порчи почв при перекрытии ее поверхности',
          'shortName': UnderlineIndex('УЩ', 'перек'),
          'rowIndex': 2
        },
        {
          'name':
              'Размер вреда в результате порчи почв при снятии плодородного слоя почвы',
          'shortName': UnderlineIndex('УЩ', 'сн'),
          'rowIndex': 3
        },
        {
          'name':
              'Размер вреда в результате уничтожения плодородного слоя почвы',
          'shortName': UnderlineIndex('УЩ', 'уничт'),
          'rowIndex': 4
        },
        {
          'name': 'Общий размер вреда, причиненного почвам',
          'shortName': UnderlineIndex('УЩ', ''),
          'showToolTip': true,
          'readOnly': true,
          'rowIndex': 5,
          'bold': true
        }
      ];
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  Widget generateTable(BuildContext context, List<Map<String, dynamic>> rows) {
    Map<int, TableColumnWidth> columnWidths = {
      0: FlexColumnWidth(8),
      1: FlexColumnWidth(1),
      2: FlexColumnWidth(1),
      3: FlexColumnWidth(2),
      4: FlexColumnWidth(.5)
    };

    List<TableRow> tableRows = [];

    rows.forEach((row) {
      TableRow tableRow = TableRow(children: [
        Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Expanded(
                child: Text(
                  '${row["name"]}',
                  style: TextStyle(
                      fontStyle: FontStyle.normal,
                      fontWeight: row["bold"] == true
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                      color: Theme.of(context).buttonColor),
                ),
              ),
             
            ])),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: row["shortName"] ?? Text(''),
        ),
        Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              (row["rowIndex"] + 1).toString(),
            )),
        EditDigitField(
          text: null,
         // textInPopEdit: row["name"],
          value:
              values[row["rowIndex"]]?.toString()?.replaceAll('.', ',') ?? '',
          onSaved: (value) => {
            setState(() {
              values[row["rowIndex"]] =
                  double.tryParse(value.replaceAll(',', '.'));
            })
          },
           readOnly: row["readOnly"] ?? false,
          context: context,
           backgroundColor: row["readOnly"] == true
              ? Theme.of(context).primaryColorLight
              : null,
          margin: 3,
          borderColor: Theme.of(context).primaryColorDark,
        ),
         (row["showToolTip"] == true) ? 
                MyToolTip(
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).primaryColor, width: 0),
                        color: Theme.of(context).primaryColor,
                      ),
                      height: 30,
                      width: 370,
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        children: [
                          Text('УЩ = '),
                         UnderlineIndex('УЩ', 'загр'),
                          Text('+'),
                          UnderlineIndex('УЩ', 'отх'),
                          Text('+'),
                          UnderlineIndex('УЩ', 'перек'),
                          Text('+'),
                          UnderlineIndex('УЩ', 'сн'),
                          Text('+'),
                          UnderlineIndex('УЩ', 'уничт'),
                        ],
                      ),
                    ),
                    bgColor: Theme.of(context).primaryColor) : Text(''),
      ]);
      tableRows.add(tableRow);
    });

    return Table(
        border: TableBorder.all(color: Colors.transparent),
        columnWidths: columnWidths,
        children: tableRows);
  }

  calc() {
    double harm = 0.0;
    int len = values.length;
    for (var i = 0; i < len - 1; i++) harm += values[i] ?? 0;
    values[len - 1] = harm;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/frameScreen.png"),
                fit: BoxFit.fill)),
        child: showLoading
            ? Text("")
            : Container(
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                child: Column(children: [
                  Container(
                      alignment: Alignment.topLeft,
                      child: FormTitle('Расчет вреда, причененного почвам')),
                  Text(''),
                  Expanded(
                    child: SingleChildScrollView(
                      child: generateTable(context, _rows),
                    ),
                  ),
                  Container(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MyButton(
                              text: 'Расчитать',
                              parentContext: context,
                              onPress: calc),
                          MyButton(
                              text: 'Сохранить',
                              disabled: values[values.length - 1] == null,
                              parentContext: context,
                              onPress: () {}),
                        ],
                      )),
                ])));
  }
}
