import 'package:ek_asu_opb_mobile/controllers/fault.dart';
import 'package:ek_asu_opb_mobile/models/fault.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:ek_asu_opb_mobile/models/faultFix.dart';
import 'package:ek_asu_opb_mobile/controllers/faultFix.dart';

class FaultFixListScreen extends StatefulWidget {
  int faultId;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;
  GlobalKey key;

  @override
  FaultFixListScreen(this.faultId, this.push, this.pop, this.key);

  @override
  State<FaultFixListScreen> createState() => _FaultFixListScreen();
}

class _FaultFixListScreen extends State<FaultFixListScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  Fault _fault;
  List<FaultFix> _items;
  var _tapPosition;

  List<Map<String, dynamic>> faultFixListHeader = [
    {'text': 'Дата устранения', 'flex': 2},
    {'text': 'Описание устранения', 'flex': 9},
    {'text': 'Проверено', 'flex': 1},
  ];

  List<Map<String, dynamic>> choices = [
    {'title': 'Удалить', 'icon': Icons.delete, 'key': 'delete'},
    {'title': 'Редактировать', 'icon': Icons.edit, 'key': 'edit'},
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

      _fault = await FaultController.selectById(widget.faultId);
      List<FaultFix> items = await FaultFixController.select(widget.faultId);

      _items = items ?? [];
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  Future<void> addFaultFixClicked(StateSetter setState) async {
    return widget.push({
      "pathTo": 'faultFix',
      "pathFrom": 'faultFixList',
      'text': 'Назад к списку устранений'
    }, {
      'faultFixId': -1
    });
  }

  Future<void> editFaultFixClicked(int faultFixId) async {
    return widget.push({
      "pathTo": 'faultFix',
      "pathFrom": 'faultFixList',
      'text': 'Назад к списку устранений'
    }, {
      'faultFixId': faultFixId
    });
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showCustomMenu(int faultFixId, int index) {
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
          editFaultFixClicked(faultFixId);
          break;
        case 'delete':
          deleteFaultFixClicked(faultFixId);
          break;
      }
    });
  }

  Future<void> deleteFaultFixClicked(int faultFixId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить устранение нарушения?', context);
    if (result != null && result) {
      FaultFix deletedFaultFix = _items.firstWhere(
          (faultFix) => faultFix.id == faultFixId,
          orElse: () => null);

      if (deletedFaultFix == null) return;

      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        result = await FaultFixController.delete(faultFixId);
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          Scaffold.of(context).showSnackBar(
              errorSnackBar(text: 'Произошла ошибка при удалении'));
          return;
        }
        _items.remove(deletedFaultFix);
        setState(() {});
      } catch (e) {
        Scaffold.of(context)
            .showSnackBar(errorSnackBar(text: 'Произошла ошибка при удалении'));
      }
    }
  }

  List<Widget> generateFaultFixTable(BuildContext context,
      List<Map<String, dynamic>> headers, List<FaultFix> rows) {
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
                getRowCell(dateDMY(row.date), row.id, 0,
                    textAlign: TextAlign.center, flex: columnWidths[0]),
                getRowCell(row.desc, row.id, 1, flex: columnWidths[1]),
                getRowCell((row.is_finished == true).toString(), row.id, 2,
                    textAlign: TextAlign.center, flex: columnWidths[2]),
              ])));
      result.add(tableRow);
    });

    return result;
  }

  Widget getRowCell(String text, int faultFixId, int index,
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
        child: Container(
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
        ));

    return Expanded(
        flex: flex,
        child: GestureDetector(
            onTapDown: _storePosition,
            onLongPress: () {
              _showCustomMenu(faultFixId, index);
            },
            child: cell));
  }

  @override
  Widget build(BuildContext context) {
    final menu = PopupMenuButton(
      itemBuilder: (_) {
        List<PopupMenuItem<String>> result = [];
        result.add(
          PopupMenuItem<String>(
              child: TextIcon(
                icon: Icons.add,
                text: "Добавить устранение",
                margin: 5.0,
                color: Theme.of(context).primaryColorDark,
              ),
              value: 'addFaultFix'),
        );
        return result;
      },
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'addFaultFix':
            addFaultFixClicked(setState);
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
                      title: FormTitle(
                          "Контроль устранения нарушения '${_fault.name ?? ''}'" ??
                              ''),
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
                        children: generateFaultFixTable(
                            context, faultFixListHeader, _items))
                  ]))
            ]));
  }
}
