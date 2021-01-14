import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/controllers/fault.dart';
import 'package:ek_asu_opb_mobile/models/fault.dart';
import 'package:ek_asu_opb_mobile/models/koap.dart';
import 'package:ek_asu_opb_mobile/screens/faultScreen.dart';
import 'package:ek_asu_opb_mobile/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';

class MyFault {
  Fault fault;
  String fineName;
  DateTime fixDate;
  MyFault(this.fault, this.fineName, this.fixDate);
}

class FaultListScreen extends StatefulWidget {
  int checkListItemId;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;
  String checkListItemName;
  int departmentId;
  int checkPlanItemId;
  GlobalKey key;

  @override
  FaultListScreen(
      {this.checkListItemId,
      this.push,
      this.pop,
      this.key,
      this.checkListItemName,
      this.departmentId,
      this.checkPlanItemId});
  @override
  State<FaultListScreen> createState() => _FaultListScreen();
}

class _FaultListScreen extends State<FaultListScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  var _tapPosition;
  int checkListItemId;
  int checkPlanItemId;

  bool isHistory =
      false; //форма загружена из истории нарушений или вопроса чек-листа
  bool allFaultByDepartment = false; //все нарушения предприятия или проверки

  int departmentId;
  List<MyFault> _items;
  final formFaultKey = new GlobalKey<FormState>();

  List<Map<String, dynamic>> faultListHeader = [
    {'text': 'Описание нарушения', 'flex': 5},
    {'text': 'Плановая дата устранения', 'flex': 2},
    {'text': 'Факт. дата устранения', 'flex': 2},
    {'text': 'Штраф в денежном выражении, руб.', 'flex': 3},
    {'text': 'Размер вреда, руб.', 'flex': 2},
    {'text': 'Описание штрафа', 'flex': 6},
    {'text': 'Статья КОАП', 'flex': 2},
  ];

  List<Map<String, dynamic>> choices = [
    {'title': 'Удалить нарушение', 'icon': Icons.delete, 'key': 'delete'},
    {'title': 'Редактировать нарушение', 'icon': Icons.edit, 'key': 'edit'},
    {
      'title': 'Перейти к устранению',
      'icon': Icons.assignment_turned_in,
      'key': 'fix'
    },
    {
      'title': 'Перейти к расчету вреда',
      'icon': Icons.calculate,
      'key': 'damage'
    }
  ];

  Future<String> getFineName(int koapId) async {
    if (koapId == null) return null;
    Koap koap = await KoapController.selectById(koapId);
    return koap != null ? await koap.fineName : '';
  }

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          checkListItemId = widget.checkListItemId;
          if (checkListItemId != null) {
            isHistory = false;
          } else {
            isHistory = true;
          }
          checkPlanItemId = widget.checkPlanItemId;
          departmentId = widget.departmentId;
          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});
      await loadFaultItems();
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  String getTitle() {
    if (isHistory == false) return widget.checkListItemName;

    if (allFaultByDepartment) return 'Список всех нарушений предприятия';

    return 'Список всех нарушений проверки';
  }

  Future<void> loadFaultItems() async {
    _items = [];
    List<Fault> items = [];
    if (checkListItemId != null)
      items = await FaultController.select(checkListItemId);
    else if (departmentId != null) if (allFaultByDepartment)
      items = await FaultController.getFaultsByDepartment(departmentId);
    else
      items = await FaultController.getFaultsByCheckPlanId(checkPlanItemId);

    if (items != null)
      for (int i = 0; i < items.length; i++) {
        String fineName = await getFineName(items[i].koap_id);
        DateTime fixDate = await items[i].getLastFixDate;
        _items.add(MyFault(items[i], fineName, fixDate));
      }
  }

  List<Widget> generateFaultTable(BuildContext context,
      List<Map<String, dynamic>> headers, List<MyFault> rows) {
    int i = 0;
    Map<int, int> columnWidths = Map.fromIterable(headers,
        key: (item) => i++,
        value: (item) => int.parse(item['flex'].toString()));

    List<Widget> result = [];

    Widget headerTableRow = Container(
        color: Theme.of(context).primaryColor,
        child: IntrinsicHeight(
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                    headers.length,
                    (index) => Expanded(
                        flex: columnWidths[index],
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                                right: BorderSide(
                                  color: Colors.black,
                                ),
                                top: BorderSide(
                                  color: Colors.black,
                                ),
                                bottom: BorderSide(
                                  color: Colors.black,
                                ),
                                left: BorderSide(
                                    style: index == 0
                                        ? BorderStyle.solid
                                        : BorderStyle.none,
                                    color: Colors.black)),
                          ),
                          child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Text(
                                headers[index]["text"],
                                softWrap: true,
                                textAlign: TextAlign.center,
                              )),
                        ))))));

    result.add(headerTableRow);

    int rowIndex = 0;
    rows.forEach((fault) {
      Fault row = fault.fault;
      rowIndex++;
      Widget tableRow = Container(
          color: (rowIndex % 2 == 0
              ? Theme.of(context).shadowColor
              : Colors.white),
          child: IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                getRowCell(row.desc, row.id, 0, flex: columnWidths[0]),
                getRowCell(dateDMY(row.plan_fix_date), row.id, 1,
                    textAlign: TextAlign.center, flex: columnWidths[1]),
                getRowCell(dateDMY(fault.fixDate), row.id, 2,
                    textAlign: TextAlign.center, flex: columnWidths[2]),
                getRowCell(
                    row.fine != null ? row.fine.toString() : '', row.id, 3,
                    textAlign: TextAlign.center, flex: columnWidths[3]),
                getRowCell(
                    row.damageAmount != null
                        ? row.damageAmount.toString().replaceAll('.', ',')
                        : '',
                    row.id,
                    4,
                    textAlign: TextAlign.center,
                    flex: columnWidths[4]),
                getRowCell(row.fine_desc, row.id, 5, flex: columnWidths[5]),
                getRowCell(fault.fineName, row.id, 6, flex: columnWidths[6]),
              ])));
      result.add(tableRow);
    });

    return result;
  }

  Widget getRowCell(String text, int faultId, int index,
      {TextAlign textAlign = TextAlign.left, int flex = 1}) {
    Widget cell = Container(
        decoration: BoxDecoration(
          border: Border(
              right: BorderSide(
                color: Colors.black,
              ),
              bottom: BorderSide(
                color: Colors.black,
              ),
              left: BorderSide(
                  style: index == 0 ? BorderStyle.solid : BorderStyle.none,
                  color: Colors.black)),
        ),
        child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              text ?? "",
              textAlign: textAlign,
            )));

    return Expanded(
        flex: flex,
        child: GestureDetector(
            onTapDown: _storePosition,
            onLongPress: () {
              _showCustomMenu(faultId, index);
            },
            child: cell));
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showCustomMenu(int faultId, int index) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
        context: context,
        position: RelativeRect.fromRect(
            _tapPosition & const Size(1, 1), Offset.zero & overlay.size),
        items: <PopupMenuEntry<Map<String, dynamic>>>[
          CustomPopMenu(
            context: context,
            choices: choices,
            color: null, //isItem ? Theme.of(context).primaryColorDark : null,
            fontColor:
                null, //isItem ? Theme.of(context).primaryColorLight : null,
          )
        ]).then<void>((Map<String, dynamic> choice) {
      if (choice == null) return;
      switch (choice["key"]) {
        case 'edit':
          editFaultClicked(faultId);
          break;
        case 'delete':
          deleteFaultClicked(faultId);
          break;
        case 'fix':
          fixFaultClicked(faultId);
          break;
        case 'damage':
          faultDamageClicked(faultId);
          break;
      }
    });
  }

  List<PopupMenuItem<String>> getMenuFaultList(BuildContext context) {
    List<PopupMenuItem<String>> result = [];
    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.add,
            text: "Добавить нарушение",
            margin: 5.0,
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'addFault'),
    );
    return result;
  }

  Future<void> deleteFaultClicked(int faultId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить нарушение?', context);
    if (result != null && result) {
      MyFault deletedFault = _items
          .firstWhere((fault) => fault.fault.id == faultId, orElse: () => null);

      if (deletedFault == null) return;

      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        result = await FaultController.delete(faultId);
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          if (context != null)
            Scaffold.of(context).showSnackBar(
                errorSnackBar(text: 'Произошла ошибка при удалении'));
          return;
        }
        _items.remove(deletedFault);
        setState(() {});
      } catch (e) {
        if (context != null)
          Scaffold.of(context).showSnackBar(
              errorSnackBar(text: 'Произошла ошибка при удалении'));
      }
    }
  }

  Future<void> toggleFault() async {
    showLoadingDialog(context);

    setState(() {
      allFaultByDepartment = !allFaultByDepartment;
    });
    await loadFaultItems();
    setState(() {});
    hideDialog(context);
  }

  Future<void> addFaultClicked(StateSetter setState) async {
    return widget.push({
      "pathTo": 'fault',
      "pathFrom": 'faultList',
      'text': 'Назад к нарушениям'
    }, {
      'faultId': -1
    });
  }

  Future<void> editFaultClicked(int faultId) async {
    return widget.push({
      "pathTo": 'fault',
      "pathFrom": 'faultList',
      'text': 'Назад к нарушениям'
    }, {
      'faultId': faultId
    });
  }

  Future<void> faultDamageClicked(int faultId) async {
    return widget.push({
      "pathTo": 'faultDamage',
      "pathFrom": 'faultList',
      'text': 'Назад к нарушениям'
    }, {
      'faultId': faultId
    });
  }

  Future<void> fixFaultClicked(int faultId) async {
    return widget.push({
      "pathTo": 'faultFixList',
      "pathFrom": 'faultList',
      'text': 'Назад к нарушениям'
    }, {
      'faultId': faultId
    });
  }

  @override
  Widget build(BuildContext context) {
    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenuFaultList(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'addFault':
            addFaultClicked(setState);
            break;
        }
      },
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).primaryColorDark,
        size: 30,
      ),
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0))),
    );

    return showLoading
        ? Text("")
        : (isHistory == false)
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 5),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(
                      child: ListTile(
                          trailing: menu,
                          contentPadding: EdgeInsets.all(0),
                          title: FormTitle(getTitle() ?? ''),
                          onTap: () {}),
                    ),
                  ]),
                  Expanded(
                      child: ListView(
                          padding: EdgeInsets.only(
                            top: 10,
                          ),
                          children: [
                        Column(
                            children: generateFaultTable(
                                context, faultListHeader, _items))
                      ]))
                ]))
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 5),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextIcon(
                            iconSize: 45,
                            icon: allFaultByDepartment
                                ? Icons.toggle_on
                                : Icons.toggle_off,
                            text: 'Все нарушения по предприятию',
                            onTap: toggleFault,
                            color: allFaultByDepartment
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          )
                        ],
                      ),
                      FormTitle(getTitle() ?? ''),
                      Expanded(
                          child: ListView(
                              padding: EdgeInsets.only(
                                top: 10,
                              ),
                              children: [
                            Column(
                                children: generateFaultTable(
                                    context, faultListHeader, _items))
                          ]))
                    ]));
  }
}
