/*import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:ek_asu_opb_mobile/screens/checkListScreen.dart';
import 'package:ek_asu_opb_mobile/screens/checkListItemScreen.dart';
import 'package:ek_asu_opb_mobile/screens/faultScreen.dart';

class MyCheckListTemplate {
  int id;
  int odooId;
  int parentIdcheck; //PlanItemId; //для рабочих чек-листов
  bool is_base;
  int type;
  String name;
  bool active;
  List<MyCheckListItem> items;
  MyCheckListTemplate(
      {this.id,
      this.odooId,
      this.is_base,
      this.type,
      this.name,
      this.active,
      this.items});

  ///Варианты типов чек-листов
  static Map<int, String> typeSelection = {1: 'Воздух', 2: 'Вода', 3: 'Отходы'};
}

class MyCheckListItem {
  int id;
  int odooId;
  int parentId;
  String name;
  String question;
  String result;
  String description;
  bool active;
  MyCheckListItem(
      {this.id,
      this.odooId,
      this.parentId,
      this.name,
      this.question,
      this.result,
      this.description,
      this.active});
}

class CheckListTemplateScreen extends StatefulWidget {
  @override
  State<CheckListTemplateScreen> createState() => _CheckListTemplateScreen();
}

class _CheckListTemplateScreen extends State<CheckListTemplateScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  List<Map<String, Object>> typeCheckListList;
  List<Map<String, Object>> typeCheckListListAll;
  int _selectedType = 0;
  List<MyCheckListTemplate> _items;
  MyCheckListTemplate _currentCheckList;
  var _tapPosition;
  double heightCheckList = 700;
  double widthCheckList = 1000;
  final formKey = new GlobalKey<FormState>();

  List<Map<String, dynamic>> choices = [
    {'title': "Редактировать чек-лист", 'icon': Icons.edit, 'key': 'edit'},
    {'title': 'Удалить чек-лист', 'icon': Icons.delete, 'key': 'delete'},
  ];
  List<Map<String, dynamic>> choicesItem = [
    {'title': 'Удалить запись', 'icon': Icons.delete, 'key': 'deleteItem'},
  ];

  List<Map<String, dynamic>> itemHeader = [
    {'text': 'Наименование', 'flex': 1.0},
    {'text': 'Вопрос', 'flex': 3.0},
  ];

  List<MyCheckListTemplate> items = [
    MyCheckListTemplate(
        id: 1,
        odooId: 1,
        is_base: true,
        name: 'Чек-лист 1',
        type: 1,
        active: true,
        items: [
          MyCheckListItem(
              id: 1,
              odooId: 1,
              parentId: 1,
              name: 'пункт 1',
              question: 'вопрос 1\nдлинный вопрос\nочень длинный'),
          MyCheckListItem(
              id: 2,
              odooId: 2,
              parentId: 1,
              name: 'пункт 2',
              question: 'вопрос 2')
        ]),
    MyCheckListTemplate(
        id: 2,
        odooId: 2,
        is_base: true,
        name: 'Чек-лист 2',
        type: 1,
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
      typeCheckListList = makeListFromJson(MyCheckListTemplate.typeSelection);
      typeCheckListListAll = makeListFromJson(MyCheckListTemplate.typeSelection);
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

  Future<void> addCheckListClicked() async {
    setState(() {
      _currentCheckList = new MyCheckListTemplate(
          id: null,
          odooId: null,
          name: null,
          is_base: true,
          active: true,
          items: [],
          type: null);
    });
    bool result = await showCheckListDialog(setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<void> editCheckList(int checkListId) async {
    MyCheckListTemplate checkList =
        _items.firstWhere((checkList) => checkList.id == checkListId);

    setState(() {
      _currentCheckList = new MyCheckListTemplate(
          odooId: checkList.odooId,
          id: checkList.id,
          name: checkList.name,
          is_base: true,
          type: checkList.type,
          active: checkList.active);

      _currentCheckList.items = [];
      checkList.items.forEach((item) {
        MyCheckListItem itemCopy = MyCheckListItem(
            id: item.id,
            odooId: item.odooId,
            parentId: item.parentId,
            name: item.name,
            question: item.question,
            active: item.active);
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
      MyCheckListTemplate deletedCheckList = _items.firstWhere(
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
              _currentCheckList.items.add(MyCheckListItem(
                  id: null, odooId: null, parentId: _currentCheckList.id));
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
        barrierDismissible: true,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            dialogSetter = setState;
            return Stack(alignment: Alignment.center,
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
                      margin:
                          EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 20.0),
                      child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Form(
                              key: formKey,
                              child: Container(
                                  child: Column(children: [
                                FormTitle(
                                    '${_currentCheckList.id == null ? 'Добавление' : 'Редактирование'} шаблона чек-листа'),
                                //   Container(child: refresh ? Text('') : Text('')),
                                Container(
                                    child: Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                          trailing: menu,
                                          contentPadding: EdgeInsets.all(0),
                                          title: EditTextField(
                                            text: 'Наименование чек-листа',
                                            value: _currentCheckList.name,
                                            onSaved: (value) => {
                                              _currentCheckList.name = value
                                            },
                                            context: context,
                                          ),
                                          onTap: () {}),
                                      flex: 5,
                                    ),
                                    Expanded(
                                      child: PopupMenuItem<String>(
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 5.0),
                                            child: MyDropdown(
                                              text: 'Тип',
                                              width: double.infinity,
                                              dropdownValue:
                                                  _currentCheckList.type != null
                                                      ? _currentCheckList.type
                                                          .toString()
                                                      : null,
                                              items: typeCheckListList,
                                              onChange: (value) {
                                                setState(() {
                                                  _currentCheckList.type =
                                                      int.parse(value);
                                                });
                                              },
                                              parentContext: context,
                                            ),
                                          ),
                                          value: 'type'),
                                      flex: 2,
                                    )
                                  ],
                                )),
                                Expanded(
                                    child: ListView(
                                        key: Key(_currentCheckList.items.length
                                            .toString()),
                                        padding: EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 50),
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

  List<PopupMenuItem<String>> getMenu(BuildContext context) {
    List<PopupMenuItem<String>> result = [];
    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.add,
            text: "Добавить чек-лист",
            margin: 5.0,
            /* onTap: () ,*/
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'add'),
    );
    result.add(
      PopupMenuItem<String>(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 17.0),
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
          ),
          value: 'type'),
    );

    return result;
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
      List<Map<String, dynamic>> headers, List<MyCheckListItem> rows,
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
                              color: Theme.of(context).primaryColorLight),
                        )),
                  ],
                )));
    List<TableRow> tableRows = [headerTableRow];
    int rowIndex = 0;

    rows.forEach((row) {
      TableRow tableRow = TableRow(
          decoration: BoxDecoration(
              color: (rowIndex % 2 == 0
                  ? Colors.white
                  : Theme.of(context).shadowColor)),
          children: [
            getRowCellItem(row.name, row.id, 0,
                isItem: true,
                dialogSetter: dialogSetter,
                rowIndex: rowIndex, onSaved: (value) {
              row.name = value;
              //  _currentCheckList.items[rowIndex].name = value;
              setState(() {});
              dialogSetter(() {});
            }),
            getRowCellItem(row.question, row.id, 0,
                isItem: true,
                rowIndex: rowIndex,
                dialogSetter: dialogSetter, onSaved: (value) {
              row.question = value;
              //  _currentCheckList.items[rowIndex].name = value;
              setState(() {});
              dialogSetter(() {});
            }),
          ]);
      tableRows.add(tableRow);
      rowIndex++;
    });

    return Table(
        border: TableBorder.all(),
        columnWidths: columnWidths,
        children: tableRows);
  }

  Widget generateTableData(BuildContext context, List<MyCheckListTemplate> rows) {
    List<TableRow> tableRows = [];
    int rowIndex = 0;
    rows.forEach((row) {
      rowIndex++;
      TableRow tableRow = TableRow(
          decoration: BoxDecoration(
              color: (rowIndex % 2 == 0
                  ? Theme.of(context).shadowColor
                  : Colors.white)),
          children: [
            getRowCell(row.name, row.id, 0),
          ]);
      tableRows.add(tableRow);
    });

    return Table(border: TableBorder.all(), children: tableRows);
  }

  Widget getRowCellItem(String text, int checkListId, int index,
      {TextAlign textAlign = TextAlign.left,
      bool isItem: false,
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
      backgroundColor: (rowIndex != null && rowIndex % 2 == 1)
          ? Theme.of(context).shadowColor
          : Colors.white,
      onTapDown: _storePosition,
      onLongPress: () {
        _showCustomMenu(checkListId, index,
            isItem: isItem, rowIndex: rowIndex, dialogSetter: dialogSetter);
      },
    ));
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
    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenu(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'add':
            addCheckListClicked();
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

    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/frameScreen.png"),
                fit: BoxFit.fill)),
        child: showLoading
            ? Text("")
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(children: [
                  ListTile(
                      trailing: menu,
                      contentPadding: EdgeInsets.all(0),
                      title: Text(
                          'Чтобы добавить новый шаблон чек-лист, выберите в меню "Добавить чек-лист" ',
                          textAlign: TextAlign.center),
                      onTap: () {}),
                  Expanded(
                      child: ListView(
                          padding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 150),
                          children: [
                        Column(children: [generateTableData(context, _items)])
                      ])),
                  /*Container(
                      child: MyButton(
                          text: 'test',
                          parentContext: context,
                          onPress: testClicked))*/
                ])));
  }
}*/
