import 'package:ek_asu_opb_mobile/controllers/checkListItem.dart';
import 'package:ek_asu_opb_mobile/controllers/fault.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/models/checkListItem.dart';

class MyCheckListItem {
  CheckListItem item;
  int faultCount;
  

  MyCheckListItem(this.item, this.faultCount);
}

class CheckListItemScreen extends StatefulWidget {
  int checkListId;
  String checkListName;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;
  GlobalKey key;

  CheckListItemScreen(this.checkListId, this.push, this.pop, this.key,
      {this.checkListName});
  @override
  State<CheckListItemScreen> createState() => _CheckListItemScreen();
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
  List<MyCheckListItem> _items;
  CheckListItem _currentCheckLIstItem;

  List<Map<String, dynamic>> choicesItem = [
    {'title': 'Удалить запись', 'icon': Icons.delete, 'key': 'deleteItem'},
  ];

  List<Map<String, dynamic>> checkListItemHeader = [
    {'text': 'Вопрос', 'flex': 10},
    {'text': 'Результат', 'flex': 6},
    {'text': 'Комментарий', 'flex': 12},
    {'text': 'Количество нарушений всего', 'flex': 3}
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
    MyCheckListItem checkListItem =
        _items.firstWhere((item) => item.item.id == checkListItemId);

    MyCheckListItem itemCopy = MyCheckListItem(
        CheckListItem.fromJson(checkListItem.item.toJson()),
        checkListItem.faultCount);

    bool result = await showCheckListItemDialog(itemCopy, setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<void> deleteCheckListItem(int checkListItemId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить вопрос чек-лист?', context);
    if (result != null && result) {
      MyCheckListItem deletedCheckListItem = _items.firstWhere(
          (checkListItem) => checkListItem.item.id == checkListItemId,
          orElse: () => null);

      if (deletedCheckListItem == null) return;

      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        result = await CheckListItemController.delete(checkListItemId);
        hasErorr = result["code"] < 0;

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
    MyCheckListItem checkListItem = _items.firstWhere(
        (item) => item.item.id == checkListItemId,
        orElse: () => null);

    return widget.push({
      "pathTo": 'faultList',
      "pathFrom": 'checkListItem',
      'text': 'Назад к вопросам'
    }, {
      'checkListItemId': checkListItemId,
      'checkListItemName':
          checkListItem != null ? checkListItem.item.question : ''
    });
  }

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          checkListId = widget.checkListId;
          checkListName = widget.checkListName;
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
    _items = [];
    List<CheckListItem> items =
        await CheckListItemController.select(checkListId);
    for (int i = 0; i < items.length; i++) {
      int faultCount = await items[i].getFaultsCounts;
      _items.add(MyCheckListItem(items[i], faultCount));
    }

    _items = _items ?? []; //загружать из базы
  }

  Future<bool> showCheckListItemDialog(
      MyCheckListItem checkListItem, StateSetter setState) {
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
                          horizontal: 10.0, vertical: 40.0),
                      child: Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Form(
                              key: formCheckListItemKey,
                              child: Container(
                                  child: Column(children: [
                                FormTitle(
                                    '${checkListItem.item.id == null ? 'Добавление' : 'Редактирование'} вопроса'),
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
                                          value: checkListItem.item.question,
                                          onSaved: (value) => {
                                            checkListItem.item.question = value
                                          },
                                          context: context,
                                          height: 100,
                                          maxLines: 3,
                                          readOnly:
                                              checkListItem.item.base_id !=
                                                  null,
                                          showEditDialog:
                                              checkListItem.item.base_id ==
                                                  null,
                                          backgroundColor:
                                              checkListItem.item.base_id != null
                                                  ? Theme.of(context)
                                                      .primaryColorLight
                                                  : null,
                                          borderColor:
                                              checkListItem.item.base_id != null
                                                  ? Theme.of(context)
                                                      .primaryColorLight
                                                  : null,
                                        ),
                                        EditTextField(
                                          text: 'Результат',
                                          value: checkListItem.item.result,
                                          onSaved: (value) => {
                                            checkListItem.item.result = value
                                          },
                                          context: context,
                                          height: 100,
                                          maxLines: 3,
                                        ),
                                        EditTextField(
                                          text: 'Комментарий',
                                          value: checkListItem.item.description,
                                          onSaved: (value) => {
                                            checkListItem.item.description =
                                                value
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

  void submitCheckListItem(MyCheckListItem checkListItem, setState) async {
    final form = formCheckListItemKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        if (checkListItem.item.id == null) {
          result = await CheckListItemController.create(checkListItem.item);
        } else {
          result = await CheckListItemController.update(checkListItem.item);
        }
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          Navigator.pop<bool>(context, false);
          Scaffold.of(context).showSnackBar(errorSnackBar());
        } else {
          if (checkListItem.item.id == null) {
            checkListItem.item.id = result["id"];

            setState(() {
              _items.add(checkListItem);
            });
          } else {
            setState(() {
              int index = _items.indexOf(_items.firstWhere(
                  (element) => element.item.id == checkListItem.item.id));
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

  List<Widget> generateItemTable(BuildContext context,
      List<Map<String, dynamic>> headers, List<MyCheckListItem> rows) {
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
    rows.forEach((item) {
      CheckListItem row = item.item;
      rowIndex++;
      Color color = (item.faultCount != null && item.faultCount > 0)
          ? Color(0x44E57373)
          : Color(0x44ADF489);
      Widget tableRow = Container(
          color: color,
          child: IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                getRowCell(row.question, row.id, 0, flex: columnWidths[0]),
                getRowCell(row.result, row.id, 1, flex: columnWidths[1]),
                getRowCell(row.description, row.id, 2, flex: columnWidths[2]),
                getRowCell(
                    item.faultCount != null ? item.faultCount.toString() : '',
                    row.id,
                    3,
                    textAlign: TextAlign.center,
                    flex: columnWidths[3]),
              ])));
      result.add(tableRow);
    });

    return result;
  }

  Widget getRowCell(String text, int checkListItemId, int index,
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
              _showCustomMenu(checkListItemId, index);
            },
            child: cell));
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
    MyCheckListItem checkListItem = new MyCheckListItem(
        CheckListItem(id: null, parent_id: checkListId, active: true), 0);
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
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 5),
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
                    Column(
                        children: generateItemTable(
                            context, checkListItemHeader, _items))
                  ]))
            ]));
  }
}
