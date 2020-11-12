import 'package:ek_asu_opb_mobile/controllers/controllers.dart' as controllers;
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/utils/dictionary.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:workmanager/workmanager.dart';

class InspectionItem {
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

//todo delete
class InspectionPlanScreen extends StatefulWidget {
  BuildContext context;
  Map<String, dynamic> planItem;
  Function(int) setCheckPlanId;

  @override
  InspectionPlanScreen(this.context, this.planItem, this.setCheckPlanId);

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

  List<InspectionItem> _inspectionItems = <InspectionItem>[
    InspectionItem(
        id: 1,
        odooId: 1,
        inspectionId: 1,
        departmentId: null,
        eventId: 2,
        eventName: 'Встреча членов комиссии. Размещение в гостинице',
        date: DateTime(2020, 5, 19),
        timeBegin: null,
        timeEnd: null,
        groupId: null),
    InspectionItem(
        id: 2,
         odooId: 2,
        inspectionId: 1,
        departmentId: null,
        eventId: 2,
        eventName: 'Встреча c руководством Оренбургского региона',
        date: DateTime(2020, 5, 20),
        timeBegin: DateTime(2020, 5, 20, 8, 0),
        timeEnd: DateTime(2020, 5, 20, 8, 30),
        groupId: 1),
    InspectionItem(
        id: 3,
         odooId: 3,
        inspectionId: 1,
        departmentId: 32229,
        eventId: 1,
        eventName: null,
        date: DateTime(2020, 5, 20),
        timeBegin: DateTime(2020, 5, 20, 8, 30),
        timeEnd: DateTime(2020, 5, 20, 12, 30),
        groupId: 2),
  ];
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

  //todo delete
  List<Map<String, dynamic>> _groupList = [
    {
      'id': 1,
      'value': 'Все члены комисии',
    },
    {
      'id': 2,
      'value': 'Группа 1',
    }
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
              'Для редактирования плана проверок, выберите в меню редактировать план...';

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
      eventList = getEventInspectionList();
      await reloadInspection(planItem['planItemId']);

      //  reloadPlanItems(); //todo убрать отсюда
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
      if (_inspection.id == null) editInspectionClicked();
    }
  }

  Future<void> reloadInspection(int planItemId) async {
    /* try {
      _inspection =
          await controllers.InspectionController.select(planItemId);
    } catch (e) {}*/

    if (_inspection == null)
      _inspection = new CheckPlan(
          id: 1, // todo вернуть на null!!!!!
          parentId: planItemId,
          name: '${planItem["typeName"]} ${planItem["filial"]}',
          railwayId: planItem["railwayId"],
          active: true);

    if (_inspection.id != null) widget.setCheckPlanId(_inspection.id);

    await reloadInspectionItems(_inspection.id);
    await reloadGroups(_inspection.id);

    setState(() => {});
  }

  Future<void> reloadInspectionItems(int inspectionId) async {
    inspectionItems = [];
    if (inspectionId != null) {
      //todo потом проверять planId <> null
      //_inspectionItems; //получать из базы
      for (int i = 0; i < _inspectionItems.length; i++) {
        InspectionItem item = _inspectionItems[i];
        String name = await depOrEventName(
            item.eventId, item.departmentId, item.eventName);
        inspectionItems.add({'item': item, 'name': name});
      }
    }
  }

  Future<void> reloadGroups(int inspectionId) async {
    if (inspectionId != null) //todo потом проверять planId <> null
      groupList = _groupList; //получать из базы
    else
      groupList = [];
  }

