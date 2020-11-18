import 'package:ek_asu_opb_mobile/screens/commissionScreen.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';

List<Map<String, dynamic>> statusSelection = [
  {
    'id': 1,
    'name': 'Не рассматривался',
    'value': STATUS.template,
    'color': Colors.grey.shade200
  },
  {
    'id': 2,
    'name': 'Пройдено без замечаний',
    'value': STATUS.success,
    'color': Colors.green.shade200
  },
  {
    'id': 3,
    'name': 'Есть нарушения',
    'value': STATUS.fault,
    'color': Colors.red.shade200
  }
];

getStatusById(int id) {
  Map<String, dynamic> statusItem = statusSelection
      .firstWhere((status) => status['id'] == id, orElse: () => null);
  if (statusItem != null) return statusItem["value"];
  return null;
}

getColorByStatus(STATUS status) {
  Map<String, dynamic> statusItem = statusSelection
      .firstWhere((item) => item['value'] == status, orElse: () => null);
  if (statusItem != null) return statusItem["color"];
  return Colors.grey.shade200;
}

enum STATUS { template, success, fault }

/////////////////////////////////////////////////
/////MODELS
/////////////////////////////////////////////////
class CheckList {
  int id;
  int odooId;
  int parentId; //CheckPlanItem.id; //для рабочих чек-листов
  bool is_base; //является ли шаблоном
  int type; //вода/воздух/отходы
  String name; //наименование
  bool active;
  int base_id; //базовая запись - CheckList.id, id шаблона для рабочего чек-листа
  List<CheckListItem> items; //вопросы
  STATUS
      status; //вычислять на основе статуса пунктов + is_base //1: 'Не рассматривался',
  //  2: 'Пройдено без замечаний',
  //  3: 'Есть нарушения'

  CheckList(
      {this.id,
      this.odooId,
      this.is_base,
      this.type,
      this.name,
      this.active,
      this.items,
      this.status,
      this.base_id});

  ///Варианты типов чек-листов
  static Map<int, String> typeSelection = {1: 'Воздух', 2: 'Вода', 3: 'Отходы'};
}

class CheckListItem {
  int id;
  int odooId;
  int parentId; //checkLIst.id
  String name; //Наименование
  String question; //Вопрос
  String result; //Результат
  String description; //Комментарий
  STATUS status; //добавить в одоо
  List<Fault> faultItems;
  int base_id; //базовая запись ?? зачем
  bool active;
  CheckListItem(
      {this.id,
      this.odooId,
      this.parentId,
      this.name,
      this.question,
      this.result,
      this.description,
      this.faultItems,
      this.status,
      this.base_id,
      this.active});
}

class Fault {
  int id;
  int odooId;
  int parentId; //checkListItem.id
  String name; //Наименование
  String desc; //Описание
  DateTime date; //Дата фиксации
  String fine_desc; //Штраф. Описание
  int fine; //Штраф. Сумма
  int koap_id;
  Fault(
      {this.id,
      this.odooId,
      this.parentId,
      this.name,
      this.desc,
      this.date,
      this.fine,
      this.fine_desc,
      this.koap_id}); //Статья КОАП
}

/////////////////////////////////////////////////
/////MODELS
/////////////////////////////////////////////////

class CheckListScreen extends StatefulWidget {
  @override
  State<CheckListScreen> createState() => _CheckListScreen();
}

