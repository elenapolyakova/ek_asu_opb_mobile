import 'package:ek_asu_opb_mobile/screens/checkListScreen.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/models/checkListItem.dart';

/*enum STATUS { template, success, fault }
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
*/

class CheckListItemScreen extends StatefulWidget {
  int checkListId;
  String checkListName;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;

  CheckListItemScreen(this.checkListId, this.push, this.pop,
      {this.checkListName});
  @override
  State<CheckListItemScreen> createState() =>
      _CheckListItemScreen(checkListId, checkListName: checkListName);
}

class _CheckListItemScreen extends State<CheckListItemScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  int checkListId;
  String checkListName;
  var _tapPosition;
  double heightCheckList = 700;
  double widthCheckList = 700;
  final formCheckListItemKey = new GlobalKey<FormState>();
  List<CheckListItem> _items;
  CheckListItem _currentCheckLIstItem;

  @override
  _CheckListItemScreen(this.checkListId, {this.checkListName});

  List<Map<String, dynamic>> choicesItem = [
    {'title': 'Удалить запись', 'icon': Icons.delete, 'key': 'deleteItem'},
  ];

  List<Map<String, dynamic>> checkListItemHeader = [
    {'text': 'Вопрос', 'flex': 5.0},
    {'text': 'Результат', 'flex': 3.0},
    {'text': 'Комментарий', 'flex': 6.0},
  ];

  List<Map<String, dynamic>> choices = [
    {'title': "Редактировать вопрос", 'icon': Icons.edit, 'key': 'edit'},
    {'title': 'Удалить вопрос', 'icon': Icons.delete, 'key': 'delete'},
    {
      'title': 'Перейти к нарушениям',
      'icon': Icons.arrow_forward,
      'key': 'forward'
    }
  ];

  void _showCustomMenu(int checkListItemId, int index) {
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
          editCheckListItem(checkListItemId);
          break;
        case 'delete':
          deleteCheckListItem(checkListItemId);
          break;
        case 'forward':
          forwardFault(checkListItemId);
          break;
      }
    });
  }

  Future<void> editCheckListItem(int checkListItemId) async {
    CheckListItem checkListItem =
        _items.firstWhere((item) => item.id == checkListItemId);

    CheckListItem itemCopy = CheckListItem(
        id: checkListItem.id,
        odooId: checkListItem.odooId,
        parent_id: checkListItem.parent_id,
        name: checkListItem.name,
        question: checkListItem.question,
        result: checkListItem.result,
        description: checkListItem.description,
        // base_id: checkListItem.base_id,
        active: checkListItem.active);

    bool result = await showCheckListItemDialog(itemCopy, setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<void> deleteCheckListItem(int checkListItemId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить вопрос чек-лист?', context);
    if (result != null && result) {
      CheckListItem deletedCheckListItem = _items.firstWhere(
          (checkListItem) => checkListItem.id == checkListItemId,
          orElse: () => null);

      if (deletedCheckListItem == null) return;

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
        _items.remove(deletedCheckListItem);
        setState(() {});
      } catch (e) {
        Scaffold.of(context)
            .showSnackBar(errorSnackBar(text: 'Произошла ошибка при удалении'));
      }
    }
  }

  void forwardFault(int checkListItemId) {
    CheckListItem checkListItem = _items
        .firstWhere((item) => item.id == checkListItemId, orElse: () => null);

    return widget.push({
      "pathTo": 'fault',
      "pathFrom": 'checkListItem',
      'text': 'Назад к вопросам'
    }, {
      'checkListItemId': checkListItemId,
      'checkListItemName': checkListItem != null ? checkListItem.name : ''
    });
  }

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
      await loadItems();
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  Future<void> loadItems() async {
    List<CheckListItem> items = [
      CheckListItem(
          id: 1,
          odooId: 1,
          parent_id: checkListId,
          name: 'Пункт 1',
          question: 'Вопрос 1',
          result: 'Результат 1',
          description: 'Комментарий',
          //base_id: 1,
          active: true),
      CheckListItem(
          id: 2,
          odooId: 2,
          parent_id: checkListId,
          name: 'Пункт 2',
          question: 'Вопрос 2',
          result: 'Результат 2',
          description: 'Комментарий',
          // base_id: 2,
          active: true),
      CheckListItem(
          id: 3,
          odooId: 3,
          parent_id: checkListId,
          name: 'Пункт 3',
          question: 'Вопрос 3',
          result: 'Результат 3',
          description: 'Комментарий',
          //   base_id: 3,
          active: true),
    ];

    _items = items ?? []; //загружать из базы
  }

  Future<bool> showCheckListItemDialog(
      CheckListItem checkListItem, StateSetter setState) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return Stack(alignment: Alignment.center, key: Key('checkListItem'),
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
                          horizontal: 30.0, vertical: 40.0),
                      child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Form(
                              key: formCheckListItemKey,
                              child: Container(
                                  child: Column(children: [
                                FormTitle(
                                    '${checkListItem.id == null ? 'Добавление' : 'Редактирование'} вопроса'),
                                Expanded(
                                    child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        EditTextField(
                                          text: 'Вопрос',
                                          value: checkListItem.question,
                                          onSaved: (value) =>
                                              {checkListItem.question = value},
                                          context: context,
                                          height: 100,
                                          maxLines: 3,
                                        ),
                                        EditTextField(
                                          text: 'Результат',
                                          value: checkListItem.result,
                                          onSaved: (value) =>
                                              {checkListItem.result = value},
                                          context: context,
                                          height: 100,
                                          maxLines: 3,
                                        ),
                                        EditTextField(
                                          text: 'Комментарий',
                                          value: checkListItem.description,
                                          onSaved: (value) => {
                                            checkListItem.description = value
                                          },
                                          context: context,
                                          height: 100,
                                          maxLines: 3,
                                        ),
                                      ],
                                    )
                                  ],
                                )),
                                Container(
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                      MyButton(
                                          text: 'принять',
                                          parentContext: context,
                                          onPress: () {
                                            submitCheckListItem(
                                                checkListItem, setState);
                                          }),
                                      MyButton(
                                          text: 'отменить',
                                          parentContext: context,
                                          onPress: () {
                                            cancelCheckListItem();
                                          }),
                                    ])),
                              ])))))
                ]);
          });
        });
  }

  Future<void> cancelCheckListItem() async {
    Navigator.pop<bool>(context, null);
  }

  void submitCheckListItem(CheckListItem checkListItem, setState) async {
    final form = formCheckListItemKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        if (checkListItem.id == null) {
          // result = await controllers.PlanController.insert(planCopy);
        } else {
          //result = await controllers.PlanController.update(planCopy);
        }
        // hasErorr = result["code"] < 0;

        if (hasErorr) {
          Navigator.pop<bool>(context, false);
          Scaffold.of(context).showSnackBar(errorSnackBar());
        } else {
          if (checkListItem.id == null) {
            checkListItem.id = 1000; //result["id"];

            setState(() {
              _items.add(checkListItem);
            });
          } else {
            setState(() {
              int index = _items.indexOf(_items
                  .firstWhere((element) => element.id == checkListItem.id));
              _items[index] = checkListItem;
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
  }

  Widget generateItemTable(BuildContext context,
      List<Map<String, dynamic>> headers, List<CheckListItem> rows) {
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
            getRowCell(row.question, row.id, 0),
            getRowCell(row.result, row.id, 1),
            getRowCell(row.description, row.id, 2),
          ]);
      tableRows.add(tableRow);
    });

    return Table(
        border: TableBorder.all(),
        columnWidths: columnWidths,
        children: tableRows);
  }

  Widget getRowCell(String text, int planItemId, int index,
      {TextAlign textAlign = TextAlign.left}) {
    Widget cell = Container(
      padding: EdgeInsets.all(10.0),
      child: Text(
        text ?? '',
        textAlign: textAlign,
      ),
    );

    return GestureDetector(
        onTapDown: _storePosition,
        onLongPress: () {
          _showCustomMenu(planItemId, index);
        },
        child: cell);
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  List<PopupMenuItem<String>> getMenuCheckListItem(BuildContext context) {
    List<PopupMenuItem<String>> result = [];
    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.add,
            text: "Добавить вопрос",
            margin: 5.0,
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'addCheckListItem'),
    );
    return result;
  }

  Future<void> addCheckListItemClicked(StateSetter setState) async {
    CheckListItem checkListItem =
        new CheckListItem(id: null, parent_id: checkListId, active: true);
    bool result = await showCheckListItemDialog(checkListItem, setState);
    if (result != null && result) {
      setState(() {});
      //todo refresh all list?
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenuCheckListItem(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'addCheckListItem':
            addCheckListItemClicked(setState);
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
        : Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: ListTile(
                      trailing: menu,
                      contentPadding: EdgeInsets.all(0),
                      title: FormTitle(checkListName ?? ''),
                      onTap: () {}),
                ),
              ]),
              Expanded(
                  child: ListView(
                      padding: EdgeInsets.only(
                        top: 10,
                      ),
                      children: [
                    Column(children: [
                      generateItemTable(context, checkListItemHeader, _items)
                    ])
                  ]))
            ]));
  }
}