  Future<String> depOrEventName(
      int eventId, int departmentId, String eventName) async {
    if (departmentId != null)
      return (await controllers.Department.selectById(departmentId)).name;
    return eventName ?? "";
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
                    fit: BoxFit.fitWidth)),
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

  List<PopupMenuItem<String>> getMenu(BuildContext context) {
    List<PopupMenuItem<String>> result = [];
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
      InspectionItem item = row["item"] as InspectionItem;
      TableRow tableRow = TableRow(
          decoration: BoxDecoration(
              color: (rowIndex % 2 == 0
                  ? Theme.of(context).shadowColor
                  : Colors.white)),
          children: [
            getRowCell(
                dateDMY(item.date), item.id, 0, item.eventId, item.departmentId,
                textAlign: TextAlign.center),
            getRowCell(
                row['name'], item.id, 1, item.eventId, item.departmentId),
            getRowCell(getTimePeriod(item.timeBegin, item.timeEnd), item.id, 2,
                item.eventId, item.departmentId,
                textAlign: TextAlign.center),
            getRowCell(getGroupById(item.groupId), item.id, 4, item.eventId,
                item.departmentId,
                textAlign: TextAlign.center),
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
          _showCustomMenu(inspectionItemId, index, eventId, departmentId);
        },
        child: cell);
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
    Map<String, dynamic> group = groupList
        .firstWhere((group) => group["id"] == groupId, orElse: () => null);
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
            choices: (eventId == 1 && departmentId != null)
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
                        body: Form(
                            key: formInspectionKey,
                            child: Container(
                                child: Column(children: [
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
                                        maxLines: 5,
                                      ),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          children: [
                                            Container(
                                                width: 200,
                                                margin:
                                                    EdgeInsets.only(left: 15),
                                                child: MyDropdown(
                                                  text: 'Состояние',
                                                  dropdownValue:
                                                      inspection.state,
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
                                                    onChanged:
                                                        ((DateTime date) {
                                                      //   setState(() {
                                                      inspection.dateFrom =
                                                          date;
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
                                                    onChanged:
                                                        ((DateTime date) {
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
                                                  onSaved: (value) => {
                                                    inspection.numSet = value
                                                  },
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
                                                    onChanged:
                                                        ((DateTime date) {
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
                            ]))))));
          });
        });
  }

  Future<bool> showInspectionItemDialog(
      InspectionItem inspectionItem, setState) async {
    Department tempDepartment = inspectionItem.departmentId != null
        ? await controllers.Department.selectById(inspectionItem.departmentId)
        : null;
    setState(() {
      hasTimeBegin = inspectionItem.timeBegin != null;
      hasTimeEnd = inspectionItem.timeEnd != null;
      eventId = inspectionItem.eventId ?? null;
      eventName = inspectionItem.eventName ?? "";
      department = tempDepartment;
    });

    int checkTypeId = 1;
    double widthDepartment = 500;
    final TextStyle enableText =
        TextStyle(fontSize: 16.0, color: Theme.of(context).buttonColor);
    final TextStyle disableText =
        TextStyle(fontSize: 16.0, color: Color(0xAA6E6E6E));
    return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
                backgroundColor: Theme.of(context).primaryColor,
                content: Container(
                    width: widthDepartment * 2 + 50,
                    child: Scaffold(
                        backgroundColor: Theme.of(context).primaryColor,
                        body: Form(
                            key: formInspectionItemKey,
                            child: Container(
                                child: Column(children: [
                              Expanded(
                                  child: Center(
                                      child: SingleChildScrollView(
                                          child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                    Expanded(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                  width: 450,
                                                  padding: EdgeInsets.only(
                                                      bottom: 10),
                                                  child: MyDropdown(
                                                    text: 'Тип события',
                                                    dropdownValue:
                                                        inspectionItem
                                                                    .eventId !=
                                                                null
                                                            ? inspectionItem
                                                                .eventId
                                                                .toString()
                                                            : null,
                                                    items: eventList,
                                                    onChange: (value) {
                                                      inspectionItem.eventId =
                                                          int.tryParse(value);
                                                      setState(() {
                                                        eventId =
                                                            int.tryParse(value);
                                                        if (eventId >
                                                            checkTypeId) if (eventId < 100)
                                                          eventName =
                                                              getEventInspectionById(
                                                                      eventId)[
                                                                  "value"];
                                                        else
                                                          eventName = "";
                                                        inspectionItem
                                                                .eventName =
                                                            eventName;
                                                      });
                                                    },
                                                    parentContext: context,
                                                  )),
                                            ],
                                          ),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 13),
                                                    child: Container(
                                                        width: 200,
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              6),
                                                                  child: Text(
                                                                    'Дата проверки',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .left,
                                                                    style:
                                                                        enableText,
                                                                  )),
                                                              DatePicker(
                                                                  parentContext:
                                                                      context,
                                                                  text: "",
                                                                  width: 200,
                                                                  selectedDate: inspectionItem
                                                                          .date ??
                                                                      DateTime
                                                                          .now(),
                                                                  onChanged:
                                                                      ((DateTime
                                                                          date) {
                                                                    // setState(() {
                                                                    inspectionItem
                                                                            .date =
                                                                        date;
                                                                    // });
                                                                  })),
                                                            ]))),
                                                Container(
                                                    child: Container(
                                                        width: 200,
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              2),
                                                                  child: Row(
                                                                      children: [
                                                                        SizedBox(
                                                                            height:
                                                                                24,
                                                                            width:
                                                                                24,
                                                                            child:
                                                                                Checkbox(
                                                                              value: hasTimeBegin ?? false,
                                                                              onChanged: (value) {
                                                                                setState(() {
                                                                                  hasTimeBegin = value;
                                                                                  if (value && inspectionItem.timeBegin == null) inspectionItem.timeBegin = DateTime.now();
                                                                                  if (!value) inspectionItem.timeBegin = null;
                                                                                });
                                                                              },
                                                                              checkColor: Theme.of(context).primaryColor,
                                                                            )),
                                                                        GestureDetector(
                                                                            child:
                                                                                Text(
                                                                              'Время',
                                                                              style: hasTimeBegin ? enableText : disableText,
                                                                              textAlign: TextAlign.left,
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                hasTimeBegin = !hasTimeBegin;
                                                                              });
                                                                            })
                                                                      ])),
                                                              TimePicker(
                                                                time: inspectionItem
                                                                        .timeBegin ??
                                                                    DateTime
                                                                        .now(),
                                                                enable:
                                                                    hasTimeBegin,
                                                                minutesInterval:
                                                                    1,
                                                                spacing: 50,
                                                                itemHeight: 80,
                                                                context:
                                                                    context,
                                                                onTimeChange:
                                                                    (time) {
                                                                  inspectionItem
                                                                          .timeBegin =
                                                                      time;
                                                                },
                                                              )
                                                            ]))),
                                              ]),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 13),
                                                    child: Container(
                                                        width: 200,
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              2,
                                                                          top:
                                                                              13),
                                                                  child: Row(
                                                                      children: [
                                                                        SizedBox(
                                                                            height:
                                                                                24,
                                                                            width:
                                                                                24,
                                                                            child:
                                                                                Checkbox(
                                                                              value: hasTimeEnd ?? false,
                                                                              onChanged: (value) {
                                                                                setState(() {
                                                                                  hasTimeEnd = value;
                                                                                  if (value && inspectionItem.timeEnd == null) inspectionItem.timeEnd = DateTime.now();
                                                                                  if (!value) inspectionItem.timeEnd = null;
                                                                                });
                                                                              },
                                                                              checkColor: Theme.of(context).primaryColor,
                                                                            )),
                                                                        GestureDetector(
                                                                            child:
                                                                                Text(
                                                                              'Дата окончания',
                                                                              style: hasTimeEnd ? enableText : disableText,
                                                                              textAlign: TextAlign.left,
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                hasTimeEnd = !hasTimeEnd;
                                                                              });
                                                                            })
                                                                      ])),
                                                              DatePicker(
                                                                  parentContext:
                                                                      context,
                                                                  text: "",
                                                                  width: 200,
                                                                  enable:
                                                                      hasTimeEnd,
                                                                  selectedDate: inspectionItem
                                                                          .timeEnd ??
                                                                      DateTime
                                                                          .now(),
                                                                  onChanged:
                                                                      ((DateTime
                                                                          date) {
                                                                    // setState(() {
                                                                    inspectionItem
                                                                            .timeEnd =
                                                                        date;
                                                                    // });
                                                                  })),
                                                            ]))),
                                                Container(
                                                    child: Container(
                                                        width: 200,
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: 15),
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                  padding: EdgeInsets
                                                                      .only(
                                                                          bottom:
                                                                              6), //2 c checkbox
                                                                  child: Row(
                                                                      children: [
                                                                        if (false)
                                                                          SizedBox(
                                                                              height: 24,
                                                                              width: 24,
                                                                              child: Checkbox(
                                                                                value: hasTimeEnd ?? false,
                                                                                onChanged: (value) {
                                                                                  setState(() {
                                                                                    hasTimeEnd = value;
                                                                                  });
                                                                                },
                                                                                checkColor: Theme.of(context).primaryColor,
                                                                              )),
                                                                        GestureDetector(
                                                                            child:
                                                                                Text(
                                                                              'Время',
                                                                              style: hasTimeEnd ? enableText : disableText,
                                                                              textAlign: TextAlign.left,
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                hasTimeEnd = !hasTimeEnd;
                                                                              });
                                                                            })
                                                                      ])),
                                                              TimePicker(
                                                                time:
                                                                    inspectionItem
                                                                        .timeEnd,
                                                                enable:
                                                                    hasTimeEnd,
                                                                minutesInterval:
                                                                    1,
                                                                spacing: 50,
                                                                itemHeight: 80,
                                                                context:
                                                                    context,
                                                                onTimeChange:
                                                                    (time) {
                                                                  inspectionItem
                                                                          .timeEnd =
                                                                      time;
                                                                },
                                                              )
                                                            ]))),
                                              ]),
                                          Container(
                                              width: 450,
                                              child: MyDropdown(
                                                text: 'Члены комиссии',
                                                dropdownValue:
                                                    inspectionItem.groupId !=
                                                            null
                                                        ? inspectionItem.groupId
                                                            .toString()
                                                        : null,
                                                items: groupList,
                                                onChange: (value) {
                                                  setState(() {
                                                    inspectionItem.groupId =
                                                        int.tryParse(value);
                                                  });
                                                },
                                                parentContext: context,
                                              )),
                                        ])),
                                    Expanded(
                                        child: Column(
                                      children: [
                                        if (eventId != null &&
                                            eventId == checkTypeId)
                                          ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  maxWidth: widthDepartment,
                                                  minHeight: 60),
                                              child: DepartmentSelect(
                                                  text:
                                                      "Структурное подразделение",
                                                  width: widthDepartment,
                                                  height: 250,
                                                  maxLine: 12,
                                                  department: department,
                                                  railwayId:
                                                      planItem["railwayId"],
                                                  context: context,
                                                  onSaved: (newDepartment) {
                                                    if (newDepartment == null)
                                                      return;
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
                                                  maxWidth: widthDepartment,
                                                  minHeight: 60),
                                              child: EditTextField(
                                                text: 'Описание',
                                                value: eventName,
                                                onSaved: (value) {
                                                  eventName = value;
                                                  inspectionItem.eventName =
                                                      value;
                                                },
                                                context: context,
                                                height: 250,
                                                maxLines: 12,
                                              )),
                                        if (eventId == null)
                                          Container(
                                              width: widthDepartment,
                                              height: 250,
                                              child: Text("")),
                                      ],
                                    ))
                                  ])))),
                              Container(
                                  child: MyButton(
                                      text: 'принять',
                                      parentContext: context,
                                      onPress: () => submitInspectionItem(
                                          inspectionItem, setState)))
                            ]))))));
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

      Navigator.pop<bool>(context, true);
      Scaffold.of(context).showSnackBar(successSnackBar);

      setState(() {
        _inspection = inspectionCopy;
        widget.setCheckPlanId(_inspection.id);
        reloadInspection(_inspection.parentId);
      });

      /*   try {
        if (inspectionCopy.id == null) {
          result = await controllers.CheckPlanController.insert(inspectionCopy);
        } else {
          result = await controllers.CheckPlanController.update(inspectionCopy);
        }
        hasErorr = result["code"] < 0;

        if (hasErorr) {
         
            Navigator.pop<bool>(context, false);
            Scaffold.of(context).showSnackBar(errorSnackBar());
        } else {
          if (planCopy.id == null) planCopy.id = result["id"];

          Navigator.pop<bool>(context, true);
          Scaffold.of(context).showSnackBar(successSnackBar);
        }
      } catch (e) {
        Navigator.pop<bool>(context, false);
        Scaffold.of(context).showSnackBar(errorSnackBar());
      }*/
    }
  }

  Future<void> submitInspectionItem(
      InspectionItem inspectionItem, setState) async {
    final form = formInspectionItemKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool result = true;

      if (inspectionItem.id == null) {
        // inspectionItem.id = result["id"];

        Map<String, dynamic> newValue = {
          'item': inspectionItem,
          'name': await depOrEventName(inspectionItem.eventId,
              inspectionItem.departmentId, inspectionItem.eventName)
        };
        setState(() {
          inspectionItems.add(newValue);
          //todo refresh all list?
        });
      } else {
        Map<String, dynamic> newValue = {
          'item': inspectionItem,
          'name': await depOrEventName(inspectionItem.eventId,
              inspectionItem.departmentId, inspectionItem.eventName)
        };

        setState(() {
          int index = inspectionItems.indexWhere((item) =>
              (item["item"] as InspectionItem).id == inspectionItem.id);
          inspectionItems[index] = newValue;
        });
      }

      Navigator.pop<bool>(context, result);
      if (result)
        Scaffold.of(context).showSnackBar(successSnackBar);
      else
        Scaffold.of(context).showSnackBar(errorSnackBar());
    }
  }

  Future<void> editInspectionItem(int inspectionItemId) async {
    InspectionItem inspectionItem = (inspectionItems.firstWhere((item) =>
            (item["item"] as InspectionItem).id == inspectionItemId))["item"]
        as InspectionItem;
    InspectionItem inspectionItemCopy = new InspectionItem(
        id: inspectionItem.id,
        odooId:inspectionItem.odooId,
        inspectionId: inspectionItem.inspectionId,
        departmentId: inspectionItem.departmentId,
        eventId: inspectionItem.eventId,
        eventName: inspectionItem.eventName,
        date: inspectionItem.date,
        timeBegin: inspectionItem.timeBegin,
        timeEnd: inspectionItem.timeEnd,
        groupId: inspectionItem.groupId);
    bool result = await showInspectionItemDialog(inspectionItemCopy, setState);
    if (result != null && result) {}
  }

  Future<void> deleteInspectionItem(int inspectionItemId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить проверку?', context);
    if (result != null && result) {
      Map<String, dynamic> deletedInspectionItem = inspectionItems.firstWhere(
          (item) => (item["item"] as InspectionItem).id == inspectionItemId);

      if (deletedInspectionItem == null) return;
      inspectionItems.remove(deletedInspectionItem);
      //todo delete from db
      setState(() {});
    }
  }

  Future<void> addInspectionItemClicked() async {
    if (_inspection.id == null) {
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
    if (result != null && result) {}
  }

  Future<void> forwardCheckItem(int inspectionItemId) async {
    InspectionItem inspectionItem = (inspectionItems.firstWhere((item) =>
            (item["item"] as InspectionItem).id == inspectionItemId))["item"]
        as InspectionItem;
     Map<String, dynamic> args = {
      'id': inspectionItem.id,
     // 'filial': planItem.filial,
     // 'typeName': getTypeInspectionById(planItem.typeId)["value"],
     // 'railwayId': _railway_id,
     // 'typePlan': _type,
     // 'year': _year
    };
    Navigator.pushNamed(context, '/checkItem', arguments: args);
  }
}
