import 'dart:ui';

import 'package:ek_asu_opb_mobile/controllers/checkPlanItem.dart';
import 'package:ek_asu_opb_mobile/controllers/comGroup.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/models/comGroup.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:search_widget/search_widget.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'dart:async';

/*class Group {
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
*/
class MyGroup {
  ComGroup group;
  Chat chat;
  List<Member> members;
  MyGroup(this.group, this.members, this.chat);
}

class Member {
  User user;
  int roleId;
  String depName;
  Member(this.user, {this.depName, this.roleId});
}

enum TYPE_LIST { commission, group, available }

class CommissionScreen extends StatefulWidget {
  int checkPlanId;
  BuildContext context;
  GlobalKey key;

  @override
  CommissionScreen(this.context, this.checkPlanId, this.key);

  @override
  State<CommissionScreen> createState() => _CommissionScreen(checkPlanId);
}

class _CommissionScreen extends State<CommissionScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  List<Member> userList =
      []; //Пользователи доступные в выпадающем списке комиссии
  List<Member> _userList = []; //полный список всех пользователей
  int checkPlanId;
  int railwayId;
  var _tapPosition;
  String commissionName;
  String emptyCommissionName;
  MyGroup _commision;
  List<MyGroup> _groups;
  List<Member> _commissionList;
  List<Member> _groupList;
  List<Member> _availableList;
  int headCommissionRole;
  int headGroupRole;
  var formGroupKey = new GlobalKey<FormState>();

  int selectedAvailibleUserId;
  int selectedGroupUserId;
  int selectedCommissionUserId;

  double heightCommision = 700.0;
  double widthCommision = 800.0;
  double widthGroup = 1000.0;

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
      //CheckPlan checkPlan = await CheckPlanController.selectById(checkPlanId);
      // railwayId = checkPlan.railwayId;
      List<User> allUserList =
          await UserController.selectByRailway(_userInfo.railway_id);

      allUserList.sort(
          (a, b) => a.display_name.trim().compareTo(b.display_name.trim()));

      for (User user in allUserList) {
        String shortDepName = await depName(user.department_id);
        _userList.add(Member(user, depName: shortDepName));
        userList.add(Member(user, depName: shortDepName));
      }

      _errorText = '';
      await loadGroups();
    } catch (e) {
      print(e);
    } finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
      if (_commision == null || _commision.group.id == null)
        editCommissionClicked();
    }
  }

  Future<List<Member>> getMembers(ComGroup group) async {
    List<User> users = await group.comUsers;
    int headId = group.headId;
    List<Member> result = [];

    for (User user in users) {
      String shortDepName = await depName(user.department_id);
      if (headId == user.id)
        result.add(Member(user,
            depName: shortDepName,
            roleId: group.isMain ? headCommissionRole : headGroupRole));
      else
        result.add(Member(user, depName: shortDepName));
    }

    return result;
  }

  Future<String> depName(int department_id) async {
    if (department_id == null) return '';
    return (await DepartmentController.selectById(department_id)).short_name;
  }

  loadGroups() async {
    _groups = [];
    List<ComGroup> groups = await ComGroupController.select(checkPlanId);
    ComGroup commision;
    if (groups.length > 0) {
      commision = groups.firstWhere((group) => group.isMain == true,
          orElse: () => null);

      if (commision != null) {
        Chat chat = new Chat(id: null, active: true);
        try {
          chat = await commision?.chat;
        } catch (e) {}

        _commision = new MyGroup(commision, await getMembers(commision), chat);
      }

      // groups.remove(commision);
      for (var i = 0; i < groups.length; i++)
        if (!groups[i].isMain) {
          Chat chat = new Chat(id: null, active: true);
          try {
            chat = await groups[i]?.chat;
          } catch (e) {}
          _groups.add(MyGroup(groups[i], await getMembers(groups[i]), chat));
        }
    } else
      _commision = null;

    if (_commision != null)
      commissionName = getMemberName(
          _commision.members, commision.isMain); //_commision.name;
    else {
      commissionName = emptyCommissionName;
      _commision = new MyGroup(
          ComGroup(
              id: null,
              odooId: null,
              parentId: checkPlanId,
              groupNum: null,
              isMain: true,
              active: true),
          [],
          Chat(id: null, active: true));
      // !![];
    }
  }

  Widget generateTableData(BuildContext context,
      List<Map<String, dynamic>> headers, List<MyGroup> rows) {
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
      if (!row.group.isMain) {
        TableRow tableRow = TableRow(
            decoration: BoxDecoration(
                color: (rowIndex % 2 == 0
                    ? Theme.of(context).shadowColor
                    : Colors.white)),
            children: [
              getRowCell(row.group.groupNum, row.group.id, 0),
              getRowCell(getMemberName(row.members, row.group.isMain),
                  row.group.id, 1),
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
        text ?? "",
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
      userList.add(_userList.firstWhere((user) => user.user.id == userId));
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
    /*if (selectedAvailibleUserId == null) {
      showError("Выберите пользователя для добавления в группу", setState);
      return;
    }*/
    Member member = _availableList.firstWhere(
        (available) => available.user.id == selectedAvailibleUserId,
        orElse: () => null);
    if (member != null) {
      _groupList.add(member);
      _availableList.remove(member);
      selectedAvailibleUserId =
          (_availableList.length > 0) ? _availableList.first.user.id : null;
      if (selectedGroupUserId == null) selectedGroupUserId = member.user.id;
      setState(() {});
    }
  }

  void removeUserFromGroup(setState) {
    /* if (selectedGroupUserId == null) {
      showError("Выберите пользователя для исключения из группы", setState);
      return;
    }*/

    Member member = _groupList.firstWhere(
        (group) => group.user.id == selectedGroupUserId,
        orElse: () => null);

    if (member != null) {
      _groupList.remove(member);
      if (_commision.members
          .any((commission) => commission.user.id == selectedGroupUserId))
        _availableList.add(member);
      selectedGroupUserId =
          (_groupList.length > 0) ? _groupList.first.user.id : null;
      if (selectedAvailibleUserId == null)
        selectedAvailibleUserId = member.user.id;
      setState(() {});
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
    MyGroup commissionCopy = new MyGroup(
        ComGroup(
            id: _commision.group.id,
            parentId: _commision.group.parentId,
            odooId: _commision.group.odooId,
            groupNum: _commision.group.groupNum,
            isMain: _commision.group.isMain,
            active: _commision.group.active,
            headId: _commision.group.headId),
        [],
        _commision.chat);
    _commision.members.forEach((member) {
      commissionCopy.members.add(Member(
          User(
            display_name: member.user.display_name,
            department_id: member.user.department_id,
            id: member.user.id,
          ),
          depName: member.depName,
          roleId: member.roleId));
    });
    bool result = await showCommissionDialog(commissionCopy, setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<void> addGroupClicked() async {
    if (_commision.group.id == null) {
      Scaffold.of(context)
          .showSnackBar(errorSnackBar(text: 'Сначала сохраните комиссию'));
      return;
    }
    MyGroup group = new MyGroup(
        ComGroup(
            id: null,
            parentId: checkPlanId,
            odooId: null,
            groupNum: null,
            isMain: false,
            active: true),
        [],
        Chat(id: null, active: true));
    bool result = await showGroupDialog(group, setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<void> editGroup(int groupId) async {
    MyGroup group = _groups.firstWhere((item) => item.group.id == groupId,
        orElse: () => null);
    if (group == null) return;

    MyGroup groupCopy = new MyGroup(
        ComGroup(
            id: group.group.id,
            odooId: group.group.odooId,
            parentId: group.group.parentId,
            groupNum: group.group.groupNum,
            isMain: group.group.isMain,
            active: group.group.active,
            headId: group.group.headId),
        [],
        group.chat);
    group.members.forEach((member) {
      groupCopy.members.add(Member(
          User(
            display_name: member.user.display_name,
            department_id: member.user.department_id,
            id: member.user.id,
          ),
          depName: member.depName,
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
      MyGroup deletedGroup = _groups
          .firstWhere((group) => group.group.id == groupId, orElse: () => null);

      if (deletedGroup == null) return;

      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        result = await ComGroupController.delete(groupId);
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          Scaffold.of(context).showSnackBar(
              errorSnackBar(text: 'Произошла ошибка при удалении'));
          return;
        }
        _groups.remove(deletedGroup);
        setState(() {});
      } catch (e) {
        Scaffold.of(context)
            .showSnackBar(errorSnackBar(text: 'Произошла ошибка при удалении'));
      }
    }
  }

  Future<bool> showGroupDialog(MyGroup group, setState) {
    bool isChatActive = group.chat != null && group.chat.active == true;
    setState(() {
      _groupList = group.members;
      _availableList = [];
      _commision.members.forEach((member) {
        if (!_groupList
            .any((groupMember) => groupMember.user.id == member.user.id))
          _availableList.add(member);
      });

      selectedAvailibleUserId =
          _availableList.length > 0 ? _availableList.first.user.id : null;
      selectedGroupUserId =
          _groupList.length > 0 ? _groupList.first.user.id : null;
      selectedCommissionUserId = null;
      // _commissionList.length > 0 ? _commissionList.first.user.id : null;
    });

    final color = Theme.of(widget.context).buttonColor;
    final textStyle = TextStyle(fontSize: 16.0, color: color);

    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return /*AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
                backgroundColor: Theme.of(context).primaryColor,
                content: SizedBox(
                  content:*/
                Stack(alignment: Alignment.center, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/app.jpg",
                  fit: BoxFit.fill,
                  height: heightCommision,
                  width: widthGroup,
                ),
              ),
              Container(
                  width: widthGroup,
                  margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Form(
                          key: formGroupKey,
                          child: Container(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(children: [
                                FormTitle('Формирование группы'),
                                TextIcon(
                                  iconSize: 50,
                                  
                                  icon: isChatActive
                                      ? Icons.toggle_on
                                      : Icons.toggle_off,
                                  text: isChatActive
                                      ? 'Выключить чат группы'
                                      : 'Включить чат группы',
                                  onTap: () {
                                    setState(() {
                                      isChatActive = !isChatActive;
                                      if (isChatActive == true)
                                        group.chat.setActive();
                                      else
                                        group.chat.setInactive();
                                    });
                                  },
                                  color:isChatActive
                                      ? Theme.of(context).primaryColorDark
                                      : Theme.of(context)
                                          .primaryColorDark
                                          .withOpacity(.5), //Colors.grey[600],
                                ),
                                Container(
                                  child: EditTextField(
                                    text: 'Название группы',
                                    value: group.group.groupNum,
                                    onSaved: (value) => setState(() {
                                      group.group.groupNum = value;
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: generateList(
                                                        _availableList,
                                                        setState,
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
                                        disabled: !(_availableList != null &&
                                            _availableList.length > 0),
                                        width: 100,
                                        onPress: () {
                                          addUserToGroup(setState);
                                        },
                                      ),
                                      Container(height: 30, child: Text('')),
                                      MyButton(
                                        parentContext: context,
                                        disabled: !(_groupList != null &&
                                            _groupList.length > 0),
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
                                                        CrossAxisAlignment
                                                            .start,
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
                                        style: TextStyle(
                                            color: Color(0xFF252A0E))))
                              ])))))
            ]);
          });
        });
  }

  Future<bool> showCommissionDialog(MyGroup commission, setState) {
    bool isChatActive =
        commission.chat != null && commission.chat.active == true;
    setState(() {
      _commissionList = [];
      _commision.members.forEach((member) {
        userList.removeWhere((user) => user.user.id == member.user.id);
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
            return /*AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
                backgroundColor: Theme.of(context).primaryColor,
                content:*/
                Stack(alignment: Alignment.center, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/app.jpg",
                  fit: BoxFit.fill,
                  height: heightCommision,
                  width: widthCommision,
                ),
              ),
              Container(
                  width: widthCommision,
                  margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Container(
                          child: Column(children: [
                        FormTitle('Формирование комиссии'),
                        TextIcon(
                          iconSize: 50,

                          icon:
                              isChatActive ? Icons.toggle_on : Icons.toggle_off,
                          text: isChatActive
                              ? 'Выключить чат комиссии'
                              : 'Включить чат комиссии',
                          onTap: () {
                            setState(() {
                              isChatActive = !isChatActive;
                              if (isChatActive)
                                commission.chat.setActive();
                              else
                                commission.chat.setInactive();
                            });
                          },
                          color: isChatActive
                              ? Theme.of(context).primaryColorDark
                              : Theme.of(context)
                                  .primaryColorDark
                                  .withOpacity(.5), //Colors.grey[600],
                        ),
                        Container(
                          child: SingleChildScrollView(
                              // padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                            children: <Widget>[
                              const SizedBox(
                                height: 16,
                              ),
                              if (_show)
                                new SearchWidget<Member>(
                                  key: Key('userList${userList.length}'),
                                  dataList: userList,
                                  hideSearchBoxWhenItemSelected: false,
                                  listContainerHeight:
                                      MediaQuery.of(context).size.height / 4,
                                  queryBuilder: (query, list) {
                                    return list
                                        .where((item) =>
                                            (item.user.display_name +
                                                    ' ' +
                                                    (item.user.function ?? '') +
                                                    ' ' +
                                                    (item.depName ?? ''))
                                                .toLowerCase()
                                                .contains(query.toLowerCase()))
                                        .toList();
                                  },
                                  popupListItemBuilder: (item) {
                                    return PopupListItemWidget(
                                        '${item.user.display_name} (${item.user.function ?? ''} ${item.depName ?? ''})');
                                  },
                                  selectedItemBuilder:
                                      (selectedItem, deleteSelectedItem) {
                                    return Text('');
                                    // return SelectedItemWidget(
                                    //      selectedItem, deleteSelectedItem);
                                  },
                                  // widget customization
                                  noItemsFoundWidget: NoItemsFound(),
                                  textFieldBuilder: (controller, focusNode) {
                                    return MyTextField(controller, focusNode,
                                        hintText: 'Введите ФИО сотрудника');
                                  },
                                  onItemSelected: (item) {
                                    _commissionList.add(Member(item.user,
                                        depName: item.depName));

                                    userList.removeWhere(
                                        (user) => user.user.id == item.user.id);
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
                                            typeList: TYPE_LIST.commission))))),
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
                      ]))))
            ]);
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
      {onTapdown, typeList, onTap, MyGroup group}) {
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
              //padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
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
                    height: 40,
                  ),
                  Expanded(
                      child: Container(
                          height: 40,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            //members[i].user.display_name,
                            '${members[i].user.display_name} (${members[i].user.function ?? ''} ${members[i].depName ?? ''})',
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

  Map<String, dynamic> makeHeadAndUids(MyGroup group) {
    ComGroup comGroup = group.group;

    comGroup.headId = null;
    List<int> ids = [];
    group.members.forEach((member) {
      if (member.roleId ==
          (group.group.isMain ? headCommissionRole : headGroupRole))
        comGroup.headId = member.user.id;
      // else
      ids.add(member.user.id);
    });
    return {'comGroup': comGroup, 'ids': ids};
  }

  Future<void> submitGroup(MyGroup group, setState) async {
    final form = formGroupKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool hasErorr = false;
      Map<String, dynamic> result;

      Map<String, dynamic> data = makeHeadAndUids(group);
      group.group = data['comGroup'];

      try {
        if (group.group.id == null) {
          result =
              await ComGroupController.insert(data['comGroup'], data['ids']);
        } else {
          result =
              await ComGroupController.update(data['comGroup'], data['ids']);
        }
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          Navigator.pop<bool>(context, false);
          Scaffold.of(context).showSnackBar(errorSnackBar());
        } else {
          if (group.group.id == null) {
            group.group.id = result["id"];
            setState(() {
              _groups.add(group);
            });
          } else {
            setState(() {
              int index =
                  _groups.indexWhere((item) => item.group.id == group.group.id);
              _groups[index] = group;
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

  Future<void> submitCommission(MyGroup commission, setState) async {
    bool hasErorr = false;
    Map<String, dynamic> result;

    Map<String, dynamic> data = makeHeadAndUids(commission);
    commission.group = data['comGroup'];
    //commission.group.groupNum = 'Все члены комиссии';

    try {
      if (commission.group.id == null) {
        result = await ComGroupController.insert(data['comGroup'], data['ids']);
      } else {
        result = await ComGroupController.update(data['comGroup'], data['ids']);
      }
      hasErorr = result["code"] < 0;

      if (hasErorr) {
        Navigator.pop<bool>(context, false);
        Scaffold.of(context).showSnackBar(errorSnackBar());
      } else {
        if (commission.group.id == null) commission.group.id = result["id"];
        setState(() {
          _commision = commission;
          commissionName =
              getMemberName(commission.members, commission.group.isMain);
        });

        Navigator.pop<bool>(context, true);
        Scaffold.of(context).showSnackBar(successSnackBar);
      }
    } catch (e) {
      Navigator.pop<bool>(context, false);
      Scaffold.of(context).showSnackBar(errorSnackBar());
    }
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
                    fit: BoxFit.fill)),
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
                            if (_commision.group.id != null)
                              Column(children: [
                                generateTableData(context, groupHeader, _groups)
                              ])
                          ])),
                    ]))));
  }
}
