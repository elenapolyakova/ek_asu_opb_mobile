import 'dart:ui';

import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/screens/screens.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:search_widget/search_widget.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'dart:async';

import 'package:workmanager/workmanager.dart';

class Group {
  int id;
  int odooId;
  int checkPlanId;
  String name;
  bool isCommision;
  bool active;
  List<Member> members;
  Group(
      {this.id,
      this.odooId,
      this.checkPlanId,
      this.name,
      this.isCommision,
      this.active,
      this.members});
}

class Member {
  User user;
  int roleId;
  Member(this.user, {this.roleId});
}

enum TYPE_LIST { commission, group, available }

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
  List<User> _userList;
  int checkPlanId;
  var _tapPosition;
  String commissionName;
  String emptyCommissionName;
  Group _commision;
  List<Group> _groups;
  List<Member> _commissionList;
  List<Member> _groupList;
  List<Member> _availableList;
  int headCommissionRole;
  int headGroupRole;
  var formGroupKey = new GlobalKey<FormState>();

  int selectedAvailibleUserId;
  int selectedGroupUserId;
  int selectedCommissionUserId;

  String _errorText;

  @override
  _CommissionScreen(this.checkPlanId);

  //LeaderBoard _selectedItem;

  bool _show = true;

  List<Map<String, dynamic>> groupHeader = [
    {'text': 'Наименование группы', 'flex': 2.0},
    {'text': 'Участники', 'flex': 5.0},
  ];

  List<Map<String, dynamic>> choices = [
    {'title': "Редактировать группу", 'icon': Icons.edit, 'key': 'edit'},
    {'title': 'Удалить группу', 'icon': Icons.delete, 'key': 'delete'}
  ];

  List<Map<String, dynamic>> choicesComUnset = [
    {'title': "Исключить сотрудника", 'icon': Icons.delete, 'key': 'delete'},
    {
      'title': 'Отозвать председателя',
      'icon': Icons.star_outline_rounded,
      'key': 'unsetHead'
    }
  ];

  List<Map<String, dynamic>> choicesComSet = [
    {'title': "Исключить сотрудника", 'icon': Icons.delete, 'key': 'delete'},
    {'title': 'Назначить председателем', 'icon': Icons.star, 'key': 'setHead'}
  ];

  List<Map<String, dynamic>> choicesGroupUnset = [
    {
      'title': 'Отозвать руководителя',
      'icon': Icons.star_outline_rounded,
      'key': 'unsetHead'
    }
  ];

  List<Map<String, dynamic>> choicesGroupSet = [
    {'title': 'Назначить руководителем', 'icon': Icons.star, 'key': 'setHead'}
  ];

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          commissionName = '';
          headCommissionRole = 1;
          headGroupRole = 2;

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
      _userList = await UserController.selectAll();
      userList = await UserController.selectAll();
      _userList.sort(
          (a, b) => a.display_name.trim().compareTo(b.display_name.trim()));
      userList.sort(
          (a, b) => a.display_name.trim().compareTo(b.display_name.trim()));
      _errorText = '';
      await loadGroups();
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
      if (_commision == null || _commision.id == null) editCommissionClicked();
    }
  }

  Future<String> depName(int department_id) async {
    if (department_id == null) return '';
    return (await DepartmentController.selectById(department_id)).short_name;
  }

  loadGroups() {
    _groups = []; //checkPlanId // загружать из базы

    if (_groups.length > 0)
      _commision = _groups.firstWhere((group) => group.isCommision == true,
          orElse: () => null);
    else
      _commision = null;

    if (_commision != null)
      commissionName = getMemberName(
          _commision.members, _commision.isCommision); //_commision.name;
    else {
      commissionName = emptyCommissionName;
      _commision = new Group(
          id: null,
          odooId: null,
          checkPlanId: checkPlanId,
          name: '',
          isCommision: true,
          active: true,
          members: []); // !![];
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
      if (!row.isCommision) {
        TableRow tableRow = TableRow(
            decoration: BoxDecoration(
                color: (rowIndex % 2 == 0
                    ? Theme.of(context).shadowColor
                    : Colors.white)),
            children: [
              getRowCell(row.name, row.id, 0),
              getRowCell(
                  getMemberName(row.members, row.isCommision), row.id, 1),
            ]);
        tableRows.add(tableRow);
      }
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

  String getMemberName(List<Member> members, bool isCommission) {
    String headPosition = '';
    String head = '';
    String member = '';
    int headRoleId = 1;

    if (isCommission) {
      headRoleId = headCommissionRole;
      headPosition = 'председатель';
    } else {
      headRoleId = headGroupRole;
      headPosition = 'руководитель группы';
    }

    head = members
        .firstWhere((member) => member.roleId == headRoleId,
            orElse: () => Member(User(display_name: '')))
        .user
        .display_name;
    members.forEach((m) {
      if (m.roleId != headRoleId) member += '${m.user.display_name}, ';
    });
    member = member != '' ? slice(member, 0, -2) : member;
    return '${head != '' ? '$head($headPosition), ' : ''} $member';
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

  void _showCustomMenuForGroup(int userId, int roleId, setState) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
        context: context,
        position: RelativeRect.fromRect(
            _tapPosition & const Size(1, 1), Offset.zero & overlay.size),
        items: <PopupMenuEntry<Map<String, dynamic>>>[
          CustomPopMenu(
            context: context,
            choices:
                roleId == headGroupRole ? choicesGroupUnset : choicesGroupSet,
          )
        ]).then<void>((Map<String, dynamic> choice) {
      if (choice == null) return;
      switch (choice["key"]) {
        case 'setHead':
          setHeadGroup(userId, setState);
          break;
        case 'unsetHead':
          unsetHeadGroup(userId, setState);
          break;
      }
    });
  }

  void _showCustomMenuForCommission(int userId, int roleId, setState) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
        context: context,
        position: RelativeRect.fromRect(
            _tapPosition & const Size(1, 1), Offset.zero & overlay.size),
        items: <PopupMenuEntry<Map<String, dynamic>>>[
          CustomPopMenu(
            context: context,
            choices:
                roleId == headCommissionRole ? choicesComUnset : choicesComSet,
          )
        ]).then<void>((Map<String, dynamic> choice) {
      if (choice == null) return;
      switch (choice["key"]) {
        case 'delete':
          deleteUserFromCommission(userId, setState);
          break;
        case 'setHead':
          setHeadCommission(userId, setState);
          break;
        case 'unsetHead':
          unsetHeadCommission(userId, setState);
          break;
      }
    });
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void deleteUserFromCommission(int userId, setState) {
    setState(() {
      _commissionList.removeWhere((member) => member.user.id == userId);
      userList.add(_userList.firstWhere((user) => user.id == userId));
    });
  }

  void setHeadCommission(int userId, setState) {
    setState(() {
      _commissionList
          .where((member) => member.roleId == headCommissionRole)
          .forEach((oldHead) {
        oldHead.roleId = null;
      }); //todo заменить на роль участника
      _commissionList.firstWhere((member) => member.user.id == userId).roleId =
          headCommissionRole;
    });
  }

  void unsetHeadCommission(int userId, setState) {
    setState(() {
      _commissionList.firstWhere((member) => member.user.id == userId).roleId =
          null;
    }); //todo заменить на роль участника
  }

  void setHeadGroup(int userId, setState) {
    setState(() {
      _groupList
          .where((member) => member.roleId == headGroupRole)
          .forEach((oldHead) {
        oldHead.roleId = null;
      }); //todo заменить на роль участника
      _groupList.firstWhere((member) => member.user.id == userId).roleId =
          headGroupRole;
    });
  }

  void unsetHeadGroup(int userId, setState) {
    setState(() {
      _groupList.firstWhere((member) => member.user.id == userId).roleId = null;
    }); //todo заменить на роль участника
  }

  void addUserToGroup(setState) {
    if (selectedAvailibleUserId == null) {
      showError("Выберите пользователя для добавления в группу", setState);
      return;
    }
    Member member = _availableList.firstWhere(
        (available) => available.user.id == selectedAvailibleUserId,
        orElse: () => null);
    if (member != null) {
      setState(() {
        _groupList.add(member);
        _availableList.remove(member);
        selectedAvailibleUserId = null;
      });
    }
  }

  void removeUserFromGroup(setState) {
    if (selectedGroupUserId == null) {
      showError("Выберите пользователя для исключения из группы", setState);
      return;
    }

    Member member = _groupList.firstWhere(
        (group) => group.user.id == selectedGroupUserId,
        orElse: () => null);

    if (member != null) {
      setState(() {
        _groupList.remove(member);
        if (_commision.members
            .any((commission) => commission.user.id == selectedGroupUserId))
          _availableList.add(member);
        selectedGroupUserId = null;
      });
    }
  }

  void showError(String errorText, setState) {
    setState(() {
      _errorText = errorText;
      Timer(new Duration(seconds: 3), () {
        setState(() {
          _errorText = "";
        });
      });
    });
  }

  Future<void> editCommissionClicked() async {
    Group commissionCopy = new Group(
        id: _commision.id,
        odooId: _commision.id,
        name: _commision.name,
        isCommision: _commision.isCommision,
        members: []);
    _commision.members.forEach((member) {
      commissionCopy.members.add(Member(
          User(
            display_name: member.user.display_name,
            department_id: member.user.department_id,
            id: member.user.id,
          ),
          roleId: member.roleId));
    });
    bool result = await showCommissionDialog(commissionCopy, setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<void> addGroupClicked() async {
    if (_commision.id == null) {
      Scaffold.of(context)
          .showSnackBar(errorSnackBar(text: 'Сначала сохраните комиссию'));
      return;
    }
    Group group = new Group(
        id: null,
        checkPlanId: checkPlanId,
        odooId: null,
        name: '',
        isCommision: false,
        members: [],
        active: true);
    bool result = await showGroupDialog(group, setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<void> editGroup(int groupId) async {
    Group group =
        _groups.firstWhere((group) => group.id == groupId, orElse: () => null);
    if (group == null) return;

    Group groupCopy = new Group(
        id: group.id,
        odooId: group.odooId,
        checkPlanId: group.checkPlanId,
        name: group.name,
        isCommision: group.isCommision,
        members: [],
        active: group.active);
    group.members.forEach((member) {
      groupCopy.members.add(Member(
          User(
            display_name: member.user.display_name,
            department_id: member.user.department_id,
            id: member.user.id,
          ),
          roleId: member.roleId));
    });

    bool result = await showGroupDialog(groupCopy, setState);
    if (result != null && result) {
      setState(() {
        //  int index = inspectionItems.indexWhere((inspectionItem) =>
        //     (inspectionItem["item"] as InspectionItem).id == inspectionItemId);
        //  inspectionItems[index] = newValue;
      });
    }
  }

  Future<void> deleteGroup(int groupId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить группу?', context);
    if (result != null && result) {
      Group deletedGroup = _groups.firstWhere((group) => group.id == groupId);

      if (deletedGroup == null) return;
      _groups.remove(deletedGroup);
      //todo delete from db
      setState(() {});
    }
  }

  Future<bool> showGroupDialog(Group group, setState) {
    setState(() {
      _groupList = group.members;
      _availableList = [];
      _commision.members.forEach((member) {
        if (!_groupList
            .any((groupMember) => groupMember.user.id == member.user.id))
          _availableList.add(member);
      });

      selectedAvailibleUserId = null;
      selectedGroupUserId = null;
      selectedCommissionUserId = null;
    });

    final color = Theme.of(widget.context).buttonColor;
    final textStyle = TextStyle(fontSize: 16.0, color: color);

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
                    width: 1000.0,
                    // margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                    // padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Scaffold(
                        backgroundColor: Theme.of(context).primaryColor,
                        body: Form(
                            key: formGroupKey,
                            child: Container(
                                child: Column(children: [
                             
                               FormTitle('Формирование группы'),
                              Container(
                                child: EditTextField(
                                  text: 'Название группы',
                                  value: group.name,
                                  onSaved: (value) => setState(() {
                                    group.name = value;
                                  }),
                                  context: context,
                                ),
                              ),
                              Expanded(
                                  child: Row(children: [
                                Expanded(
                                    child: Column(children: [
                                  Container(
                                      child: Text(
                                        'Члены коммиссии:',
                                        style: textStyle,
                                        textAlign: TextAlign.left,
                                      ),
                                      width: double.maxFinite,
                                      padding: EdgeInsets.only(bottom: 5)),
                                  Expanded(
                                      child: Container(
                                          height: double.infinity,
                                          width: 1000, //костыль
                                          margin: EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            color: Colors.white,
                                          ),
                                          child: SingleChildScrollView(
                                              child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: generateList(
                                                      _availableList, setState,
                                                      typeList: TYPE_LIST
                                                          .available)))))
                                ])),
                                Container(
                                    // height: double.infinity,
                                    child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    MyButton(
                                      parentContext: context,
                                      text: '>>',
                                      width: 100,
                                      onPress: () {
                                        addUserToGroup(setState);
                                      },
                                    ),
                                    Container(height: 30, child: Text('')),
                                    MyButton(
                                      parentContext: context,
                                      text: '<<',
                                      width: 100,
                                      onPress: () {
                                        removeUserFromGroup(setState);
                                      },
                                    )
                                  ],
                                )),
                                Expanded(
                                    child: Column(children: [
                                  Container(
                                      child: Text(
                                        'Участники группы:',
                                        textAlign: TextAlign.left,
                                        style: textStyle,
                                      ),
                                      width: double.maxFinite,
                                      padding: EdgeInsets.only(bottom: 5)),
                                  Expanded(
                                      child: Container(
                                          height: double.infinity,
                                          width: 1000, //костыль
                                          margin: EdgeInsets.only(bottom: 10),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            color: Colors.white,
                                          ),
                                          child: SingleChildScrollView(
                                              child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: generateList(
                                                      _groupList, setState,
                                                      typeList:
                                                          TYPE_LIST.group)))))
                                ])),
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
                                          group.members = _groupList;
                                          submitGroup(group, setState);
                                        }),
                                    MyButton(
                                        text: 'отменить',
                                        parentContext: context,
                                        onPress: () {
                                          cancelCommission();
                                        }),
                                  ])),
                              Container(
                                  width: double.infinity,
                                  height: 20,
                                  color: (_errorText != "")
                                      ? Color(0xAAE57373)
                                      : Color(0x00E57373),
                                  child: Text('$_errorText',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: Color(0xFF252A0E))))
                            ]))))));
          });
        });
  }

  Future<bool> showCommissionDialog(Group commission, setState) {
    setState(() {
      _commissionList = [];
      _commision.members.forEach((member) {
        userList.removeWhere((user) => user.id == member.user.id);
      });
      _commissionList = commission.members;

      selectedAvailibleUserId = null;
      selectedGroupUserId = null;
      selectedCommissionUserId = null;
    });
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
                              FormTitle('Формирование комиссии'),
                        
                          Container(
                            child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Column(
                                  children: <Widget>[
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    if (_show)
                                      new SearchWidget<User>(
                                        key: Key('userList${userList.length}'),
                                        dataList: userList,
                                        hideSearchBoxWhenItemSelected: false,
                                        listContainerHeight:
                                            MediaQuery.of(context).size.height /
                                                4,
                                        queryBuilder: (query, list) {
                                          return list
                                              .where((item) => item.display_name
                                                  .toLowerCase()
                                                  .contains(
                                                      query.toLowerCase()))
                                              .toList();
                                        },
                                        popupListItemBuilder: (item) {
                                          return PopupListItemWidget(
                                              item.display_name);
                                        },
                                        selectedItemBuilder:
                                            (selectedItem, deleteSelectedItem) {
                                          return Text('');
                                          // return SelectedItemWidget(
                                          //      selectedItem, deleteSelectedItem);
                                        },
                                        // widget customization
                                        noItemsFoundWidget: NoItemsFound(),
                                        textFieldBuilder:
                                            (controller, focusNode) {
                                          return MyTextField(
                                              controller, focusNode,
                                              hintText:
                                                  'Введите ФИО сотрудника');
                                        },
                                        onItemSelected: (item) {
                                          _commissionList.add(Member(item));

                                          userList.removeWhere(
                                              (user) => user.id == item.id);
                                          setState(() {
                                            //_selectedItem = item;
                                          });
                                        },
                                      ),
                                    const SizedBox(
                                      height: 32,
                                    )
                                  ],
                                )),
                          ),
                          Expanded(
                              child: Container(
                                  width: 650,
                                  margin: EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: Colors.white,
                                  ),
                                  child: SingleChildScrollView(
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: generateList(
                                              _commissionList, setState,
                                              typeList:
                                                  TYPE_LIST.commission))))),
                          Container(
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                MyButton(
                                    text: 'принять',
                                    parentContext: context,
                                    onPress: () {
                                      commission.members = _commissionList;
                                      submitCommission(commission, setState);
                                    }),
                                MyButton(
                                    text: 'отменить',
                                    parentContext: context,
                                    onPress: () {
                                      cancelCommission();
                                    }),
                              ]))
                        ])))));
          });
        });
  }

  void onRowSelected(int userId, typeList, setState) {
    setState(() {
      switch (typeList) {
        case TYPE_LIST.commission:
          selectedCommissionUserId = userId;
          break;
        case TYPE_LIST.group:
          selectedGroupUserId = userId;
          break;
        case TYPE_LIST.available:
          selectedAvailibleUserId = userId;
          break;
      }
    });
  }

  List<Widget> generateList(List<Member> members, setState,
      {onTapdown, typeList, onTap, Group group}) {
    if (members == null || members.length == 0)
      return [Text('')]; //'Список членов комиссии пуст')];
    return List.generate(members.length, (i) {
      Function onLongPress;

      if (typeList == TYPE_LIST.commission)
        onLongPress = () {
          _showCustomMenuForCommission(
              members[i].user.id, members[i].roleId, setState);
        };
      if (typeList == TYPE_LIST.group) {
        onLongPress = () {
          _showCustomMenuForGroup(
              members[i].user.id, members[i].roleId, setState);
        };
      }

      Color backGroundColor;
      Color fontColor;
      if (typeList == TYPE_LIST.commission &&
              members[i].user.id == selectedCommissionUserId ||
          typeList == TYPE_LIST.group &&
              members[i].user.id == selectedGroupUserId ||
          typeList == TYPE_LIST.available &&
              members[i].user.id == selectedAvailibleUserId) {
        backGroundColor = Theme.of(context).primaryColorDark;
        fontColor = Theme.of(context).primaryColorLight;
      } else {
        backGroundColor = null;
        fontColor = Theme.of(context).buttonColor;
      }

      return GestureDetector(
          onTapDown: onTapdown ?? _storePosition,
          onLongPress: onLongPress,
          onTap: () => onRowSelected(members[i].user.id, typeList, setState),
          child: Container(
              color: backGroundColor,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    child: (members[i].roleId == headCommissionRole &&
                            typeList == TYPE_LIST.commission)
                        ? Icon(
                            Icons.star,
                            color: fontColor,
                          ) //для председателя
                        : (members[i].roleId == headGroupRole &&
                                typeList == TYPE_LIST.group
                            ? Icon(
                                Icons.star,
                                color: fontColor,
                              ) //для руководителя группы
                            : Text('')),
                    width: 30,
                    height: 20,
                  ),
                  Expanded(
                      child: Container(
                          height: 20,
                          child: Text(
                            members[i].user.display_name,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: fontColor,
                            ),
                          )))
                ],
              )));
    });
  }

  Future<void> cancelCommission() async {
    Navigator.pop<bool>(context, null);
  }

  Future<void> submitGroup(Group group, setState) async {
    final form = formGroupKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool hasErorr = false;
      Map<String, dynamic> result;

      if (group.id == null) {
        group.id = 1;

        setState(() {
          _groups.add(group);

          //loadGroups(); todo раскоментировать как появится база
        });
      } else {
        setState(() {
          int index = _groups.indexWhere((item) => item.id == group.id);
          _groups[index] = group;
        });
      }

      Navigator.pop<bool>(context, true);
      Scaffold.of(context).showSnackBar(successSnackBar);

      /* try {
        if (planCopy.id == null) {
          result = await PlanController.insert(planCopy);
        } else {
          result = await PlanController.update(planCopy);
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
  }

  Future<void> submitCommission(Group commission, setState) async {
    bool hasErorr = false;
    Map<String, dynamic> result;
    commission.name = 'Все члены комиссии';
    if (commission.id == null) {
      commission.id = 1;
    }

    setState(() {
      _commision = commission;

      //loadGroups(); todo раскоментировать как появится база
      commissionName =
          getMemberName(commission.members, commission.isCommision);
    });

    Navigator.pop<bool>(context, true);
    Scaffold.of(context).showSnackBar(successSnackBar);

    /* try {
        if (planCopy.id == null) {
          result = await PlanController.insert(planCopy);
        } else {
          result = await PlanController.update(planCopy);
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
                              Text(commissionName, textAlign: TextAlign.center),
                          onTap: () {}),
                      Expanded(
                          child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                            if (_commision.id != null)
                              Column(children: [
                                generateTableData(context, groupHeader, _groups)
                              ])
                          ])),
                    ]))));
  }
}
