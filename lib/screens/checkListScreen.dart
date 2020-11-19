import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/models/checkList.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';

/*List<Map<String, dynamic>> statusSelectionCheckList = [
  {
    'id': 1,
    'name': 'Не рассматривался',
    'value': STATUS_CHECK_LIST.template,
    'color': Colors.grey.shade200
  },
  {
    'id': 2,
    'name': 'Пройдено без замечаний',
    'value': STATUS_CHECK_LIST.success,
    'color': Colors.green.shade200
  },
  {
    'id': 3,
    'name': 'Есть нарушения',
    'value': STATUS_CHECK_LIST.fault,
    'color': Colors.red.shade200
  }
];

getStatusCheckListById(int id) {
  Map<String, dynamic> statusItem = statusSelectionCheckList
      .firstWhere((status) => status['id'] == id, orElse: () => null);
  if (statusItem != null) return statusItem["value"];
  return null;
}

getColorByStatusCheckList(STATUS_CHECK_LIST status) {
  Map<String, dynamic> statusItem = statusSelectionCheckList
      .firstWhere((item) => item['value'] == status, orElse: () => null);
  if (statusItem != null) return statusItem["color"];
  return Colors.grey.shade200;
}

enum STATUS_CHECK_LIST { template, success, fault }*/

class CheckListScreen extends StatefulWidget {
  int checkPlanItemId;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;

  CheckListScreen(this.checkPlanItemId, this.push, this.pop);

  @override
  State<CheckListScreen> createState() => _CheckListScreen(checkPlanItemId);
}

class _CheckListScreen extends State<CheckListScreen> {
  int checkPlanItemId;
  UserInfo _userInfo;
  bool showLoading = true;
  // List<Map<String, Object>> typeCheckListList;
  List<Map<String, Object>> typeCheckListListAll;
  int _selectedType = 0;
  CheckListWork _currentCheckList;
  List<CheckListWork> _items;
  List<CheckListWork> _allItems;
  var _tapPosition;
  double heightCheckList = 700;
  double widthCheckList = 1000;
  _CheckListScreen(this.checkPlanItemId);

   static Map<int, String> typeSelection = {
    1: 'Воздух',
    2: 'Вода',
    3: 'Отходы',
    4: 'Почва',
    5: 'Почва',
    6: 'Гос.органы',
    7: 'Эко-менеджмент',
    8: 'Эко-риски'
  };

