import 'package:ek_asu_opb_mobile/controllers/controllers.dart' as controllers;
import 'package:ek_asu_opb_mobile/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/components/search.dart';

class Group {
  int id;
  String name;
  bool isCommision;
  bool active;
  List<Member> members;
  Group({this.id, this.name, this.isCommision, this.active});
}

class Member {
  User user;
  int roleId;
}

List<Group> groups;

class CommissionScreen extends StatefulWidget {
  int checkPlanId;

  BuildContext context;
  @override
  CommissionScreen(this.context, this.checkPlanId);

  @override
  State<CommissionScreen> createState() => _CommissionScreen(checkPlanId);
}

class _CommissionScreen extends State<CommissionScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  List<User> userList;
  int checkPlanId;
  var _tapPosition;
  String commisionName;
  String emptyCommissionName;
  Group _commision;

  @override
  _CommissionScreen(this.checkPlanId);

  final _list = const [
    'Igor Minar',
    'Brad Green',
    'Dave Geddes',
    'Naomi Black',
    'Greg Weber',
    'Dean Sofer',
    'Wes Alvaro',
    'John Scott',
    'Daniel Nadasi',
  ];

  List<Map<String, dynamic>> groupHeader = [
    {'text': 'Наименование группы', 'flex': 2.0},
    {'text': 'Участники', 'flex': 5.0},
  ];

  List<Map<String, dynamic>> choices = [
    {'title': "Редактировать группу", 'icon': Icons.edit, 'key': 'edit'},
    {'title': 'Удалить группу', 'icon': Icons.delete, 'key': 'delete'}
  ];

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          commisionName = '';
          emptyCommissionName =
              'Чтобы добавить комиссию, выберите в меню редактировать коммисию';
          loadData();
          //  setState(() {});
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});
      userList = await controllers.User.selectAll();
      await loadGroups(checkPlanId);
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
       if (_commision == null || _commision.id == null) editCommissionClicked();
    }
  }

  loadGroups(int planItemId) {
    groups = []; // загружать из базы
    if (groups.length > 0)
      _commision = groups.firstWhere((group) => group.isCommision == true,
          orElse: () => null);
    else
      _commision = null;

    if (_commision != null)
      commisionName = _commision.name;
    else {
      commisionName = emptyCommissionName;
      _commision =
          new Group(id: null, name: '', isCommision: true, active: true);
    }
  }

  Widget generateTableData(BuildContext context,
      List<Map<String, dynamic>> headers, List<Group> rows) {
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
            getRowCell(row.name, row.id, 0),
            getRowCell(getMemberName(row.members), row.id, 1),
          ]);
      tableRows.add(tableRow);
    });

    return Table(
        border: TableBorder.all(),
        columnWidths: columnWidths,
        children: tableRows);
  }

  Widget getRowCell(String text, int groupId, int index,
      {TextAlign textAlign = TextAlign.left}) {
    Widget cell = Container(
      padding: EdgeInsets.all(10.0),
      child: Text(
        text,
        textAlign: textAlign,
      ),
    );

    return GestureDetector(
        onTapDown: _storePosition,
        onLongPress: () {
          _showCustomMenu(groupId);
        },
        child: cell);
  }

  String getMemberName(List<Member> members) {
    return 'Иванов (рук.группы), Петров, Сидоров';
  }

  void _showCustomMenu(int groupId) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
        context: context,
        position: RelativeRect.fromRect(
            _tapPosition & const Size(1, 1), Offset.zero & overlay.size),
        items: <PopupMenuEntry<Map<String, dynamic>>>[
          CustomPopMenu(
            context: context,
            choices: choices,
          )
        ]).then<void>((Map<String, dynamic> choice) {
      if (choice == null) return;
      switch (choice["key"]) {
        case 'edit':
          editGroup(groupId);
          break;
        case 'delete':
          deleteGroup(groupId);
          break;
      }
    });
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  Future<void> editCommissionClicked() async {
    Group commissionCopy = new Group(
        id: _commision.id,
        name: _commision.name,
        isCommision: _commision.isCommision);

    /*  bool result = await showCommissionDialog(inspectionCopy);
    if (result != null && result) //иначе перезагружать _plan?
      setState(() {
        _inspection = inspectionCopy;
        widget.setCheckPlanId(_inspection.id);
        reloadInspection(_inspection.parentId);
      });*/
  }

  Future<void> addGroupClicked() async {
    /*if (_inspection.id == null) {
      Scaffold.of(context).showSnackBar(
          errorSnackBar(text: 'Сначала сохраните реквизиты плана проверок'));
      return;
    }
    InspectionItem inspectionItem = new InspectionItem(
        id: null,
        inspectionId: _inspection.id,
        date: DateTime.now(),
        active: true);
    bool result = await showInspectionItemDialog(inspectionItem, setState);
    if (result != null && result) {
      Map<String, dynamic> newValue = {
        'item': inspectionItem,
        'name': await depOrEventName(inspectionItem.eventId,
            inspectionItem.departmentId, inspectionItem.eventName)
      };
      setState(() {
        inspectionItems.add(newValue);
        //todo refresh all list?
      });
    }*/
  }

  Future<void> editGroup(int groupId) async {
    /*
       InspectionItem inspectionItem = (inspectionItems.firstWhere((item) =>
            (item["item"] as InspectionItem).id == inspectionItemId))["item"]
        as InspectionItem;
    InspectionItem inspectionItemCopy = new InspectionItem(
        id: inspectionItem.id,
        inspectionId: inspectionItem.inspectionId,
        departmentId: inspectionItem.departmentId,
        eventId: inspectionItem.eventId,
        eventName: inspectionItem.eventName,
        date: inspectionItem.date,
        timeBegin: inspectionItem.timeBegin,
        timeEnd: inspectionItem.timeEnd,
        groupId: inspectionItem.groupId);
    bool result = await showInspectionItemDialog(inspectionItemCopy, setState);
    if (result != null && result) {
      Map<String, dynamic> newValue = {
        'item': inspectionItemCopy,
        'name': await depOrEventName(inspectionItemCopy.eventId,
            inspectionItemCopy.departmentId, inspectionItemCopy.eventName)
      };

      setState(() {
        int index = inspectionItems.indexWhere((inspectionItem) =>
            (inspectionItem["item"] as InspectionItem).id == inspectionItemId);
        inspectionItems[index] = newValue;
      });
    }
    */
  }

  Future<void> deleteGroup(int groupId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить проверку?', context);
    if (result != null && result) {
      Group deletedGroup = groups.firstWhere((group) => group.id == groupId);

      if (deletedGroup == null) return;
      groups.remove(deletedGroup);
      //todo delete from db
      setState(() {});
    }
  }

  Future<bool> showCommissionDialog(Group commission) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
                backgroundColor: Theme.of(context).primaryColor,
                content: SizedBox(
                    width: 700.0,
                    // margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                    // padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Scaffold(
                        backgroundColor: Theme.of(context).primaryColor,
                        body: Container(
                            child: Column(children: [
                          Expanded(
                              child: Center(
                                  child: ListView(shrinkWrap: true, children: [
                            Text('формирование коммисии')
                          ]))),
                          Container(
                              child: Column(children: [
                            MyButton(
                                text: 'принять',
                                parentContext: context,
                                onPress: () {
                                  submitCommission(commission, setState);
                                }),
                          ]))
                        ])))));
          });
        });
  }

  Future<void> submitCommission(Group commission, setState) async {
    bool hasErorr = false;
    Map<String, dynamic> result;
    //if (commission.id == null) commission.id = result["id"];

    Navigator.pop<bool>(context, true);
    Scaffold.of(context).showSnackBar(successSnackBar);

    /* try {
        if (planCopy.id == null) {
          result = await controllers.PlanController.insert(planCopy);
        } else {
          result = await controllers.PlanController.update(planCopy);
        }
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          if (result["code"] == -1)
            setState(() {
              saveError = 'Уже существует план на ${planCopy.year} год';
              Timer(new Duration(seconds: 3), () {
                setState(() {
                  saveError = "";
                });
              });
            });
          //  Scaffold.of(context).showSnackBar(errorSnackBar(
          //      text: 'Уже существует план на ${planCopy.year} год'));
          else {
            Navigator.pop<bool>(context, false);
            Scaffold.of(context).showSnackBar(errorSnackBar());
          }
        } else {
          if (planCopy.id == null) planCopy.id = result["id"];

          Navigator.pop<bool>(context, true);
          Scaffold.of(context).showSnackBar(successSnackBar);
        }
      } catch (e) {
        Navigator.pop<bool>(context, false);
        Scaffold.of(context).showSnackBar(errorSnackBar());
      }
    }*/
  }

  List<PopupMenuItem<String>> getMenu(BuildContext context) {
    List<PopupMenuItem<String>> result = [];
    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.edit,
            text: "Редактировать комиссию",
            margin: 0.0,
            /* onTap: () */
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'edit'),
    );

    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.add,
            text: "Добавить группу",
            margin: 0.0,
            /* onTap: () ,*/
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'add'),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenu(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            editCommissionClicked();
            break;
          case 'add':
            addGroupClicked();
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

    return Expanded(
        child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/frameScreen.png"),
                    fit: BoxFit.fitWidth)),
            child: showLoading
                ? Text("")
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(children: [
                      ListTile(
                          trailing: menu,
                          contentPadding: EdgeInsets.all(0),
                          title:
                              Text(commisionName, textAlign: TextAlign.center),
                          onTap: () {}),
                      Expanded(
                          child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                            Column(children: [
                              generateTableData(context, groupHeader, groups)
                            ])
                          ])),
                    ]))));

    /* new MaterialSearchInput<String>(
      placeholder: 'ФИО участника', //placeholder of the search bar text input

      //or
      results: _list
          .map((name) => new MaterialSearchResult<String>(
                value: name, //The value must be of type <String>
                text: name, //String that will be show in the list
                //  icon: Icons.person,
              ))
          .toList(),
      filter: (dynamic value, String criteria) {
        return value
            .toLowerCase()
            .trim()
            .contains(new RegExp(r'' + criteria.toLowerCase().trim() + ''));
      },

      //callback when some value is selected, optional.
      onSelect: (String selected) {
        print(selected);
      },
      //callback when the value is submitted, optional.
      //  leading: null,
    );*/
  }
}
