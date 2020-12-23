import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';

class ForestScreen extends StatefulWidget {
  GlobalKey key;
  int faultId;

  ForestScreen(this.faultId, this.key);

  @override
  State<ForestScreen> createState() => _ForestScreen();
}

class _ForestScreen extends State<ForestScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  List<Map<String, dynamic>> _rows = [];
  List<double> values = List(5);

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
          'name':
              'Размер вреда, причиненного  вследствие нарушения лесного законодательства лесным насаждениям, заготовка древесины которых допускается',
          'shortName': UnderlineIndex('У', '1'),
          'rowIndex': 0
        },
        {
          'name':
              'Размер вреда, причиненного  вследствие нарушения лесного законодательства лесным насаждениям, заготовка древесины которых не допускается',
          'shortName': UnderlineIndex('У', '2'),
          'rowIndex': 1
        },
        {
          'name':
              'Размер вреда, причиненного лесам вследствие нарушения лесного законодательства, за исключением вреда, причиненного лесным насаждениям',
          'shortName': UnderlineIndex('У', '3'),
          'rowIndex': 2
        },
        {
          'name':
              'Расходы, связанные с осуществлением принятых работ по рекультивации земель, лесовосстановлению (лесоразведению) и понесенные лицом, причинившим вред, до дня вынесения решения суда по гражданскому делу о возмещении вреда вследствие совершения административного правонарушения либо обвинительного приговора в размере, не превышающем размера вреда',
          'shortName': UnderlineIndex('Z', ''),
          'rowIndex': 3
        },
        {
          'name':
              'Суммарный размер вреда, причиненного лесам и находящимся в них объектам вследствие нарушения лесного законодательства',
          'shortName': UnderlineIndex('У', ''),
          'showToolTip': true,
          'readOnly': true,
          'rowIndex': 4,
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
      0: FlexColumnWidth(10),
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

          value:
              values[row["rowIndex"]]?.toString()?.replaceAll('.', ',') ?? '',
          onSaved: (value) => {
            setState(() {
              values[row["rowIndex"]] =
                  double.tryParse(value.replaceAll(',', '.'));
            })
          },
          context: context,

          readOnly: row["readOnly"] ?? false,

          backgroundColor: row["readOnly"] == true
              ? Theme.of(context).primaryColorLight
              : null,
          //height: 30,
          margin: 3,
          borderColor: Theme.of(context).primaryColorDark,
        ),
        (row["showToolTip"] == true)
            ? MyToolTip(
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).primaryColor, width: 0),
                    color: Theme.of(context).primaryColor,
                  ),
                  height: 35,
                  width: 135,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    children: [
                      Text('У = '),
                      UnderlineIndex('У', '1'),
                      Text(' + '),
                      UnderlineIndex('У', '2'),
                      Text(' + '),
                      UnderlineIndex('У', '3'),
                      Text(' - Z')
                    ],
                  ),
                ),
                bgColor: Theme.of(context).primaryColor)
            : Text(''),
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

    for (var i = 0; i < len - 2; i++) harm += values[i] ?? 0;
    harm -= values[len - 2] ?? 0;

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
                padding:
                    EdgeInsets.only(top: 10, bottom: 10, left: 80, right: 50),
                child: Column(children: [
                  Container(
                      alignment: Alignment.topLeft,
                      child: FormTitle(
                          'Расчет вреда, причененного лесам и находящимся в них объектам')),
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
