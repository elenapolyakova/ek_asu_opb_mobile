import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/utils/dictionary.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:ek_asu_opb_mobile/components/time_picker_spinner.dart';

class Inspection {
  int id;
  int planItemId;
  String name; //наименование
  String signerName; //Подписант имя
  String signerPost; //Подписант должность
  String appName; //утвержден имя
  String appPost; //утвержден должность
  String numSet; //Номер плана
  String dateSet; //дата утверждения
  bool active; //Действует
  String state; //Состояние
  String dateBegin; //Дата начала проверки
  String dateEnd; //Дата окончания проверки
  Inspection(
      {this.id,
      this.planItemId,
      this.name,
      this.signerName,
      this.signerPost,
      this.appName,
      this.appPost,
      this.numSet,
      this.dateSet,
      this.active,
      this.state,
      this.dateBegin,
      this.dateEnd});
}

//todo delete when model exists
class InspectionItem {
  int id;
  int inspectionItemId;
  int departmentId; //если проверка СП
  int eventId; //для обеда, отъезда, ужина и тд
  String eventName; //событие текстом на случай встреча с руководством и тд
  String date; //Дата проверки
  String timeBegin; //Время начала проверки
  String timeEnd; //Время окончания проверки
  InspectionItem(
      {this.id,
      this.inspectionItemId,
      this.departmentId,
      this.eventId,
      this.eventName,
      this.date,
      this.timeBegin,
      this.timeEnd});
}

//todo delete
class InspectionPlanScreen extends StatefulWidget {
  BuildContext context;
  Map<String, dynamic> planItem;

  @override
  InspectionPlanScreen(this.context, this.planItem);

  @override
  State<InspectionPlanScreen> createState() => _InspectionPlanScreen(planItem);
}

