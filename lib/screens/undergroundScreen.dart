import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter/services.dart';

class UndergroundScreen extends StatefulWidget {
  GlobalKey key;
  int faultId;

  UndergroundScreen(this.faultId, this.key);

  @override
  State<UndergroundScreen> createState() => _UndergroundScreen();
}

class _UndergroundScreen extends State<UndergroundScreen> {
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
          'name':
              'Затраты на изучение объекта загрязнения подземных вод, прогноз дальнейшего развития этого процесса и выработку решения по ликвидации загрязнения или компенсации его последствий',
          'shortName': UnderlineIndex('З', 'гр'),
          'rowIndex': 0
        },
        {
          'name':
              'Ущерб подземным водам как полезному ископаемому, использование которого в связи с загрязнением должно быть ограничено или невозможно',
          'shortName': UnderlineIndex('Ущ', '1'),
          'rowIndex': 1
        },
        {
          'name':
              'Убытки, которые несут недропользователи, эксплуатирующие подземные воды, в связи с их загрязнением, включая упущенную выгоду',
          'shortName': UnderlineIndex('Уб', '1'),
          'rowIndex': 2
        },
        {
          'name':
              'Ущерб другим компонентам окружающей природной среды (почва, поверхностные воды суши и морские воды, флора и фауна) в связи с загрязнением подземных вод, затрудняющим или делающим невозможным использование этих компонентов по заданному назначению',
          'shortName': UnderlineIndex('Ущ', '2'),
          'rowIndex': 3
        },
        {
          'name':
              'Убытки природопользователей в связи с ограничением использования других компонентов окружающей природной среды из-за загрязнения подземных вод',
          'shortName': UnderlineIndex('Уб', '2'),
          'rowIndex': 4
        },
        {
          'name':
              'Стоимостное выражение всей совокупности затрат, ущерба подземным водам и другим компонентам окружающей природной среды и убытков, вызванных экологическим правонарушением',
          'shortName': UnderlineIndex('ВР', ''),
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
      0: FlexColumnWidth(10),
      1: FlexColumnWidth(1),
      2: FlexColumnWidth(1),
      3: FlexColumnWidth(2),
      4: FlexColumnWidth(1)

    };

    List<TableRow> tableRows = [];

    rows.forEach((row) {
      TableRow tableRow = TableRow(children: [
        Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Expanded(
                  child: Container(
                      padding: EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        '${row["name"]}',
                        style: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontWeight: row["bold"] == true
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                            color: Theme.of(context).buttonColor),
                      ))),
             
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
         (row["showToolTip"] == true) ?
                MyToolTip(
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).primaryColor, width: 0),
                        color: Theme.of(context).primaryColor,
                      ),

                      height: 35,
                      width: 235,
                      // alignment: Alignment.center,
                      padding: EdgeInsets.all(5),
                      child: Row(
                         crossAxisAlignment: CrossAxisAlignment.baseline,
                        children: [
                          Text('ВР = '),
                          UnderlineIndex('З', 'гр'),
                          Text(' + '),
                          UnderlineIndex('Ущ', '1'),
                          Text(' + '),
                          UnderlineIndex('Уб', '1'),
                          Text(' + '),
                          UnderlineIndex('Ущ', '2'),
                          Text(' + '),
                          UnderlineIndex('Уб', '2'),
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
                padding: EdgeInsets.only(top: 10, bottom: 10, left: 50, right: 30),
                child: Column(children: [
                  Container(
                      alignment: Alignment.topLeft,
                      child: FormTitle(
                          'Расчет вреда, причененного подземным водам')),
                  Text(''),
                  Expanded(
                    child: SingleChildScrollView(
                      child: generateTable(context, _rows),
                    ),
                  ),
                  Container(
                      height: 50,
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
