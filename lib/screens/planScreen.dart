import 'package:ek_asu_opb_mobile/controllers/syn.dart';
import 'package:ek_asu_opb_mobile/src/exchangeData.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart' as controllers;
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter/rendering.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'dart:async';
import 'package:ek_asu_opb_mobile/utils/dictionary.dart';
import 'package:ek_asu_opb_mobile/src/db.dart';

class PlanScreen extends StatefulWidget {
  String type;
  GlobalKey key;

  PlanScreen({this.type, this.key});
  @override
  State<PlanScreen> createState() => _PlanScreen(type);
}

class _PlanScreen extends State<PlanScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  String tableName;
  int _year;
  String _type;
  int _railway_id;
  var _tapPosition;
  int _count = 0;
  final GlobalKey _menuKey = new GlobalKey();
  Plan _plan;
  //создаём копию и при редактировании работаем с ней
  //если пользователь отменит или ошибка при сохранении - вернем на начальное значение _plan

  List<Map<String, dynamic>> yearList;
  List<Map<String, dynamic>> railwayList;
  List<Map<String, dynamic>> stateList;
  List<Map<String, Object>> typeInspectionList;
  List<Map<String, Object>> periodInspectionList;

  Color color;
  TextStyle textStyle;
  String errorTableName;
  String emptyTableName;
  String saveError;
  String _tableName;

  double widthPlan = 800;
  double heightPlan = 700;
  double widthPlanItem = 1100;

  _PlanScreen(type) {
    _type = type;
  }
  final formPlanKey = new GlobalKey<FormState>();
  final formPlanItemKey = new GlobalKey<FormState>();

  List<Map<String, dynamic>> choices = [
    {'title': "Редактировать запись", 'icon': Icons.edit, 'key': 'edit'},
    {'title': 'Удалить запись', 'icon': Icons.delete, 'key': 'delete'},
    {
      'title': 'Перейти к плану проверок',
      'icon': Icons.arrow_forward,
      'key': 'forward'
    }
  ];

  List<Map<String, dynamic>> planItemHeader = [
    {
      'text': 'Наименование проверяемого филиала, территории железной дороги',
      'flex': 3.0
    },
    {'text': 'Подразделения, подлежащие проверке', 'flex': 2.0},
    {'text': 'Вид проверки', 'flex': 2.0},
    {'text': 'Срок проведения  проверки', 'flex': 2.0},
    {'text': 'Ответственные за организацию и проведение проверки', 'flex': 2.0},
    {'text': 'Результаты проведенной проверки', 'flex': 2.0}
  ];

  /*List<PlanItem> _planItems = <PlanItem>[
    PlanItem(
        parentId: 1,
        id: 1,
        name:
            'Комплексная проверка Центральная дирекция по ремонту тягового подвижного состава (ЦТР)',
        departmentTxt: 'Все ТР, ЦТР',
        checkType: 1,
        period: 1,
        responsible: 'ЦБТ - ЦТР, НЦОП - ТР',
        checkResult: 'Корректирующие меры',
        active: true),
    PlanItem(
        parentId: 1,
        id: 2,
        name: 'Дирекция железнодорожных вокзалов  (ДЖВ)',
        departmentTxt: 'Все РДЖВ, ДЖВ',
        checkType: 2,
        period: 2,
        responsible: 'ЦБТ - ДЖВ,НЦОП - РДЖВ',
        checkResult: 'Корректирующие меры',
        active: true),
    PlanItem(
        parentId: 1,
        id: 3,
        name:
            'Территория Южно-Уральской железной дороги подразделения всех хозяйств ОАО «РЖД» и ДЗО (по согласованию)',
        departmentTxt:
            'Челябинск, Курган, Петропавловск, Троицк, Карталы, Магнитогорск, Орск, Оренбург, Бердяуш',
        checkType: 2,
        period: 2,
        responsible:
            'Комиссионно, под председательством руководителей или специалистов ЦБТ, НПЦ по ООС',
        checkResult: 'Протокол,  приказ, корректирующие меры',
        active: true),
  ];*/

  List<PlanItem> planItems = [];
  PlanItem planItemCopy;

  @override
  void initState() {
    super.initState();
    auth.getUserInfo().then((userInfo) {
      _userInfo = userInfo;
      _year = DateTime.now().year;
      _railway_id = _userInfo.railway_id;
      saveError = "";
      emptyTableName =
          "ПЛАН\nпроведения комплексных аудитов и целевых проверок организации работы по экологической безопасности"; // на ${_year.toString()} год";
      errorTableName = "Выберите дорогу для загрузки плана";
      //showLoading = false;
      _tableName = "";

      loadData(); //.then((value) => setState(() => {}));
    });
  }

  List<Map<String, dynamic>> getYearList(int year) {
    List<Map<String, dynamic>> yearList = [];
    for (int i = year - 1; i <= year + 1; i++)
      yearList.add({"id": i, "value": i});
    return yearList;
  }

  bool canEdit() {
    if (_type == "ncop" && (_railway_id == null)) return false;
    return true;
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});
      yearList = getYearList(_year);
      railwayList = await getRailwayList();
      stateList = makeListFromJson(Plan.stateSelection);
      typeInspectionList = makeListFromJson(PlanItem.checkTypeSelection);
      periodInspectionList = makeListFromJson(PlanItem.periodSelection);
      await reloadPlan();
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  Future<void> reloadPlan() async {
    try {
      _plan =
          await controllers.PlanController.select(_year, _type, _railway_id);
    } catch (e) {
      _plan = null;
    }

    if (_plan == null)
      _plan = new Plan(
          id: null,
          type: _type,
          year: _year,
          railwayId: _railway_id,
          active: true,
          name: canEdit() ? emptyTableName : errorTableName);

    planItems = [];

    if (_plan.id != null) planItems = await _plan.items;

    planItems = planItems ?? [];

    // await reloadPlanItems(_plan.id);

    setState(() => {/*_tableName = tableName*/});
  }

  /* Future<void> reloadPlanItems(int planId) async {
    planItems = [];
    if (canEdit() && planId != null)
      planItems = await _plan
          .items; //await controllers.PlanItemController.select(planId);

    planItems = planItems ?? []; //todo вернуть []

    return planItems;
  }*/

  @override
  Widget build(BuildContext context) {
    color = Theme.of(context).buttonColor;
    textStyle = TextStyle(fontSize: 16.0, color: color);

    final menu = PopupMenuButton(
      itemBuilder: (_) => getMenu(context),
      padding: EdgeInsets.all(0.0),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            editPlanClicked();
            break;
          case 'add':
            addPlanItemClicked();
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
    if (_plan != null && _plan.name != null) {
      if (_plan.name != errorTableName)
        tableName = '${_plan.name} ${_year.toString()} год';
      else
        tableName = '${_plan.name}';
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
                        if (_plan.id != null)
                          Column(children: [
                            generateTableData(
                                context, planItemHeader, planItems)
                          ])
                      ])),
                   Container(
                      child: MyButton(
                          text: 'test',
                          parentContext: context,
                          onPress: testClicked))
                ])));
  }

  Widget generateTableData(BuildContext context,
      List<Map<String, dynamic>> headers, List<PlanItem> rows) {
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
            getRowCell(row.departmentTxt, row.id, 1),
            getRowCell(
                row.checkTypeDisplay.toString() == 'null'
                    ? ''
                    : row.checkTypeDisplay,
                row.id,
                2),
            getRowCell(
                row.periodDisplay.toString() == 'null' ? '' : row.periodDisplay,
                row.id,
                3),
            getRowCell(row.responsible, row.id, 4),
            getRowCell(row.checkResult, row.id, 5),
          ]);
      tableRows.add(tableRow);
    });

    return Table(
        border: TableBorder.all(),
        columnWidths: columnWidths,
        children: tableRows);
  }

  Widget getRowCell(String text, int planItemId, int index,
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
          _showCustomMenu(planItemId, index);
        },
        child: cell);
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
    result.add(
      PopupMenuItem<String>(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 17.0),
            child: MyDropdown(
              text: 'Год',
              width: double.infinity,
              dropdownValue: _year.toString(),
              items: yearList,
              onChange: (value) {
                setState(() {
                  _year = int.parse(value);
                  reloadPlan();
                });
              },
              parentContext: context,
            ),
          ),
          value: 'year'),
    );

    if (_userInfo.f_user_role_txt == cbtRole && _type == "ncop") {
      result.add(
        PopupMenuItem<String>(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 17.0),
              child: MyDropdown(
                text: 'Дорога',
                width: double.infinity,
                height: 100,
                dropdownValue:
                    _railway_id != null ? _railway_id.toString() : null, //"0",
                items: railwayList,
                onChange: (value) {
                  setState(() {
                    _railway_id = int.parse(value);
                    reloadPlan();
                  });
                },
                parentContext: context,
              ),
            ),
            value: 'railway'),
      );
    }
    return result;
  }

  Future<void> editPlanClicked() async {
    if (!canEdit()) {
      Scaffold.of(context).showSnackBar(errorSnackBar(text: errorTableName));
      return;
    }
    saveError = "";
    Plan planCopy = new Plan(
        odooId: _plan.odooId,
        id: _plan.id,
        type: _plan.type,
        year: _plan.year,
        dateSet: _plan.dateSet ?? DateTime.now(),
        name: _plan.name,
        railwayId: _plan.railwayId,
        signerName: _plan.signerName,
        signerPost: _plan.signerPost,
        numSet: _plan.numSet,
        active: _plan.active,
        state: _plan.state);
    setState(() {});
    bool result = await showPlanDialog(planCopy);
    if (result != null && result) //иначе перезагружать _plan?
    {}
  }

  Future<void> addPlanItemClicked() async {
    if (!canEdit()) {
      Scaffold.of(context).showSnackBar(errorSnackBar(text: errorTableName));
      return;
    }
    if (_plan.id == null) {
      Scaffold.of(context).showSnackBar(
          errorSnackBar(text: 'Сначала сохраните реквизиты плана'));
      return;
    }
    PlanItem planItem =
        new PlanItem(id: null, parentId: _plan.id, active: true);
    bool result = await showPlanItemDialog(planItem);
    if (result != null && result) {
      //todo refresh all list?
    }
  }

  void _showCustomMenu(int planItemId, int index) {
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
          editPlanItem(planItemId);
          break;
        case 'delete':
          deletePlanItem(planItemId);
          break;
        case 'forward':
          forwardPlanInspection(planItemId);
          break;
      }
    });
  }

  Future<void> editPlanItem(int planItemId) async {
    PlanItem planItem =
        planItems.firstWhere((planItem) => planItem.id == planItemId);
    PlanItem planItemCopy = new PlanItem(
        odooId: planItem.odooId,
        parentId: planItem.parentId,
        id: planItem.id,
        name: planItem.name,
        departmentTxt: planItem.departmentTxt,
        checkType: planItem.checkType,
        period: planItem.period,
        responsible: planItem.responsible,
        checkResult: planItem.checkResult,
        active: planItem.active);
    bool result = await showPlanItemDialog(planItemCopy);
    if (result != null && result) {}
  }

  Future<void> deletePlanItem(int planItemId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удалить пункт плана?', context);
    if (result != null && result) {
      PlanItem deletedPlanItem =
          planItems.firstWhere((planItem) => planItem.id == planItemId);
      if (deletedPlanItem == null) return;
      //  deletedPlanItem.active = false;
      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        result = await controllers.PlanItemController.delete(planItemId);
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          Scaffold.of(context).showSnackBar(
              errorSnackBar(text: 'Произошла ошибка при удалении'));
          return;
        }

        planItems.remove(deletedPlanItem);
        setState(() {});
      } catch (e) {
        Scaffold.of(context)
            .showSnackBar(errorSnackBar(text: 'Произошла ошибка при удалении'));
      }
    }
  }

  Future<void> forwardPlanInspection(int planItemId) async {
    PlanItem planItem =
        planItems.firstWhere((planItem) => planItem.id == planItemId);
    Map<String, dynamic> args = {
      'planItemId': planItemId,
      'filial': planItem.name.toString() != null ? planItem.name : '',
      'typeName': planItem.checkTypeDisplay.toString() != 'null'
          ? planItem.checkTypeDisplay
          : '',
      'railwayId': _railway_id,
      'typePlan': _type,
      'year': _year
    };
    Navigator.pushNamed(context, '/inspection', arguments: args);
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  Future<bool> showPlanDialog(Plan plan) {
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
                content:*/
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
                  margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Scaffold(
                      backgroundColor: Colors.transparent,
                      body: Form(
                          key: formPlanKey,
                          child: Container(
                              child: Column(children: [
                            FormTitle(
                                'Реквизиты плана ${plan.type == 'ncop' ? 'НЦОП' : 'ЦБТ'}'),
                            Expanded(
                                child: Center(
                                    child: SingleChildScrollView(
                                        child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                  EditTextField(
                                    text: 'Наименование',
                                    value: plan.name,
                                    onSaved: (value) => {plan.name = value},
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
                                              dropdownValue: plan.state,
                                              items: stateList,
                                              onChange: (value) {
                                                plan.state = value;
                                              },
                                              parentContext: context,
                                            )),
                                        Container(
                                            width: 100,
                                            child: MyDropdown(
                                              text: 'Год',
                                              dropdownValue:
                                                  plan.year.toString(),
                                              items: yearList,
                                              onChange: (value) {
                                                plan.year = int.parse(value);
                                              },
                                              parentContext: context,
                                            )),
                                        Container(
                                            width: 200,
                                            height:
                                                (_userInfo.f_user_role_txt ==
                                                            cbtRole &&
                                                        plan.type == 'ncop')
                                                    ? null
                                                    : 0,
                                            margin: EdgeInsets.only(right: 15),
                                            child: MyDropdown(
                                              text: 'Дорога',
                                              dropdownValue: plan.railwayId !=
                                                      null
                                                  ? plan.railwayId.toString()
                                                  : null, // railwayList[0]['id'].toString(),
                                              items: railwayList,
                                              onChange: (value) {
                                                plan.railwayId =
                                                    int.parse(value.toString());
                                              },
                                              parentContext: context,
                                            )),
                                      ]),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      children: [
                                        Container(
                                            width: 400,
                                            child: EditTextField(
                                              text: 'Номер',
                                              value: plan.numSet,
                                              onSaved: (value) =>
                                                  {plan.numSet = value},
                                              context: context,
                                            )),
                                        Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 13),
                                            child: DatePicker(
                                                parentContext: context,
                                                text: "Дата утверждения",
                                                selectedDate: plan.dateSet ??
                                                    DateTime.now(),
                                                onChanged: ((DateTime date) {
                                                  //   setState(() {
                                                  plan.dateSet =
                                                      date; //.toString();
                                                  //  });
                                                })))
                                      ]),
                                  EditTextField(
                                    text: 'Подписант, ФИО',
                                    value: plan.signerName,
                                    onSaved: (value) =>
                                        {plan.signerName = value},
                                    context: context,
                                  ),
                                  EditTextField(
                                    text: 'Подписант, должность',
                                    value: plan.signerPost,
                                    onSaved: (value) =>
                                        {plan.signerPost = value},
                                    context: context,
                                  )
                                ])))),
                            Container(
                                child: Column(children: [
                              MyButton(
                                  text: 'принять',
                                  parentContext: context,
                                  onPress: () {
                                    submitPlan(plan, setState);
                                  }),
                              Container(
                                  width: double.infinity,
                                  height: 20,
                                  color: (saveError != "")
                                      ? Color(0xAAE57373)
                                      : Color(0x00E57373),
                                  child: Text('$saveError',
                                      textAlign: TextAlign.center,
                                      style:
                                          TextStyle(color: Color(0xFF252A0E))))
                            ]))
                          ])))))
            ]);
          });
        });
  }

  Future<bool> showPlanItemDialog(PlanItem planItem) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
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
                width: widthPlanItem,
              ),
            ),
            Container(
                width: widthPlanItem,
                margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Form(
                        key: formPlanItemKey,
                        child: Container(
                            child: Column(children: [
                          FormTitle(
                              '${planItem.id == null ? 'Добавление' : 'Редактирование'} пункта плана'),
                          Expanded(
                              child: Center(
                                  child: SingleChildScrollView(
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                Expanded(
                                    child: EditTextField(
                                      text: 'Наименование проверяемого филиала',
                                      value: planItem.name,
                                      onSaved: (value) =>
                                          {planItem.name = value},
                                      context: context,
                                      height: 350,
                                      maxLines: 17,
                                      // color: Theme.of(context).primaryColorDark,
                                    ),
                                    flex: 1),
                                Expanded(
                                    flex: 2,
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          EditTextField(
                                            text:
                                                'Подразделение, подлежащее проверке',
                                            value: planItem.departmentTxt,
                                            onSaved: (value) => {
                                              planItem.departmentTxt = value
                                            },
                                            context: context,
                                            height: 100,
                                            maxLines: 3,
                                          ),
                                          /* EditTextField(
                                          text: 'Вид проверки',
                                          value: planItem.type,
                                          onSaved: (value) =>
                                              {planItem.type = value},
                                          context: context,
                                        ),*/
                                          Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.baseline,
                                              children: [
                                                Expanded(
                                                    child: Container(
                                                        margin: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 15),
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 15),
                                                        child: MyDropdown(
                                                          text: 'Вид проверки',
                                                          dropdownValue:
                                                              planItem.checkType !=
                                                                      null
                                                                  ? planItem
                                                                      .checkType
                                                                      .toString()
                                                                  : null,
                                                          items:
                                                              typeInspectionList,
                                                          onChange: (value) {
                                                            planItem.checkType =
                                                                int.tryParse(
                                                                    value);
                                                          },
                                                          parentContext:
                                                              context,
                                                        ))),
                                                Expanded(
                                                    child: Container(
                                                        margin: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 15),
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 15),
                                                        child: MyDropdown(
                                                          text:
                                                              'Срок проведения проверки',
                                                          dropdownValue: planItem
                                                                      .period !=
                                                                  null
                                                              ? planItem.period
                                                                  .toString()
                                                              : null,
                                                          items:
                                                              periodInspectionList,
                                                          onChange: (value) {
                                                            planItem.period =
                                                                int.tryParse(
                                                                    value);
                                                          },
                                                          parentContext:
                                                              context,
                                                        )))
                                              ]),
                                          EditTextField(
                                            text:
                                                'Ответственные за организацию и проведение проверки',
                                            value: planItem.responsible,
                                            onSaved: (value) =>
                                                {planItem.responsible = value},
                                            context: context,
                                          ),
                                          EditTextField(
                                            text:
                                                'Результаты проведенной проверки',
                                            value: planItem.checkResult,
                                            onSaved: (value) =>
                                                {planItem.checkResult = value},
                                            context: context,
                                          ),
                                        ]))
                              ])))),
                          Container(
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                MyButton(
                                    text: 'принять',
                                    parentContext: context,
                                    onPress: () => submitPlanItem(planItem)),
                                MyButton(
                                    text: 'отменить',
                                    parentContext: context,
                                    onPress: () {
                                      cancelPlanItem();
                                    }),
                              ]))
                        ])))))
          ]);
        });
  }

  void submitPlan(Plan planCopy, setState) async {
    var formPlanKey2 = formPlanKey;
    final form = formPlanKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
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

          setState(() {
            _plan = planCopy;
            _year = _plan.year;
            _railway_id = _plan.railwayId;
            reloadPlan();
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

  Future<void> cancelPlanItem() async {
    Navigator.pop<bool>(context, null);
  }

  void submitPlanItem(PlanItem planItem) async {
    final form = formPlanItemKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();

      bool hasErorr = false;
      Map<String, dynamic> result;
      try {
        if (planItem.id == null) {
          result = await controllers.PlanItemController.insert(planItem);
        } else {
          result = await controllers.PlanItemController.update(planItem);
        }
        hasErorr = result["code"] < 0;

        if (hasErorr) {
          Navigator.pop<bool>(context, false);
          Scaffold.of(context).showSnackBar(errorSnackBar());
        } else {
          if (planItem.id == null) {
            planItem.id = result["id"];

            setState(() {
              planItems.add(planItem);
            });
          } else {
            setState(() {
              int index = planItems.indexOf(
                  planItems.firstWhere((element) => element.id == planItem.id));
              planItems[index] = planItem;
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

  void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<void> testClicked() async {
    print('test');

    //  List result = await DBProvider.db.selectAll('plan');
    await DBProvider.db.deleteAll('check_list');
    await DBProvider.db.deleteAll('check_list_item');

    //await DBProvider.db.deleteAll('plan_item');
    //await DBProvider.db.deleteAll('plan');
   // print(result.length);
  }
}
