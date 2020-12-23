import 'package:ek_asu_opb_mobile/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:flutter_icons/flutter_icons.dart';

class FaultDamageScreen extends StatefulWidget {
  int faultId;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;
  GlobalKey key;

  @override
  FaultDamageScreen(this.faultId, this.push, this.pop, this.key);

  @override
  State<FaultDamageScreen> createState() => _FaultDamageScreen();
}

class _FaultDamageScreen extends State<FaultDamageScreen> {
  bool isSyncData = false;
  UserInfo _userInfo;
  bool showLoading = true;

  Map<String, dynamic> screenList = {};

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
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  Widget generateFaultFixTable(BuildContext context,
      List<Map<String, dynamic>> headers, List<FaultFix> rows) {
    int i = 0;
    Map<int, TableColumnWidth> columnWidths = Map.fromIterable(headers,
        key: (item) => i++,
        value: (item) =>
            FlexColumnWidth(double.parse(item['flex'].toString())));

    TableRow headerTableRow = TableRow(
        decoration: BoxDecoration(color: Theme.of(context).primaryColor),
        children: List.generate(
            headers.length,
            (index) => Column(
                  children: [
                    Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text(
                          headers[index]["text"],
                          textAlign: TextAlign.center,
                        )),
                  ],
                )));
    List<TableRow> tableRows = [headerTableRow];
    int rowIndex = 0;
    rows.forEach((row) {
      rowIndex++;
      TableRow tableRow = TableRow(
          decoration: BoxDecoration(
              color: (rowIndex % 2 == 0
                  ? Theme.of(context).shadowColor
                  : Colors.white)),
          children: [
            getRowCell(dateDMY(row.date), row.id, 0,
                textAlign: TextAlign.center),
            getRowCell(row.desc, row.id, 1),
            getRowCell((row.is_finished == true).toString(), row.id, 2,
                textAlign: TextAlign.center),
          ]);
      tableRows.add(tableRow);
    });

    return Table(
        border: TableBorder.all(),
        columnWidths: columnWidths,
        children: tableRows);
  }

  Widget getRowCell(String text, int faultFixId, int index,
      {TextAlign textAlign = TextAlign.left}) {
    Widget cell = Container(
      padding: EdgeInsets.all(index != 2 ? 10.0 : 0.0),
      child: (index != 2)
          ? Text(
              text ?? '',
              textAlign: textAlign,
            )
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              MyCheckbox(text == 'true', '', (val) {},
                  color: Theme.of(context).primaryColorLight)
            ]),
    );

    return cell;
  }

  Widget getTabContent(Map<String, dynamic> tab) {
    String key = tab["key"];
    if (!isSyncData) if (screenList[key] != null) return screenList[key];
    switch (key) {
      case 'soil': 
        screenList[key] = SoilScreen(widget.faultId, GlobalKey());
        break;
       case 'water': 
        screenList[key] = WaterScreen(widget.faultId, GlobalKey());
        break;
       case 'forest': 
        screenList[key] = ForestScreen(widget.faultId, GlobalKey());
        break;
       case 'underground': 
        screenList[key] = UndergroundScreen(widget.faultId, GlobalKey());
        break;

      default:
        return Text("");
    }
    return screenList[key] ?? Text("");
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'name': 'Почва', "icon": Icons.grass, 'key': 'soil'},
      {'name': 'Водные объекты', "icon": Icons.waves, 'key': 'water'},
      {'name': 'Лесные объекты', "icon": MaterialCommunityIcons.pine_tree, 'key': 'forest'},
      {
        'name': 'Подземные воды',
        "icon": Icons.opacity,
        'key': 'underground'
      },
    ];

    return showLoading
        ? Text("")
        : DefaultTabController(
            length: tabs.length,
            child: Scaffold(
              appBar: AppBar(
                toolbarHeight: 50,
                title: null,
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).primaryColor,
                bottom: TabBar(
                  labelColor: Theme.of(context).primaryColorDark,
                  indicatorColor: Theme.of(context).primaryColorDark,
                  isScrollable: true,
                  tabs: [
                    for (final tab in tabs)
                      Tab(
                        child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 50),
                            child: Row(children: <Widget>[
                              Icon(
                                tab["icon"],
                                size: 30,
                              ),
                              Container(
                                  margin: EdgeInsets.only(left: 10),
                                  child: Text(
                                    tab["name"],
                                    style: TextStyle(fontSize: 16),
                                  ))
                            ])),
                      ),
                  ],
                ),
              ),
              body: TabBarView(
                children: tabs.map((tab) => getTabContent(tab)).toList()
               ,
              ),
            ),
          );
  }
}