  List<Map<String, dynamic>> choices = [
    {
      'title': "Перейти к чек-листу",
      'icon': Icons.arrow_forward,
      'key': 'edit'
    },
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
      // typeCheckListList = makeListFromJson(CheckList.typeSelection);
     // typeCheckListListAll = makeListFromJson(CheckListWork.typeSelection); //todo вернуть
      typeCheckListListAll = makeListFromJson(typeSelection);
      typeCheckListListAll.insert(0, {'id': 0, 'value': 'Все'});
      await loadCheckList();
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  void reloadCheckList() {
    _items = _allItems
        .where((items) =>
            items.is_active == true &&
            (items.type == _selectedType || _selectedType == 0))
        .toList();
    _items = _items ?? [];
  }

  Future<void> loadCheckList() async {
    List<CheckListWork> items = [
    CheckListWork(
        id: 1,
        odooId: 1,
        parent_id: checkPlanItemId,
        is_base: true,
        name: 'Чек-лист 1',
        type: 1,
        active: true,
        is_active: true),
    CheckListWork(
        id: 2,
        odooId: 2,
        parent_id: checkPlanItemId,
        is_base: true,
        name: 'Чек-лист 2',
        type: 2,
        active: true,
        is_active: true),
    CheckListWork(
        id: 3,
        odooId: 3,
        parent_id: checkPlanItemId,
        is_base: true,
        name: 'Чек-лист 3',
        type: 3,
        active: true,
        is_active: false)
  ];



    _allItems = items ?? [];

    _items = _allItems
        .where((item) =>
            item.is_active == true &&
            (item.type == _selectedType || _selectedType == 0))
        .toList();

    _items = _items ?? [];
  }

  Future<void> submitCheckListTemplate(List<CheckListWork> itemsCopy) async {
    bool hasErorr = false;
    Map<String, dynamic> result;
    try {
      // result = await ComGroupController.update(data['comGroup'], data['ids']);

      // hasErorr =  result["code"] < 0;

      if (hasErorr) {
        Navigator.pop<bool>(context, false);
        Scaffold.of(context).showSnackBar(errorSnackBar());
      } else {
        setState(() {
          _allItems = itemsCopy;
          reloadCheckList();
        });

        Navigator.pop<bool>(context, true);
        Scaffold.of(context).showSnackBar(successSnackBar);
      }
    } catch (e) {
      Navigator.pop<bool>(context, false);
      Scaffold.of(context).showSnackBar(errorSnackBar());
    }
  }

  Future<void> cancelCheckListTemplate() async {
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

  Widget generateTableData(BuildContext context, List<CheckListWork> rows) {
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

    return Table(
      border: TableBorder.all(),
      children: tableRows,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    );
  }

  Widget getRowCell(String text, int checkListId, int index,
      {TextAlign textAlign = TextAlign.left}) {
    return GestureDetector(
        onTapDown: _storePosition,
        onLongPress: () {
          _showCustomMenu(checkListId, index);
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

  void _showCustomMenu(int id, int index) {
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
          editCheckList(id);
          break;
      }
    });
  }

  void editCheckList(int checkListId) {
    CheckListWork checkList =
        _items.firstWhere((item) => item.id == checkListId, orElse: () => null);
    /* Map<String, dynamic> args = {
      'checkListId': checkListId,
      'checkPlanItemId': widget.checkPlanItemId
    };
    Navigator.pushNamed(context, '/checkListItem', arguments: args);*/

    return widget.push({
      "pathTo": 'checkListItem',
      "pathFrom": 'checkList',
      'text': 'Назад к листам проверок'
    }, {
      'checkListId': checkListId,
      'checkListName': checkList != null ? checkList.name : ''
    });
  }

  Future<bool> editTemplateClicked(StateSetter setState) {
    List<CheckListWork> _itemsCopy = [];
    if (_allItems != null)
      _allItems.forEach((item) {
        _itemsCopy.add(CheckListWork(
          parent_id: item.parent_id,
          id: item.id,
          is_active: item.is_active,
          name: item.name,
          odooId: item.odooId,
          is_base: item.is_base,
          type: item.type,
          //base_id: item.base_id,
          active: item.active,
        ));
      });
    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return Stack(
                alignment: Alignment.center,
                key: Key('checkListTemplate'),
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
                              child: Container(
                                  child: Column(children: [
                            FormTitle('Шаблоны листов проверок:'),
                            Expanded(
                                child: ListView(
                                    children: List.generate(
                                        _itemsCopy.length,
                                        (i) => MyCheckbox(
                                                _itemsCopy[i].is_active,
                                                _itemsCopy[i].name, (value) {
                                              _itemsCopy[i].is_active = value;
                                              setState(() {});
                                            })))),
                            Container(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                  MyButton(
                                      text: 'принять',
                                      parentContext: context,
                                      onPress: () {
                                        submitCheckListTemplate(_itemsCopy);
                                      }),
                                  MyButton(
                                      text: 'отменить',
                                      parentContext: context,
                                      onPress: () {
                                        cancelCheckListTemplate();
                                      }),
                                ])),
                          ])))))
                ]);
          });
        });
  }

  List<PopupMenuItem<String>> getMenuTemplate(BuildContext context) {
    List<PopupMenuItem<String>> result = [];
    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.fact_check,
            text: "Перечень шаблонов",
            margin: 5.0,
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'editTemplate'),
    );

    result.add(PopupMenuItem<String>(
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
    )));

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenuTemplate(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'editTemplate':
            editTemplateClicked(setState);
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
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 100),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(
                  child: ListTile(
                      trailing: menu,
                      contentPadding: EdgeInsets.all(0),
                      title: FormTitle("Список листов проверок:"),
                      onTap: () {}),
                ),
              ]),
              Expanded(
                  child: ListView(
                      padding: EdgeInsets.only(
                        top: 16,
                      ),
                      children: [
                    Column(children: [generateTableData(context, _items)])
                  ]))
            ]));
  }
}
