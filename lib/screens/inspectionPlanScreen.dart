import 'dart:io';

import 'package:ek_asu_opb_mobile/controllers/checkPlanItem.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/controllers/report.dart';
import 'package:ek_asu_opb_mobile/models/comGroup.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/utils/dictionary.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:open_file/open_file.dart';

/*class InspectionItem {
  int id;
  int odooId;
  int inspectionId;
  int departmentId; //если проверка СП
  int eventId; //для обеда, отъезда, ужина и тд
  String eventName; //событие текстом на случай встреча с руководством и тд
  DateTime date; //Дата проверки
  DateTime timeBegin; //Время начала проверки
  DateTime timeEnd; //Время окончания проверки
  int groupId; //члены комиссии
  bool active;
  InspectionItem(
      {this.id,
      this.odooId,
      this.inspectionId,
      this.departmentId,
      this.eventId,
      this.eventName,
      this.date,
      this.timeBegin,
      this.timeEnd,
      this.groupId,
      this.active = true});
}
*/
//todo delete
class InspectionPlanScreen extends StatefulWidget {
  BuildContext context;
  Map<String, dynamic> planItem;
  Function(int) setCheckPlanId;
  GlobalKey key;
  bool isSyncData;
  Function syncComplete;

  @override
  InspectionPlanScreen(this.context, this.planItem, this.setCheckPlanId,
      this.key, this.isSyncData, this.syncComplete);

  @override
  State<InspectionPlanScreen> createState() => _InspectionPlanScreen(planItem);
}

