import 'package:ek_asu_opb_mobile/controllers/checkList.dart';
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
  GlobalKey key;

  CheckListScreen(this.checkPlanItemId, this.push, this.pop, this.key);

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
  int _selectedTypeTemplate = 0;
  CheckList _currentCheckList;
  List<CheckList> _items;
  List<CheckList> _allItems;
  List<CheckList> _itemsCopy;
  List<CheckList> _itemsTemplate;
  var _tapPosition;
  double heightCheckList = 700;
  double widthCheckList = 1000;
  _CheckListScreen(this.checkPlanItemId);

  List<Map<String, dynamic>> checkListHeader = [
    {'text': 'Наименование', 'flex': 3},
    {'text': 'Тип', 'flex': 1}
  ];

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
      typeCheckListListAll = makeListFromJson(CheckList.typeSelection);
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

  void reloadTemplateCopyList() {
    _itemsTemplate = [];
    if (_itemsCopy != null)
      _itemsCopy.forEach((item) {
        if (item.type == _selectedTypeTemplate || _selectedTypeTemplate == 0)
          _itemsTemplate.add(CheckList.fromJson(item.toJson()));
      });
  }

  Future<void> loadCheckList() async {
    _itemsCopy = [];
    List<CheckList> items =
        await CheckListController.selectByParentId(checkPlanItemId);

    _allItems = items ?? [];

    _items = _allItems
        .where((item) =>
            item.is_active == true &&
            (item.type == _selectedType || _selectedType == 0))
        .toList();

    _items = _items ?? [];
  }

  Future<void> submitCheckListTemplate(List<CheckList> itemsCopy) async {
    bool hasErorr = false;
    Map<String, dynamic> result;
    List<CheckList> activeTemplates =
        itemsCopy.where((item) => item.is_active == true).toList() ?? [];
    List<int> ids =
        List.generate(activeTemplates.length, (i) => activeTemplates[i].id);

    try {
      result = await CheckListController.setIsActiveTrue(ids, checkPlanItemId);

      hasErorr = result["code"] < 0;

      if (hasErorr) {
        Navigator.pop<bool>(context, false);
        Scaffold.of(context)
            .showSnackBar(errorSnackBar(text: result["message"]));
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

  List<Widget> generateTableData(BuildContext context,
      List<Map<String, dynamic>> headers, List<CheckList> rows) {
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
    if (rows != null) {
      rows.forEach((row) {
        rowIndex++;

        Widget tableRow = Container(
            color: (rowIndex % 2 == 0
                ? Theme.of(context).shadowColor
                : Colors.white),
            child: IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  getRowCell(row.name, row.id, 0, flex: columnWidths[0]),
                  getRowCell(CheckList.typeSelection[row.type], row.id, 1,
                      flex: columnWidths[1]),
                ])));
        result.add(tableRow);
      });
    }

    return result;
  }

  Widget getRowCell(String text, int checkListId, int index,
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
              _showCustomMenu(checkListId, index);
            },
            child: cell));
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
    CheckList checkList =
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

  Future<void> editTemplateClicked() async {
    _itemsCopy = [];
    if (_allItems != null)
      _allItems.forEach((item) {
        _itemsCopy.add(CheckList.fromJson(item.toJson()));
      });

    reloadTemplateCopyList();

    bool result = await showTemplateClicked(setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<bool> showTemplateClicked(StateSetter setState) {
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
                            Row(children: [
                              Expanded(
                                  child: FormTitle('Шаблоны листов проверок:'),
                                  flex: 3),
                              Expanded(
                                  // width: 200,
                                  child: MyDropdown(
                                text: 'Тип',
                                dropdownValue: _selectedTypeTemplate.toString(),
                                items: typeCheckListListAll,
                                onChange: (value) {
                                  setState(() {
                                    _selectedTypeTemplate = int.parse(value);
                                    reloadTemplateCopyList();
                                  });
                                },
                                parentContext: context,
                              ))
                            ]),
                            Expanded(
                                child: ListView(
                                    children: List.generate(
                                        _itemsTemplate.length,
                                        (i) => MyCheckbox(
                                                _itemsTemplate[i].is_active,
                                                _itemsTemplate[i].name,
                                                (value) {
                                              CheckList item =
                                                  _itemsCopy.firstWhere(
                                                      (item) =>
                                                          item.id ==
                                                          _itemsTemplate[i].id,
                                                      orElse: () => null);

                                              if (item != null)
                                                item.is_active = value;
                                              _itemsTemplate[i].is_active =
                                                  value;
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
            editTemplateClicked();
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
                    Column(
                        children:
                            generateTableData(context, checkListHeader, _items))
                  ]))
            ]));
  }
}