class _CheckListScreen extends State<CheckListScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  List<Map<String, Object>> typeCheckListList;
  List<Map<String, Object>> typeCheckListListAll;
  int _selectedType = 0;
  List<CheckList> _items;
  CheckList _currentCheckList;
  CheckListItem _currentCheckListItem;
  var _tapPosition;
  double heightCheckList = 700;
  double widthCheckList = 1200;
  final formFaultKey = new GlobalKey<FormState>();
  final formCheckListKey = new GlobalKey<FormState>();

  List<Map<String, dynamic>> choices = [
    {'title': "Перейти к чек-листу", 'icon': Icons.forward, 'key': 'edit'},
  ];
  List<Map<String, dynamic>> choicesItem = [
    {'title': 'Удалить запись', 'icon': Icons.delete, 'key': 'deleteItem'},
  ];

  List<Map<String, dynamic>> itemHeader = [
    {'text': 'Наименование', 'flex': 3.0},
    {'text': 'Вопрос', 'flex': 10.0},
    {'text': 'Пройден', 'flex': 1.0, 'fontSize': 12.0},
    {'text': 'Наруше-\nния', 'flex': 1.0, 'fontSize': 12.0},
  ];

  List<CheckList> items = [
    CheckList(
        id: 1,
        odooId: 1,
        is_base: true,
        name: 'Чек-лист 1',
        type: 1,
        active: true,
        status: getStatusById(2),
        items: [
          CheckListItem(
              id: 1,
              odooId: 1,
              parentId: 1,
              name: 'пункт 1',
              status: getStatusById(2),
              question: 'вопрос 1\nдлинный вопрос\nочень длинный'),
          CheckListItem(
              id: 2,
              odooId: 2,
              parentId: 1,
              name: 'пункт 2',
              status: getStatusById(3),
              question: 'вопрос 2',
              faultItems: [Fault(), Fault()])
        ]),
    CheckList(
        id: 2,
        odooId: 2,
        is_base: true,
        name: 'Чек-лист 2',
        type: 1,
        status: getStatusById(1),
        active: true,
        items: []),
    CheckList(
        id: 3,
        odooId: 3,
        is_base: true,
        name: 'Чек-лист 3',
        type: 1,
        status: getStatusById(3),
        active: true,
        items: [])
  ];

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
      typeCheckListList = makeListFromJson(CheckList.typeSelection);
      typeCheckListListAll = makeListFromJson(CheckList.typeSelection);
      typeCheckListListAll.insert(0, {'id': 0, 'value': 'Все'});
      reloadCheckList();
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  Future<void> reloadCheckList() async {
    _items = items;
    //загружать из базы с учетом is_base = true; type = _selectedType || _selectedType = 0 //все
  }

  Future<void> editCheckList(int checkListId) async {
    CheckList checkList =
        _items.firstWhere((checkList) => checkList.id == checkListId);

    setState(() {
      _currentCheckList = new CheckList(
          odooId: checkList.odooId,
          id: checkList.id,
          name: checkList.name,
          is_base: true,
          type: checkList.type,
          active: checkList.active);

      _currentCheckList.items = [];
      checkList.items.forEach((item) {
        CheckListItem itemCopy = CheckListItem(
            id: item.id,
            odooId: item.odooId,
            parentId: item.parentId,
            name: item.name,
            question: item.question,
            result: item.result,
            description: item.description,
            status: item.status,
            base_id: item.base_id,
            active: item.active,
            faultItems: []);
        if (item.faultItems != null)
          item.faultItems.forEach((faultItem) {
            itemCopy.faultItems.add(Fault(
              id: faultItem.id,
              odooId: faultItem.odooId,
              parentId: faultItem.parentId,
              name: faultItem.name,
              desc: faultItem.desc,
              date: faultItem.date,
              fine_desc: faultItem.fine_desc,
              fine: faultItem.fine,
            ));
          });
        _currentCheckList.items.add(itemCopy);
      });
    });
    bool result = await showCheckListDialog(setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<void> deleteCheckList(int checkListId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить чек-лист?', context);
    if (result != null && result) {
      CheckList deletedCheckList = _items.firstWhere(
          (checkList) => checkList.id == checkListId,
          orElse: () => null);

      if (deletedCheckList == null) return;

      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        //  result = await ComGroupController.delete(groupId);
        //  hasErorr = result["code"] < 0;

        if (hasErorr) {
          Scaffold.of(context).showSnackBar(
              errorSnackBar(text: 'Произошла ошибка при удалении'));
          return;
        }
        items.remove(deletedCheckList);
        setState(() {});
      } catch (e) {
        Scaffold.of(context)
            .showSnackBar(errorSnackBar(text: 'Произошла ошибка при удалении'));
      }
    }
  }

  // Future<void> editCheckListItem(int checkListItemId, int parentId) async {}
  Future<void> deleteCheckListItem(
      int rowIndex, StateSetter dialogSetter) async {
    setState(() {
      _currentCheckList.items.removeAt(rowIndex);
    });
    dialogSetter(() {});
  }

  Future<bool> showCheckListDialog(StateSetter setState) {
    StateSetter dialogSetter;
    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenuItem(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'add':
            setState(() {
              _currentCheckList.items.add(CheckListItem(
                  id: null,
                  odooId: null,
                  parentId: _currentCheckList.id,
                  status: null));
              dialogSetter(() {});
              //refresh = true;
            });
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

    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            dialogSetter = setState;
            return Stack(alignment: Alignment.center,
            key: Key('checkListItem'),
                // key: Key(
                //     'checkList${_currentCheckList.items != null ? _currentCheckList.items.length : '0'}'),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/images/app.jpg",
                      fit: BoxFit.fill,
                      height: heightCheckList,
                      width: widthCheckList,
                    ),
                  ),
                  Container(
                      width: widthCheckList,
                      padding: EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 20.0),
                      child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Form(
                              key: formCheckListKey,
                              child: Container(
                                  child: Column(children: [
                                ListTile(
                                    trailing: menu,
                                    contentPadding: EdgeInsets.all(0),
                                    title: Center(
                                        child:
                                            FormTitle(_currentCheckList.name)),
                                    onTap: () {}),
                                //   Container(child: refresh ? Text('') : Text('')),

                                Expanded(
                                    child: ListView(
                                        key: Key(_currentCheckList.items.length
                                            .toString()),
                                        children: [
                                      Column(children: [
                                        generateItemTable(context, itemHeader,
                                            _currentCheckList.items,
                                            dialogSetter: dialogSetter
                                            // setState: setState
                                            )
                                      ])
                                    ])),
                                Container(
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                      MyButton(
                                          text: 'принять',
                                          parentContext: context,
                                          onPress: () {
                                            submitCheckList();
                                          }),
                                      MyButton(
                                          text: 'отменить',
                                          parentContext: context,
                                          onPress: () {
                                            cancelCheckList();
                                          }),
                                    ])),
                              ])))))
                ]);
          });
        });
  }

  Future<bool> showFaultDialog(StateSetter setState) {
    StateSetter dialogSetter;
    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenuItem(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'add':
            setState(() {
              if (_currentCheckListItem.faultItems == null)
                _currentCheckListItem.faultItems = [];
              _currentCheckListItem.faultItems.add(Fault(
                  id: null, odooId: null, parentId: _currentCheckListItem.id));
              dialogSetter(() {});
              //refresh = true;
            });
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

    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            dialogSetter = setState;
            return Stack(alignment: Alignment.center,
                 key: Key('FaultList'),

                //     'checkList${_currentCheckList.items != null ? _currentCheckList.items.length : '0'}'),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/images/app.jpg",
                      fit: BoxFit.fill,
                      height: heightCheckList,
                      width: widthCheckList,
                    ),
                  ),
                  Container(
                      width: widthCheckList,
                      padding: EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 20.0),
                      child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Form(
                              key: formFaultKey,
                              child: Container(
                                  child: Column(children: [
                                ListTile(
                                    trailing: menu,
                                    contentPadding: EdgeInsets.all(0),
                                    title: Center(
                                        child: FormTitle(
                                            'Перечень нарушений к ${_currentCheckListItem.name} ${_currentCheckListItem.question}')),
                                    onTap: () {}),
                                //   Container(child: refresh ? Text('') : Text('')),

                                Expanded(
                                    child: ListView(
                                        key: Key(_currentCheckList.items.length
                                            .toString()),
                                        children: [
                                      Column(children: [
                                        generateFualtTable(
                                            context,
                                            /*itemHeader,*/
                                            _currentCheckListItem.faultItems,
                                            dialogSetter: dialogSetter
                                            // setState: setState
                                            )
                                      ])
                                    ])),
                                Container(
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                      MyButton(
                                          text: 'принять',
                                          parentContext: context,
                                          onPress: () {
                                            submitFaultList();
                                          }),
                                      MyButton(
                                          text: 'отменить',
                                          parentContext: context,
                                          onPress: () {
                                            cancelCheckList();
                                          }),
                                    ])),
                              ])))))
                ]);
          });
        });
  }

  Widget generateFualtTable(
      BuildContext context,
      /*List<Map<String, dynamic>> headers,*/ List<Fault> rows,
      {/*StateSetter setState,*/ StateSetter dialogSetter}) {
    return Text('Тут будет список нарушений');
  }

  Future<void> submitFaultList() async {
    Navigator.pop<bool>(context, true);
    Scaffold.of(context).showSnackBar(successSnackBar);
  }

  Future<void> submitCheckList() async {
    bool hasErorr = false;
    Map<String, dynamic> result;

    try {
      if (_currentCheckList.id == null) {
        // result = await ComGroupController.insert(data['comGroup'], data['ids']);
      } else {
        // result = await ComGroupController.update(data['comGroup'], data['ids']);
      }
      // hasErorr =  result["code"] < 0;

      if (hasErorr) {
        Navigator.pop<bool>(context, false);
        Scaffold.of(context).showSnackBar(errorSnackBar());
      } else {
        if (_currentCheckList.id == null) {
          _currentCheckList.id = 1000; //result["id"];
          setState(() {
            _items.add(_currentCheckList);
          });
        } else {
          setState(() {
            int index =
                _items.indexWhere((item) => item.id == _currentCheckList.id);
            _items[index] = _currentCheckList;
          });
        }

        Navigator.pop<bool>(context, true);
        Scaffold.of(context).showSnackBar(successSnackBar);
      }
    } catch (e) {
      Navigator.pop<bool>(context, false);
      Scaffold.of(context).showSnackBar(errorSnackBar());
    }
  }

  Future<void> cancelCheckList() async {
    Navigator.pop<bool>(context, null);
  }

  List<PopupMenuItem<String>> getMenuItem(BuildContext context) {
    List<PopupMenuItem<String>> result = [];
    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.add,
            text: "Добавить запись",
            margin: 5.0,
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'add'),
    );
    return result;
  }

  Widget generateItemTable(BuildContext context,
      List<Map<String, dynamic>> headers, List<CheckListItem> rows,
      {/*StateSetter setState,*/ StateSetter dialogSetter}) {
    int i = 0;
    Map<int, TableColumnWidth> columnWidths = Map.fromIterable(headers,
        key: (item) => i++,
        value: (item) =>
            FlexColumnWidth(double.parse(item['flex'].toString())));

    TableRow headerTableRow = TableRow(
        decoration: BoxDecoration(color: Theme.of(context).primaryColorDark),
        children: List.generate(
            headers.length,
            (index) => Column(
                  children: [
                    Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text(
                          headers[index]["text"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: headers[index]["fontSize"] ?? 16.0,
                              color: Theme.of(context).primaryColorLight),
                        )),
                  ],
                )));
    List<TableRow> tableRows = [headerTableRow];
    int rowIndex = 0;

    rows.forEach((row) {
      Color color = getColorByStatus(row.status);
      bool hasFault =
          row.faultItems != null ? row.faultItems.length > 0 : false;
      if (hasFault) row.status = STATUS.fault;
      TableRow tableRow =
          TableRow(decoration: BoxDecoration(color: color), children: [
        getRowCellItem(row.name, row.id, 0,
            isItem: true,
            color: color,
            dialogSetter: dialogSetter,
            rowIndex: rowIndex, onSaved: (value) {
          row.name = value;
          //  _currentCheckList.items[rowIndex].name = value;
          setState(() {});
          dialogSetter(() {});
        }),
        getRowCellItem(row.question, row.id, 0,
            isItem: true,
            color: color,
            dialogSetter: dialogSetter, onSaved: (value) {
          row.question = value;
          //  _currentCheckList.items[rowIndex].name = value;
          setState(() {});
          dialogSetter(() {});
        }),
        getCheckCellItem(
            row.status, row.faultItems != null ? row.faultItems.length : 0,
            (value) {
          row.status = value == true
              ? STATUS.success
              : STATUS.fault; //value == false ? STATUS.fault : STATUS.template;
          setState(() {});
          dialogSetter(() {});
        }),
        getFaultCellItem(
            row.status, row.faultItems != null ? row.faultItems.length : 0,
            () async {
          setState(() {
            _currentCheckListItem = row;
          });
          bool result = await showFaultDialog(setState);
          if (result != null && result) {
            setState(() {});
          }
        })
      ]);
      tableRows.add(tableRow);
      rowIndex++;
    });

    return Table(
        border: TableBorder.all(),
        columnWidths: columnWidths,
        children: tableRows);
  }

  Widget generateTableData(BuildContext context, List<CheckList> rows) {
    List<TableRow> tableRows = [];
    int rowIndex = 0;
    rows.forEach((row) {
      rowIndex++;
      Color color = getColorByStatus(row.status);
      TableRow tableRow =
          TableRow(decoration: BoxDecoration(color: color), children: [
        getRowCell(row.name, row.id, 0),
      ]);
      tableRows.add(tableRow);
    });

    return Table(
      border: TableBorder.all(),
      children: tableRows,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    );
  }

  Widget getRowCellItem(String text, int checkListId, int index,
      {TextAlign textAlign = TextAlign.left,
      bool isItem: false,
      Color color,
      Function(String) onSaved,
      int rowIndex,
      StateSetter dialogSetter}) {
    return Container(
        child: EditTextField(
      text: null,
      value: text,
      onSaved: onSaved,
      context: context,
      margin: 0,
      maxLines: null,
      height: null,
      backgroundColor: color ??
          ((rowIndex != null && rowIndex % 2 == 1)
              ? Theme.of(context).shadowColor
              : Colors.white),
      onTapDown: _storePosition,
      onLongPress: () {
        _showCustomMenu(checkListId, index,
            isItem: isItem, rowIndex: rowIndex, dialogSetter: dialogSetter);
      },
    ));
  }

  Widget getCheckCellItem(
      STATUS status, int faultCount, Function(bool) onChanged) {
    return Container(
        // child: SizedBox(
        //height: 24,
        // width: 24,
        child: Checkbox(
      tristate: true,
      value: status == STATUS.success
          ? true
          : (status == STATUS.fault ? false : null),
      onChanged: (_value) {
        bool value = _value;
        if (faultCount > 0) _value = false;
        return onChanged(_value);
      },
      checkColor: Theme.of(context).primaryColor,
      //)
    ));
  }

  Widget getFaultCellItem(STATUS status, int faultCount, Function() onTap) {
    if (status == STATUS.success && faultCount == 0)
      return Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Center(child: Text('нет')));
    return GestureDetector(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(faultCount != null ? faultCount.toString() : '0'),
          Icon(
            Icons.more_vert,
            color: Theme.of(context).primaryColorDark,
            size: 30,
          ),
        ]),
        onTap: onTap);
  }

  Widget getRowCell(String text, int checkListId, int index,
      {TextAlign textAlign = TextAlign.left}) {
    return GestureDetector(
        onTapDown: _storePosition,
        onLongPress: () {
          _showCustomMenu(checkListId, index, isItem: false);
        },
        child: Container(
            padding: EdgeInsets.all(10.0),
            child: Text(
              text ?? '',
              textAlign: textAlign,
            )));
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showCustomMenu(int id, int index,
      {bool isItem = false, int rowIndex, StateSetter dialogSetter}) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
        context: context,
        position: RelativeRect.fromRect(
            _tapPosition & const Size(1, 1), Offset.zero & overlay.size),
        items: <PopupMenuEntry<Map<String, dynamic>>>[
          CustomPopMenu(
            context: context,
            choices: isItem ? choicesItem : choices,
            color: null, //isItem ? Theme.of(context).primaryColorDark : null,
            fontColor:
                null, //isItem ? Theme.of(context).primaryColorLight : null,
          )
        ]).then<void>((Map<String, dynamic> choice) {
      if (choice == null) return;
      switch (choice["key"]) {
        case 'edit':
          editCheckList(id);
          break;
        case 'delete':
          deleteCheckList(id);
          break;
        case 'editItem':
          //  editCheckListItem(id, parentId);
          break;
        case 'deleteItem':
          deleteCheckListItem(rowIndex, dialogSetter);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/frameScreen.png"),
                    fit: BoxFit.fitWidth)),
            child: showLoading
                ? Text("")
                : Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 150),
                    child: Column(children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                child: Center(
                                    child: FormTitle("Перечень чек-листов:")),
                                flex: 2),
                            Expanded(
                                child: MyDropdown(
                                  text: 'Тип',
                                  width: double.infinity,
                                  dropdownValue: _selectedType.toString(),
                                  items: typeCheckListListAll,
                                  onChange: (value) {
                                    setState(() {
                                      _selectedType = int.parse(value);
                                      reloadCheckList();
                                    });
                                  },
                                  parentContext: context,
                                ),
                                flex: 1)
                          ]),
                      Expanded(
                          child: ListView(
                              padding: EdgeInsets.only(
                                top: 16,
                              ),
                              children: [
                            Column(
                                children: [generateTableData(context, _items)])
                          ])),
                      /*Container(
                      child: MyButton(
                          text: 'test',
                          parentContext: context,
                          onPress: testClicked))*/
                    ]))));
  }
}