class _InspectionPlanScreen extends State<InspectionPlanScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  Map<String, dynamic> planItem;
  CheckPlan _inspection;

  String emptyTableName;
  String _tableName;
  List<Map<String, dynamic>> railwayList;
  List<Map<String, dynamic>> stateList;
  List<Map<String, dynamic>> eventList;
  List<Map<String, dynamic>> groupList;
  var _tapPosition;
  bool hasTimeBegin;
  bool hasTimeEnd;
  int eventId;
  String eventName;
  Department department;
  int checkTypeId = 3;
  double widthPlan = 800;
  double heightPlan = 700;

  List<CheckPlanItem> _inspectionItems;

  List<Map<String, dynamic>> inspectionItems = [];
  final formInspectionKey = new GlobalKey<FormState>();
  final formInspectionItemKey = new GlobalKey<FormState>();

  List<Map<String, dynamic>> choices = [
    {'title': "Редактировать запись", 'icon': Icons.edit, 'key': 'edit'},
    {'title': 'Удалить запись', 'icon': Icons.delete, 'key': 'delete'}
  ];

  List<Map<String, dynamic>> choicesWithInspection = [
    {'title': "Редактировать запись", 'icon': Icons.edit, 'key': 'edit'},
    {'title': 'Удалить запись', 'icon': Icons.delete, 'key': 'delete'},
    {'title': 'Начать проверку', 'icon': Icons.flag, 'key': 'forward'}
  ];

  List<Map<String, dynamic>> inspectionItemHeader = [
    {'text': 'Дата проверки', 'flex': 2.0},
    {'text': 'Наименование структурного подразделения', 'flex': 5.0},
    {'text': 'Время проверки (мест. вр)', 'flex': 2.0},
    {'text': 'Члены комиссии', 'flex': 2.0}
  ];

  @override
  _InspectionPlanScreen(this.planItem);

  @override
  void initState() {
    super.initState();
    _tableName = "";
    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          emptyTableName =
              'Для редактирования плана проверок, выберите в меню "Редактировать план"';

          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});
      railwayList = await getRailwayList();
      stateList = makeListFromJson(Plan.stateSelection);
      eventList = makeListFromJson(CheckPlanItem.typeSelection);
      await reloadInspection(planItem['planItemId']);

      //  reloadPlanItems(); //todo убрать отсюда
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
      if (_inspection.id == null) editInspectionClicked();
    }
    if (widget.isSyncData) widget.syncComplete();
  }

  Future<void> reloadInspection(int planItemId) async {
    try {
      _inspection = null;
      List<CheckPlan> insp = await CheckPlanController.select(planItemId);
      if (!insp.isEmpty) _inspection = insp[0];
    } catch (e) {}

    if (_inspection == null)
      _inspection = new CheckPlan(
          id: null,
          odooId: null,
          parentId: planItemId,
          name: '${planItem["typeName"]} ${planItem["filial"]}',
          railwayId: planItem["railwayId"],
          active: true);

    if (_inspection.id != null && !widget.isSyncData)
      widget.setCheckPlanId(_inspection
          .id); //если сохранили план проверок  - передаем в родителя id для комиссии, карты и тд...

    //загружаем пункты плана проверок
    inspectionItems = [];
    _inspectionItems = await _inspection.items;
    //загружаем группы/комиссию
    groupList = [];

    if (_inspection.id != null) {
      for (int i = 0; i < _inspectionItems.length; i++) {
        CheckPlanItem item = _inspectionItems[i];

        String name =
            await depOrEventName(item.type, item.departmentId, item.name);
        inspectionItems.add({'item': item, 'name': name});
      }

      try {
        List<ComGroup> _groupList = await _inspection.allComGroups;
        _groupList.forEach((group) {
          groupList.add({
            'id': group.id.toString(),
            'value': group.isMain ? 'Все члены комиссии' : group.groupNum
          });
        });
      } catch (e) {
        print('allComGroup error: $e');
      }

      if (_inspection.mainComGroupId != null)
        groupList.add({
          'id': _inspection.mainComGroupId.toString(),
          'value': 'Все члены комиссии'
        });
    }

    setState(() => {});
  }

  Future<String> depOrEventName(
      int eventId, int departmentId, String eventName) async {
    if (eventId == checkTypeId && departmentId != null)
      return (await DepartmentController.selectById(departmentId)).name;
    return eventName ??
        (eventId != null ? CheckPlanItem.typeSelection[eventId] : "");
  }

  @override
  Widget build(BuildContext context) {
    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenu(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            editInspectionClicked();
            break;
          case 'add':
            addInspectionItemClicked();
            break;
          case 'pdf':
            exportToPdf();
            return;
          case 'excel':
            exportToExcel();
            return;
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

    String tableName = "";
    if (_inspection != null && _inspection.name != null) {
      tableName = '${_inspection.name}';
    }

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
                          title: Text(tableName, textAlign: TextAlign.center),
                          onTap: () {}),
                      Expanded(
                          child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                            if (_inspection.id != null)
                              Column(children: [
                                generateTableData(context, inspectionItemHeader,
                                    inspectionItems)
                              ])
                          ])),
                    ]))));
  }

  List<PopupMenuEntry<Object>> getMenu(BuildContext context) {
    List<PopupMenuEntry<Object>> result = [];
    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.edit,
            text: "Редактировать план",
            margin: 5.0,
            /* onTap: () */
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'edit'),
    );

    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.add,
            text: "Добавить пункт",
            margin: 5.0,
            /* onTap: () ,*/
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'add'),
    );

    result.add(PopupMenuDivider(
      height: 20,
    ));

    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icon(FontAwesome5.file_pdf).icon, //Icons.edit,
            text: "Экспорт в PDF",
            margin: 5.0,
            /* onTap: () */
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'pdf'),
    );

    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icon(FontAwesome5.file_excel).icon,
            text: "Экспорт в Excel",
            margin: 5.0,
            /* onTap: () */
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'excel'),
    );
    return result;
  }

  Widget generateTableData(BuildContext context,
      List<Map<String, dynamic>> headers, List<Map<String, dynamic>> rows) {
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
      CheckPlanItem item = row["item"] as CheckPlanItem;
      TableRow tableRow = TableRow(
          decoration: BoxDecoration(
              color: (rowIndex % 2 == 0
                  ? Theme.of(context).shadowColor
                  : Colors.white)),
          children: [
            getRowCell(
                dateDMY(item.date), item.id, 0, item.type, item.departmentId,
                textAlign: TextAlign.center),
            getRowCell(row['name'], item.id, 1, item.type, item.departmentId),
            getRowCell(getTimePeriod(item.dtFrom, item.dtTo), item.id, 2,
                item.type, item.departmentId,
                textAlign: TextAlign.center),
            getRowCell(getGroupById(item.comGroupId), item.id, 4, item.type,
                item.departmentId,
                textAlign: TextAlign.center, groupId: item.comGroupId),
          ]);
      tableRows.add(tableRow);
    });

    return Table(
        border: TableBorder.all(),
        columnWidths: columnWidths,
        children: tableRows);
  }

  Widget getRowCell(String text, int inspectionItemId, int index, int eventId,
      int departmentId,
      {TextAlign textAlign = TextAlign.left, int groupId}) {
    Widget cell = Container(
      padding: EdgeInsets.all(10.0),
      child: Text(
        text ?? "",
        textAlign: textAlign,
      ),
    );

    return GestureDetector(
        onTapDown: _storePosition,
        onTap: () async {
          if (index == 4) return showGroupInfo(groupId);
        },
        onLongPress: () {
          _showCustomMenu(inspectionItemId, index, eventId, departmentId);
        },
        child: cell);
  }

  Future<void> showGroupInfo(int groupId) async {
    ComGroup group = await ComGroupController.selectById(groupId);
    List<User> users = await group.comUsers;
    User head = await group.head;
    int headId = group.headId;

    List<User> userToDisplay = [];
    if (head != null) userToDisplay.add(head);
    userToDisplay.addAll(users.where((user) => user.id != headId));

    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
        context: context,
        position: RelativeRect.fromRect(
            _tapPosition & const Size(1, 1), Offset.zero & overlay.size),
        items: <PopupMenuEntry<Object>>[
          CustomToolTip(
            context: context,
            content: Container(
              width: 250,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: userToDisplay
                    .map((User user) => (user.id == headId)
                        ? Row(children: [
                            Icon(Icons.star),
                            Text(user.display_name)
                          ])
                        : Text(user.display_name))
                    .toList(),
              ),
            ),
          )
        ]);
  }

  String getTimePeriod(DateTime dtBegin, DateTime dtEnd) {
    if (dtBegin != null) {
      if (dtEnd != null) {
        if (isDateEqual(dtBegin, dtEnd))
          return '${dateHm(dtBegin)} - ${dateHm(dtEnd)}';
        return '${dateDMY(dtBegin)} ${dateHm(dtBegin)} - ${dateDMY(dtEnd)} ${dateHm(dtEnd)}';
      }
      return dateHm(dtBegin);
    }
    return '';
  }

  String getGroupById(int groupId) {
    if (groupId == null || groupList.length == 0) return '';
    Map<String, dynamic> group = groupList.firstWhere(
        (group) => group["id"] == groupId.toString(),
        orElse: () => null);
    return group != null ? group['value'] : '';
  }

  void _showCustomMenu(
      int inspectionItemId, int index, int eventId, int departmentId) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
        context: context,
        position: RelativeRect.fromRect(
            _tapPosition & const Size(1, 1), Offset.zero & overlay.size),
        items: <PopupMenuEntry<Map<String, dynamic>>>[
          CustomPopMenu(
            context: context,
            choices: (eventId == checkTypeId && departmentId != null)
                ? choicesWithInspection
                : choices,
          )
        ]).then<void>((Map<String, dynamic> choice) {
      if (choice == null) return;
      switch (choice["key"]) {
        case 'edit':
          editInspectionItem(inspectionItemId);
          break;
        case 'delete':
          deleteInspectionItem(inspectionItemId);
          break;
        case 'forward':
          forwardCheckItem(inspectionItemId);
          break;
      }
    });
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  Future<bool> showInspectionDialog(CheckPlan inspection) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return /*AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
                backgroundColor: Theme.of(context).primaryColor,
                content: SizedBox(*/
                Stack(alignment: Alignment.center, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/app.jpg",
                  fit: BoxFit.fill,
                  height: heightPlan,
                  width: widthPlan,
                ),
              ),
              Container(
                  width: widthPlan - 100,
                  //  height: heightPlan - 100,
                  margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                  child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Form(
                          key: formInspectionKey,
                          child: Container(
                              child: Column(children: [
                            FormTitle('Реквизиты плана проверок'),
                            Expanded(
                                child: Center(
                                    child:
                                        ListView(shrinkWrap: true, children: [
                              Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    EditTextField(
                                      text: 'Наименование',
                                      value: inspection.name,
                                      onSaved: (value) =>
                                          {inspection.name = value},
                                      context: context,
                                      height: 100,
                                      // maxLines: 5,
                                    ),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        children: [
                                          Container(
                                              width: 200,
                                              margin: EdgeInsets.only(left: 15),
                                              child: MyDropdown(
                                                text: 'Состояние',
                                                dropdownValue: inspection.state,
                                                items: stateList,
                                                onChange: (value) {
                                                  inspection.state = value;
                                                },
                                                parentContext: context,
                                              )),
                                          Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 13),
                                              child: DatePicker(
                                                  parentContext: context,
                                                  text: "Дата начала",
                                                  width: 150,
                                                  selectedDate:
                                                      inspection.dateFrom ??
                                                          DateTime.now(),
                                                  onChanged: ((DateTime date) {
                                                    //   setState(() {
                                                    inspection.dateFrom = date;
                                                    //  });
                                                  }))),
                                          Container(
                                              padding:
                                                  EdgeInsets.only(right: 13),
                                              child: DatePicker(
                                                  parentContext: context,
                                                  text: "Дата окончания",
                                                  width: 150,
                                                  selectedDate:
                                                      inspection.dateTo ??
                                                          DateTime.now(),
                                                  onChanged: ((DateTime date) {
                                                    //   setState(() {
                                                    inspection.dateTo = date;
                                                    //  });
                                                  })))
                                        ]),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        children: [
                                          Container(
                                              width: 450,
                                              child: EditTextField(
                                                text: 'Номер',
                                                value: inspection.numSet,
                                                onSaved: (value) =>
                                                    {inspection.numSet = value},
                                                context: context,
                                              )),
                                          Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 13),
                                              child: DatePicker(
                                                  parentContext: context,
                                                  text: "Дата утверждения",
                                                  width: 150,
                                                  selectedDate:
                                                      inspection.dateSet ??
                                                          DateTime.now(),
                                                  onChanged: ((DateTime date) {
                                                    //   setState(() {
                                                    inspection.dateSet = date;
                                                    //  });
                                                  })))
                                        ]),
                                    Row(children: [
                                      Expanded(
                                          child: EditTextField(
                                        text: 'Подписант, ФИО',
                                        value: inspection.signerName,
                                        onSaved: (value) =>
                                            {inspection.signerName = value},
                                        context: context,
                                      )),
                                      Expanded(
                                          child: EditTextField(
                                        text: 'Подписант, должность',
                                        value: inspection.signerPost,
                                        onSaved: (value) =>
                                            {inspection.signerPost = value},
                                        context: context,
                                      ))
                                    ]),
                                    Row(children: [
                                      Expanded(
                                          child: EditTextField(
                                        text: 'Утвержден, ФИО',
                                        value: inspection.appName,
                                        onSaved: (value) =>
                                            {inspection.appName = value},
                                        context: context,
                                      )),
                                      Expanded(
                                          child: EditTextField(
                                        text: 'Утвержден, должность',
                                        value: inspection.appPost,
                                        onSaved: (value) =>
                                            {inspection.appPost = value},
                                        context: context,
                                      ))
                                    ]),
                                  ])
                            ]))),
                            Container(
                                child: Column(children: [
                              MyButton(
                                  text: 'принять',
                                  parentContext: context,
                                  onPress: () {
                                    submitInspection(inspection, setState);
                                  }),
                            ]))
                          ])))))
            ]);
          });
        });
  }

  Future<bool> showInspectionItemDialog(
      CheckPlanItem inspectionItem, setState) async {
    Department tempDepartment = inspectionItem.departmentId != null
        ? await DepartmentController.selectById(inspectionItem.departmentId)
        : null;
    setState(() {
      hasTimeBegin = inspectionItem.dtFrom != null;
      hasTimeEnd = inspectionItem.dtTo != null;

      DateTime now = DateTime.now();
      DateTime dtFrom = inspectionItem.date ?? now;
      if (!hasTimeBegin)
        inspectionItem.dtFrom = DateTime(dtFrom.year, dtFrom.month, dtFrom.day,
            now.hour, now.minute, now.second);
      if (!hasTimeEnd) inspectionItem.dtTo = now;

      eventId = inspectionItem.type ?? null;
      eventName = inspectionItem.name ?? "";
      department = tempDepartment;
    });

    final TextStyle enableText =
        TextStyle(fontSize: 16.0, color: Theme.of(context).buttonColor);
    final TextStyle disableText =
        TextStyle(fontSize: 16.0, color: Color(0xAA6E6E6E));
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
                content: */
                Stack(alignment: Alignment.center, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/app.jpg",
                  fit: BoxFit.fill,
                  height: heightPlan,
                  width: widthPlan,
                ),
              ),
              Container(
                  width: widthPlan,
                  margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 40),
                  child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Form(
                          key: formInspectionItemKey,
                          child: Container(
                              child: Column(children: [
                            FormTitle(
                                '${inspectionItem.id == null ? 'Добавление' : 'Редактирование'} пункта плана проверок'),
                            Expanded(
                                child: Center(
                                    // height: heightPlan,
                                    child: SingleChildScrollView(
                                        child: Row(children: [
                              Expanded(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                              padding:
                                                  EdgeInsets.only(right: 20),
                                              child: MyDropdown(
                                                text: 'Тип события',
                                                dropdownValue:
                                                    inspectionItem.type != null
                                                        ? inspectionItem.type
                                                            .toString()
                                                        : checkTypeId
                                                            .toString(),
                                                items: eventList,
                                                onChange: (value) {
                                                  inspectionItem.type =
                                                      int.tryParse(value);
                                                  setState(() {
                                                    eventId =
                                                        int.tryParse(value);
                                                    if (eventId !=
                                                        checkTypeId) if (eventId < 100)
                                                      eventName = CheckPlanItem
                                                              .typeSelection[
                                                          eventId];
                                                    else
                                                      eventName = "";
                                                    inspectionItem.name =
                                                        eventName;
                                                  });
                                                },
                                                parentContext: context,
                                              )),
                                        ),
                                        Expanded(
                                          child: Container(
                                              child: MyDropdown(
                                            text: 'Члены комиссии',
                                            dropdownValue:
                                                inspectionItem.comGroupId !=
                                                        null
                                                    ? inspectionItem.comGroupId
                                                        .toString()
                                                    : null,
                                            items: groupList,
                                            onChange: (value) {
                                              setState(() {
                                                inspectionItem.comGroupId =
                                                    int.tryParse(value);
                                              });
                                            },
                                            parentContext: context,
                                          )),
                                        )
                                      ],
                                    ),
                                    Container(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            if (eventId != null &&
                                                    eventId == checkTypeId ||
                                                eventId == null)
                                              ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                      maxWidth: widthPlan,
                                                      minHeight: 60),
                                                  child: DepartmentSelect(
                                                      text:
                                                          "Структурное подразделение",
                                                      width: widthPlan,
                                                      height: 150,
                                                      margin: 0,
                                                      department: department,
                                                      railwayId:
                                                          planItem["railwayId"],
                                                      context: context,
                                                      onSaved: (newDepartment) {
                                                        if (newDepartment ==
                                                            null) return;
                                                        setState(() {
                                                          inspectionItem
                                                                  .departmentId =
                                                              newDepartment.id;
                                                          department =
                                                              newDepartment;
                                                        });
                                                      })),
                                            if (eventId != null &&
                                                eventId != checkTypeId)
                                              ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                      maxWidth: widthPlan,
                                                      minHeight: 60),
                                                  child: EditTextField(
                                                    text: 'Описание',
                                                    value: eventName,
                                                    onSaved: (value) {
                                                      eventName = value;
                                                      inspectionItem.name =
                                                          value;
                                                    },
                                                    context: context,
                                                    height: 150,
                                                    margin: 0,
                                                  )),
                                          ],
                                        )),
                                    Row(children: [
                                      Expanded(
                                          child: Container(
                                              padding:
                                                  EdgeInsets.only(right: 20),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 6),
                                                        child: Text(
                                                          'Дата проверки',
                                                          textAlign:
                                                              TextAlign.left,
                                                          style: enableText,
                                                        )),
                                                    DatePicker(
                                                        parentContext: context,
                                                        text: "",
                                                        width: double.infinity,
                                                        // width: 200,
                                                        selectedDate:
                                                            inspectionItem
                                                                    .date ??
                                                                DateTime.now(),
                                                        onChanged:
                                                            ((DateTime date) {
                                                          setState(() {
                                                            inspectionItem
                                                                .date = date;
                                                            DateTime _dtFrom =
                                                                new DateTime(
                                                                    date.year,
                                                                    date.month,
                                                                    date.day,
                                                                    inspectionItem
                                                                        .dtFrom
                                                                        .hour,
                                                                    inspectionItem
                                                                        .dtFrom
                                                                        .minute,
                                                                    inspectionItem
                                                                        .dtFrom
                                                                        .second);
                                                            inspectionItem
                                                                    .dtFrom =
                                                                _dtFrom;
                                                          });
                                                        })),
                                                  ]))),
                                      Expanded(
                                          child: Container(
                                              // width: 200,
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                            Container(
                                                padding:
                                                    EdgeInsets.only(bottom: 2),
                                                child: Row(children: [
                                                  SizedBox(
                                                      height: 24,
                                                      width: 24,
                                                      child: Checkbox(
                                                        value: hasTimeBegin ??
                                                            false,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            hasTimeBegin =
                                                                value;
                                                            //if (value && inspectionItem.dtFrom == null) inspectionItem.dtFrom = DateTime.now();
                                                            // if (!value) inspectionItem.dtFrom = null;
                                                          });
                                                        },
                                                        checkColor:
                                                            Theme.of(context)
                                                                .primaryColor,
                                                      )),
                                                  GestureDetector(
                                                      child: Text(
                                                        'Время',
                                                        style: hasTimeBegin
                                                            ? enableText
                                                            : disableText,
                                                        textAlign:
                                                            TextAlign.left,
                                                      ),
                                                      onTap: () {
                                                        setState(() {
                                                          hasTimeBegin =
                                                              !hasTimeBegin;
                                                        });
                                                      })
                                                ])),
                                            TimePicker(
                                              width: double.infinity,
                                              time: inspectionItem.dtFrom ??
                                                  DateTime.now(),
                                              enable: hasTimeBegin,
                                              minutesInterval: 1,
                                              spacing: 50,
                                              itemHeight: 80,
                                              context: context,
                                              onTimeChange: (time) {
                                                inspectionItem.dtFrom = time;
                                              },
                                            )
                                          ]))),
                                    ]),
                                    Row(children: [
                                      Expanded(
                                          child: Container(
                                              width: double.infinity,
                                              // width: 200,
                                              padding:
                                                  EdgeInsets.only(right: 20),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 2,
                                                                top: 13),
                                                        child: Row(children: [
                                                          SizedBox(
                                                              height: 24,
                                                              width: 24,
                                                              child: Checkbox(
                                                                value:
                                                                    hasTimeEnd ??
                                                                        false,
                                                                onChanged:
                                                                    (value) {
                                                                  setState(() {
                                                                    hasTimeEnd =
                                                                        value;
                                                                    //if (value && inspectionItem.dtTo == null) inspectionItem.dtTo = DateTime.now();
                                                                    //if (!value) inspectionItem.dtTo = null;
                                                                  });
                                                                },
                                                                checkColor: Theme.of(
                                                                        context)
                                                                    .primaryColor,
                                                              )),
                                                          GestureDetector(
                                                              child: Text(
                                                                'Дата окончания',
                                                                style: hasTimeEnd
                                                                    ? enableText
                                                                    : disableText,
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                              ),
                                                              onTap: () {
                                                                setState(() {
                                                                  hasTimeEnd =
                                                                      !hasTimeEnd;
                                                                });
                                                              })
                                                        ])),
                                                    DatePicker(
                                                        parentContext: context,
                                                        text: "",
                                                        //  width: 200,
                                                        width: double.infinity,
                                                        enable: hasTimeEnd,
                                                        selectedDate:
                                                            inspectionItem
                                                                    .dtTo ??
                                                                DateTime.now(),
                                                        onChanged:
                                                            ((DateTime date) {
                                                          setState(() {
                                                            DateTime _dtTo =
                                                                new DateTime(
                                                                    date.year,
                                                                    date.month,
                                                                    date.day,
                                                                    inspectionItem
                                                                        .dtTo
                                                                        .hour,
                                                                    inspectionItem
                                                                        .dtTo
                                                                        .minute,
                                                                    inspectionItem
                                                                        .dtTo
                                                                        .second);
                                                            inspectionItem
                                                                .dtTo = _dtTo;
                                                          });
                                                        })),
                                                  ]))),
                                      Expanded(
                                          child: Container(
                                              //  width: 200,
                                              width: double.infinity,
                                              padding: EdgeInsets.only(top: 15),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                        padding: EdgeInsets.only(
                                                            bottom:
                                                                6), //2 c checkbox
                                                        child: Row(children: [
                                                          if (false)
                                                            SizedBox(
                                                                height: 24,
                                                                width: 24,
                                                                child: Checkbox(
                                                                  value:
                                                                      hasTimeEnd ??
                                                                          false,
                                                                  onChanged:
                                                                      (value) {
                                                                    setState(
                                                                        () {
                                                                      hasTimeEnd =
                                                                          value;
                                                                    });
                                                                  },
                                                                  checkColor: Theme.of(
                                                                          context)
                                                                      .primaryColor,
                                                                )),
                                                          GestureDetector(
                                                              child: Text(
                                                                'Время',
                                                                style: hasTimeEnd
                                                                    ? enableText
                                                                    : disableText,
                                                                textAlign:
                                                                    TextAlign
                                                                        .left,
                                                              ),
                                                              onTap: () {
                                                                setState(() {
                                                                  hasTimeEnd =
                                                                      !hasTimeEnd;
                                                                });
                                                              })
                                                        ])),
                                                    TimePicker(
                                                      width: double.infinity,
                                                      time: inspectionItem.dtTo,
                                                      enable: hasTimeEnd,
                                                      minutesInterval: 1,
                                                      spacing: 50,
                                                      itemHeight: 80,
                                                      context: context,
                                                      onTimeChange: (time) {
                                                        inspectionItem.dtTo =
                                                            time;
                                                      },
                                                    )
                                                  ]))),
                                    ]),
                                  ])),
                            ])))),
                            Container(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                  MyButton(
                                      text: 'принять',
                                      parentContext: context,
                                      onPress: () => submitInspectionItem(
                                          inspectionItem,
                                          setState,
                                          hasTimeBegin,
                                          hasTimeEnd)),
                                  MyButton(
                                      text: 'отменить',
                                      parentContext: context,
                                      onPress: () {
                                        cancelInspectionItem();
                                      }),
                                ]))
                          ])))))
            ]);
          });
        });
  }

  Future<void> editInspectionClicked() async {
    CheckPlan inspectionCopy = new CheckPlan(
        id: _inspection.id,
        odooId: _inspection.odooId,
        parentId: _inspection.parentId,
        name: _inspection.name,
        signerName: _inspection.signerName,
        signerPost: _inspection.signerPost,
        appName: _inspection.appName,
        appPost: _inspection.appPost,
        numSet: _inspection.numSet,
        dateSet: _inspection.dateSet ?? DateTime.now(),
        active: _inspection.active,
        state: _inspection.state,
        dateFrom: _inspection.dateFrom ?? DateTime.now(),
        dateTo: _inspection.dateTo ?? DateTime.now());
    setState(() {});
    bool result = await showInspectionDialog(inspectionCopy);
    if (result != null && result) //иначе перезагружать _plan?
    {}
  }

  Future<void> submitInspection(CheckPlan inspectionCopy, setState) async {
    final form = formInspectionKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool hasErorr = false;
      Map<String, dynamic> result;

      try {
        if (inspectionCopy.id == null) {
          result = await CheckPlanController.insert(inspectionCopy);
        } else {
          result = await CheckPlanController.update(inspectionCopy);
        }
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          Navigator.pop<bool>(context, false);
          Scaffold.of(context).showSnackBar(errorSnackBar());
        } else {
          if (inspectionCopy.id == null) inspectionCopy.id = result["id"];
          setState(() {
            _inspection = inspectionCopy;
            widget.setCheckPlanId(_inspection.id);
            reloadInspection(_inspection.parentId);
          });

          Navigator.pop<bool>(context, true);
          Scaffold.of(context).showSnackBar(successSnackBar);
        }
      } catch (e) {
        Navigator.pop<bool>(context, false);
        Scaffold.of(context).showSnackBar(errorSnackBar());
      }
    }
  }

  Future<void> cancelInspectionItem() async {
    Navigator.pop<bool>(context, null);
  }

  Future<void> submitInspectionItem(CheckPlanItem inspectionItem, setState,
      bool hasTimeBegin, bool hasTimeEnd) async {
    final form = formInspectionItemKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool hasErorr = false;
      Map<String, dynamic> result;

      if (!hasTimeBegin) inspectionItem.dtFrom = null;
      if (!hasTimeEnd) inspectionItem.dtTo = null;

      if (inspectionItem.type != checkTypeId)
        inspectionItem.departmentId = null;
      /* CheckPlanItem inspectionItemCopy =
          CheckPlanItem.fromJson(inspectionItem.toJson());
      inspectionItemCopy.date = inspectionItemCopy.date?.toUtc();
      inspectionItemCopy.dtFrom = inspectionItemCopy.dtFrom?.toUtc();
      inspectionItemCopy.dtTo = inspectionItemCopy.dtTo?.toUtc();*/

      try {
        if (inspectionItem.id == null) {
          result = await CheckPlanItemController.insert(inspectionItem);
        } else {
          result = await CheckPlanItemController.update(inspectionItem);
        }
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          Navigator.pop<bool>(context, false);
          Scaffold.of(context).showSnackBar(errorSnackBar());
        } else {
          if (inspectionItem.id == null) {
            inspectionItem.id = result["id"];
            Map<String, dynamic> newValue = {
              'item': inspectionItem,
              'name': await depOrEventName(inspectionItem.type,
                  inspectionItem.departmentId, inspectionItem.name)
            };
            setState(() {
              inspectionItems.add(newValue);
            });
          } else {
            Map<String, dynamic> newValue = {
              'item': inspectionItem,
              'name': await depOrEventName(inspectionItem.type,
                  inspectionItem.departmentId, inspectionItem.name)
            };

            setState(() {
              int index = inspectionItems.indexWhere((item) =>
                  (item["item"] as CheckPlanItem).id == inspectionItem.id);
              inspectionItems[index] = newValue;
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

  Future<void> editInspectionItem(int inspectionItemId) async {
    CheckPlanItem inspectionItem = (inspectionItems.firstWhere((item) =>
            (item["item"] as CheckPlanItem).id == inspectionItemId))["item"]
        as CheckPlanItem;
    CheckPlanItem inspectionItemCopy = new CheckPlanItem(
        id: inspectionItem.id,
        odooId: inspectionItem.odooId,
        parentId: inspectionItem.parentId,
        departmentId: inspectionItem.departmentId,
        type: inspectionItem.type,
        name: inspectionItem.name,
        date: inspectionItem.date,
        dtFrom: inspectionItem.dtFrom,
        dtTo: inspectionItem.dtTo,
        comGroupId: inspectionItem.comGroupId,
        active: inspectionItem.active);
    bool result = await showInspectionItemDialog(inspectionItemCopy, setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<void> deleteInspectionItem(int inspectionItemId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить пункт плана проверок?', context);
    if (result != null && result) {
      Map<String, dynamic> deletedInspectionItem = inspectionItems.firstWhere(
          (item) => (item["item"] as CheckPlanItem).id == inspectionItemId);

      if (deletedInspectionItem == null) return;

      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        result = await CheckPlanItemController.delete(inspectionItemId);
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          Scaffold.of(context).showSnackBar(
              errorSnackBar(text: 'Произошла ошибка при удалении'));
          return;
        }
        inspectionItems.remove(deletedInspectionItem);
        setState(() {});
      } catch (e) {
        Scaffold.of(context)
            .showSnackBar(errorSnackBar(text: 'Произошла ошибка при удалении'));
      }
    }
  }

  Future<void> addInspectionItemClicked() async {
    if (_inspection.id == null) {
      Scaffold.of(context).showSnackBar(
          errorSnackBar(text: 'Сначала сохраните реквизиты плана проверок'));
      return;
    }
    CheckPlanItem inspectionItem = new CheckPlanItem(
        id: null,
        odooId: null,
        type: checkTypeId,
        parentId: _inspection.id,
        date: DateTime.now(),
        active: true);
    bool result = await showInspectionItemDialog(inspectionItem, setState);
    if (result != null && result) {
      setState(() {});
    }
  }

  Future<void> exportToPdf() async {
    if (_inspection.id == null) {
      Scaffold.of(context).showSnackBar(
          errorSnackBar(text: 'Сначала сохраните реквизиты плана проверок'));
      return;
    }
    try {
      showLoadingDialog(context);

      File file = await _inspection.pdfReport;
      hideDialog(context);
      if (file != null) {
        OpenFile.open(file.path);
      }
    } catch (e) {
      hideDialog(context);
    }
  }

  Future<void> exportToExcel() async {
    if (_inspection.id == null) {
      Scaffold.of(context).showSnackBar(
          errorSnackBar(text: 'Сначала сохраните реквизиты плана проверок'));
      return;
    }
    try {
      showLoadingDialog(context);
      File file = await _inspection.xlsReport;
      hideDialog(context);
      if (file != null) {
        OpenFile.open(file.path);
      }
    } catch (e) {
      hideDialog(context);
    }
  }

  Future<void> forwardCheckItem(int inspectionItemId) async {
    CheckPlanItem inspectionItem = (inspectionItems.firstWhere((item) =>
            (item["item"] as CheckPlanItem).id == inspectionItemId))["item"]
        as CheckPlanItem;
    Map<String, dynamic> args = {
      'id': inspectionItem.id,
      'department_id': inspectionItem.departmentId,
      // 'filial': planItem.filial,
      // 'typeName': getTypeInspectionById(planItem.typeId)["value"],
      // 'railwayId': _railway_id,
      // 'typePlan': _type,
      // 'year': _year
    };
    Navigator.pushNamed(context, '/checkItem', arguments: args);
  }
}