class _InspectionPlanScreen extends State<InspectionPlanScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  Map<String, dynamic> planItem;
  Inspection _inspection;
  //создаём копию и при редактировании работаем с ней
  //если пользователь отменит или ошибка при сохранении - вернем на начальное значение _inspection
  Inspection inspectionCopy;
  String emptyTableName;
  String _tableName;
  List<Map<String, dynamic>> railwayList;
  List<Map<String, dynamic>> stateList;
  List<Map<String, dynamic>> eventList;
  var _tapPosition;
  bool hasTimeBegin;
  bool hasTimeEnd;

  List<InspectionItem> _inspectionItems = [];
  /*<InspectionItem>[
    InspectionItem(inspectionId: 1,inspectionItemId: 1, departmentId: null, eventId: null, eventName: '' ),
    InspectionItem(),
    InspectionItem(),
  ];*/
  List<InspectionItem> inspectionItems = [];
  final formInspectionKey = new GlobalKey<FormState>();
  final formInspectionItemKey = new GlobalKey<FormState>();

  List<Map<String, dynamic>> choices = [
    {'title': "Редактировать проверку", 'icon': Icons.edit, 'key': 'edit'},
    {'title': 'Удалить проверку', 'icon': Icons.delete, 'key': 'delete'},
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
          emptyTableName = '${planItem["typeName"]} ${planItem["filial"]}';

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
    }
  }

  Future<void> reloadInspection(int planItemId) async {
    /* try {
      _inspection =
          await controllers.InspectionController.select(planItemId);
    } catch (e) {}*/

    if (_inspection == null)
      _inspection = new Inspection(
          id: null, planItemId: planItemId, name: emptyTableName);

    await reloadInspectionItems(_inspection.id);

    setState(() => {});
  }

  Future<void> reloadInspectionItems(int inspectionId) async {
    if (inspectionId != null) //todo потом проверять planId <> null
      inspectionItems = _inspectionItems;
    else
      inspectionItems = [];
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

    return new Container(
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
                        Column(children: [
                          generateTableData(
                              context, inspectionItemHeader, inspectionItems)
                        ])
                      ])),
                  // Container(
                  //     child: MyButton(
                  //         text: 'test',
                  //         parentContext: context,
                  //         onPress: testClicked))
                ])));
  }

  List<PopupMenuItem<String>> getMenu(BuildContext context) {
    List<PopupMenuItem<String>> result = [];
    result.add(
      PopupMenuItem<String>(
          child: TextIcon(
            icon: Icons.edit,
            text: "Редактировать проверку",
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
            text: "Добавить запись",
            margin: 5.0,
            /* onTap: () ,*/
            color: Theme.of(context).primaryColorDark,
          ),
          value: 'add'),
    );
    return result;
  }

  Widget generateTableData(BuildContext context,
      List<Map<String, dynamic>> headers, List<InspectionItem> rows) {
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
    /*rows.forEach((row) {
      rowIndex++;
      TableRow tableRow = TableRow(
          decoration: BoxDecoration(
              color: (rowIndex % 2 == 0
                  ? Theme.of(context).shadowColor
                  : Colors.white)),
          children: [
            getRowCell(row.filial, row.planItemId, 0),
            getRowCell(row.department, row.planItemId, 1),
            getRowCell(
                getTypeInspectionById(row.typeId)["value"], row.planItemId, 2),
            getRowCell(getPeriodInspectionById(row.periodId)["value"],
                row.planItemId, 3),
            getRowCell(row.responsible, row.planItemId, 4),
            getRowCell(row.result, row.planItemId, 5),
          ]);
      tableRows.add(tableRow);
    });*/

    return Table(
        border: TableBorder.all(),
        columnWidths: columnWidths,
        children: tableRows);
  }

  void _showCustomMenu(int inspectionItemId, int index) {
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
          editInspectionItem(inspectionItemId);
          break;
        case 'delete':
          deleteInspectionItem(inspectionItemId);
          break;
        case 'forward':
          forwardInsDepartment(inspectionItemId);
          break;
      }
    });
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  Future<bool> showInspectionDialog(Inspection inspection) {
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
                    width: 700.0,
                    margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Scaffold(
                        backgroundColor: Theme.of(context).primaryColor,
                        body: Form(
                            key: formInspectionKey,
                            child: Container(
                                child: Column(children: [
                              Expanded(
                                  child: Center(
                                      child: SingleChildScrollView(
                                          child: Column(
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
                                                  selectedDate: DateTime
                                                          .tryParse(inspection
                                                              .dateBegin
                                                              .toString()) ??
                                                      DateTime.now(),
                                                  onChanged: ((DateTime date) {
                                                    //   setState(() {
                                                    inspection.dateBegin =
                                                        date.toString();
                                                    //  });
                                                  }))),
                                          Container(
                                              padding:
                                                  EdgeInsets.only(right: 13),
                                              child: DatePicker(
                                                  parentContext: context,
                                                  text: "Дата окончания",
                                                  width: 150,
                                                  selectedDate: DateTime
                                                          .tryParse(inspection
                                                              .dateEnd
                                                              .toString()) ??
                                                      DateTime.now(),
                                                  onChanged: ((DateTime date) {
                                                    //   setState(() {
                                                    inspection.dateEnd =
                                                        date.toString();
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
                                                  selectedDate: DateTime
                                                          .tryParse(inspection
                                                              .dateSet
                                                              .toString()) ??
                                                      DateTime.now(),
                                                  onChanged: ((DateTime date) {
                                                    //   setState(() {
                                                    inspection.dateSet =
                                                        date.toString();
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
                                  ])))),
                              Container(
                                  child: Column(children: [
                                MyButton(
                                    text: 'принять',
                                    parentContext: context,
                                    onPress: () {
                                      submitInspection(setState);
                                    }),
                              ]))
                            ]))))));
          });
        });
  }

  Future<bool> showInspectionItemDialog(
      InspectionItem inspectionItem, setState) {
    setState(() {
      hasTimeBegin = inspectionItem.timeBegin != null;
      hasTimeEnd = inspectionItem.timeEnd != null;
    });
    final TextStyle enableText =
        TextStyle(fontSize: 16.0, color: Theme.of(context).primaryColorDark);
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
                    width: 500.0,
                    child: Scaffold(
                        backgroundColor: Theme.of(context).primaryColor,
                        body: Form(
                            key: formInspectionItemKey,
                            child: Container(
                                child: Column(children: [
                              Expanded(
                                  child: Center(
                                      child: SingleChildScrollView(
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
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 13),
                                              child: Container(
                                                  width: 200,
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    bottom: 6),
                                                            child: Text(
                                                              'Дата проверки',
                                                              textAlign:
                                                                  TextAlign
                                                                      .left,
                                                              style: enableText,
                                                            )),
                                                        DatePicker(
                                                            parentContext:
                                                                context,
                                                            text: "",
                                                            width: 200,
                                                            selectedDate: DateTime
                                                                    .tryParse(
                                                                        inspectionItem
                                                                            .date
                                                                            .toString()) ??
                                                                DateTime.now(),
                                                            onChanged:
                                                                ((DateTime
                                                                    date) {
                                                              // setState(() {
                                                              inspectionItem
                                                                      .date =
                                                                  date.toString();
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
                                                            padding:
                                                                EdgeInsets.only(
                                                                    bottom: 2),
                                                            child:
                                                                Row(children: [
                                                              SizedBox(
                                                                  height: 24,
                                                                  width: 24,
                                                                  child:
                                                                      Checkbox(
                                                                    value:
                                                                        hasTimeBegin ??
                                                                            false,
                                                                    onChanged:
                                                                        (value) {
                                                                      setState(
                                                                          () {
                                                                        hasTimeBegin =
                                                                            value;
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
                                                                        TextAlign
                                                                            .left,
                                                                  ),
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      hasTimeBegin =
                                                                          !hasTimeBegin;
                                                                    });
                                                                  })
                                                            ])),
                                                        TimePicker(
                                                          time: inspectionItem
                                                                      .timeBegin !=
                                                                  null
                                                              ? DateTime.parse(
                                                                  inspectionItem
                                                                      .timeBegin)
                                                              : null,
                                                          enable: hasTimeBegin,
                                                          minutesInterval: 1,
                                                          spacing: 50,
                                                          itemHeight: 80,
                                                          context: context,
                                                          onTimeChange: (time) {
                                                            inspectionItem
                                                                    .timeBegin =
                                                                time.toString();
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
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 13),
                                              child: Container(
                                                  width: 200,
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    bottom: 2,
                                                                    top: 13),
                                                            child:
                                                                Row(children: [
                                                              SizedBox(
                                                                  height: 24,
                                                                  width: 24,
                                                                  child:
                                                                      Checkbox(
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
                                                                    checkColor:
                                                                        Theme.of(context)
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
                                                                    setState(
                                                                        () {
                                                                      hasTimeEnd =
                                                                          !hasTimeEnd;
                                                                    });
                                                                  })
                                                            ])),
                                                        DatePicker(
                                                            parentContext:
                                                                context,
                                                            text: "",
                                                            width: 200,
                                                            enable: hasTimeEnd,
                                                            selectedDate: DateTime
                                                                    .tryParse(
                                                                        inspectionItem
                                                                            .date
                                                                            .toString()) ??
                                                                DateTime.now(),
                                                            onChanged:
                                                                ((DateTime
                                                                    date) {
                                                              // setState(() {
                                                              inspectionItem
                                                                      .date =
                                                                  date.toString();
                                                              // });
                                                            })),
                                                      ]))),
                                          Container(
                                              child: Container(
                                                  width: 200,
                                                  padding:
                                                      EdgeInsets.only(top: 15),
                                                  child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    bottom:
                                                                        6), //2 c checkbox
                                                            child:
                                                                Row(children: [
                                                              if (false)
                                                                SizedBox(
                                                                    height: 24,
                                                                    width: 24,
                                                                    child:
                                                                        Checkbox(
                                                                      value: hasTimeEnd ??
                                                                          false,
                                                                      onChanged:
                                                                          (value) {
                                                                        setState(
                                                                            () {
                                                                          hasTimeEnd =
                                                                              value;
                                                                        });
                                                                      },
                                                                      checkColor:
                                                                          Theme.of(context)
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
                                                                    setState(
                                                                        () {
                                                                      hasTimeEnd =
                                                                          !hasTimeEnd;
                                                                    });
                                                                  })
                                                            ])),
                                                        TimePicker(
                                                          time: inspectionItem
                                                                      .timeBegin !=
                                                                  null
                                                              ? DateTime.parse(
                                                                  inspectionItem
                                                                      .timeBegin)
                                                              : null,
                                                          enable: hasTimeEnd,
                                                          minutesInterval: 1,
                                                          spacing: 50,
                                                          itemHeight: 80,
                                                          context: context,
                                                          onTimeChange: (time) {
                                                            inspectionItem
                                                                    .timeBegin =
                                                                time.toString();
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
                                                        width:200,
                                                          child: MyDropdown(
                                                            text:
                                                                'Тип события',
                                                            dropdownValue: inspectionItem.eventId !=
                                                                    null
                                                                ? inspectionItem
                                                                    .eventId
                                                                    .toString()
                                                                : null,
                                                            items:
                                                                eventList,
                                                            onChange: (value) {
                                                              inspectionItem.eventId =
                                                                  int.tryParse(
                                                                      value);
                                                            },
                                                            parentContext:
                                                                context,
                                                          ))
                                        ],)
                                  ])))),
                              Container(
                                  child: MyButton(
                                      text: 'принять',
                                      parentContext: context,
                                      onPress: submitInspectionItem))
                            ]))))));
          });
        });
  }

  Future<void> editInspectionClicked() async {
    inspectionCopy = new Inspection(
        id: _inspection.id,
        planItemId: _inspection.planItemId,
        name: _inspection.name,
        signerName: _inspection.signerName,
        signerPost: _inspection.signerPost,
        appName: _inspection.appName,
        appPost: _inspection.appPost,
        numSet: _inspection.numSet,
        dateSet: _inspection.dateSet,
        active: _inspection.active,
        state: _inspection.state,
        dateBegin: _inspection.dateBegin,
        dateEnd: _inspection.dateEnd);
    setState(() {});
    bool result = await showInspectionDialog(inspectionCopy);
    if (result != null && result) //иначе перезагружать _plan?
      setState(() {
        _inspection = inspectionCopy;
        reloadInspection(_inspection.planItemId);
      });
  }

  Future<void> submitInspection(setState) async {
    final form = formInspectionKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool hasErorr = false;
      Map<String, dynamic> result;
// if (planItemCopy.id == null) planItemCopy.id = result["id"];

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
      }*/
    }
  }

  Future<void> submitInspectionItem() async {
    final form = formInspectionItemKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool result = true;

      // if (inspectionItemCopy.id == null) inspectionItemCopy.id = result["id"];
      Navigator.pop<bool>(context, result);
      if (result)
        Scaffold.of(context).showSnackBar(successSnackBar);
      else
        Scaffold.of(context).showSnackBar(errorSnackBar());
    }
  }

  Future<void> editInspectionItem(int inspectionItemId) async {
    InspectionItem inspectionItem = inspectionItems
        .firstWhere((inspectionItem) => inspectionItem.id == inspectionItemId);
    InspectionItem inspectionItemCopy = new InspectionItem(
        id: inspectionItem.id,
        inspectionItemId: inspectionItem.inspectionItemId,
        departmentId: inspectionItem.departmentId,
        eventId: inspectionItem.eventId,
        eventName: inspectionItem.eventName,
        date: inspectionItem.date,
        timeBegin: inspectionItem.timeBegin);
    bool result = await showInspectionItemDialog(inspectionItemCopy, setState);
    if (result != null && result)
      setState(() {
        int index = inspectionItems.indexOf(inspectionItem);
        inspectionItems[index] = inspectionItemCopy;
      });
  }

  Future<void> deleteInspectionItem(int inspectionItemId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить проверку?', context);
    if (result != null && result) {
      InspectionItem deletedInspectionItem = inspectionItems.firstWhere(
          (inspectionItem) => inspectionItem.id == inspectionItemId);
      if (deletedInspectionItem == null) return;
      inspectionItems.remove(deletedInspectionItem);
      //todo delete from db
      setState(() {});
    }
  }

  Future<void> addInspectionItemClicked() async {
    InspectionItem inspectionItem = new InspectionItem(id: null);
    bool result = await showInspectionItemDialog(inspectionItem, setState);
    if (result != null && result)
      setState(() {
        inspectionItems.add(inspectionItem);
        //todo refresh all list?
      });
  }

  Future<void> forwardInsDepartment(int inspectionItemId) async {
    InspectionItem inspectionItem = inspectionItems
        .firstWhere((inspectionItem) => inspectionItem.id == inspectionItemId);
    /* Map<String, dynamic> args = {
      'planItemId': planItemId,
      'filial': planItem.filial,
      'typeName': getTypeInspectionById(planItem.typeId)["value"],
      'railwayId': _railway_id,
      'typePlan': _type,
      'year': _year
    };
    Navigator.pushNamed(context, '/inspection', arguments: args);*/
  }
}
