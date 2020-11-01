import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart' as controllers;
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter/rendering.dart';

final _sizeTextBlack =
    const TextStyle(fontSize: 20.0, color: Color(0xFF252A0E));
final _sizeTextWhite = const TextStyle(fontSize: 20.0, color: Colors.white);

//todo delete
class PlanItem {
  int planItemId;
  String filial;
  String department;
  String type;
  String period;
  String responsible;
  String result;
  PlanItem(
      {this.planItemId,
      this.filial,
      this.department,
      this.type,
      this.period,
      this.responsible,
      this.result});
}
//todo delete

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
  var _tapPosition;
  int _count = 0;
  final GlobalKey _menuKey = new GlobalKey();
  Plan _plan;
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

  List<PlanItem> planItems = <PlanItem>[
    PlanItem(
        planItemId: 1,
        filial:
            'Центральная дирекция по ремонту тягового подвижного состава (ЦТР)',
        department: 'Все ТР, ЦТР',
        type: 'комплексный аудит',
        period: 'I квартал',
        responsible: 'ЦБТ - ЦТР, НЦОП - ТР',
        result: 'Корректирующие меры'),
    PlanItem(
        planItemId: 2,
        filial: 'Дирекция железнодорожных вокзалов  (ДЖВ)',
        department: 'Все РДЖВ, ДЖВ',
        type: 'целевая',
        period: 'II квартал',
        responsible: 'ЦБТ - ДЖВ,НЦОП - РДЖВ',
        result: 'Корректирующие меры'),
    PlanItem(
        planItemId: 3,
        filial:
            'Территория Южно-Уральской железной дороги подразделения всех хозяйств ОАО «РЖД» и ДЗО (по согласованию)',
        department:
            'Челябинск, Курган, Петропавловск, Троицк, Карталы, Магнитогорск, Орск, Оренбург, Бердяуш',
        type: 'целевая ',
        period: 'II квартал',
        responsible:
            'Комиссионно, под председательством руководителей или специалистов ЦБТ, НПЦ по ООС',
        result: 'Протокол,  приказ, корректирующие меры'),
  ];

  @override
  void initState() {
    super.initState();
    auth.getUserInfo().then((userInfo) {
      _userInfo = userInfo;
      _year = DateTime.now().year;
      tableName =
          "ПЛАН\nпроведения комплексных аудитов и целевых проверок организации работы по экологической безопасности на ${_year.toString()} год";
      showLoading = false;
      loadData();
      setState(() {});
    });
  }

  void loadData() async {
    List<Map<String, dynamic>> plans = await controllers.PlanController
        .selectAll(); //todo переделать на getByParam (_year, _type, _userInfo.railway_id)
    if (plans != null && plans.length > 0)
      _plan = Plan.fromJson(plans[0]);
    else
      _plan =
          new Plan(type: _type, year: _year, railwayId: _userInfo.railway_id);
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/frameScreen.png"),
                fit: BoxFit.fitWidth)),
        child: showLoading
            ? Text("")
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 70, vertical: 20),
                child: Column(children: [
                  Container(
                    child: Text(tableName ?? "", textAlign: TextAlign.center),
                    width: double.infinity,
                  ),
                  Expanded(
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                        Column(children: [
                          generateTableData(context, planItemHeader, planItems)
                        ])
                      ])),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: getPanel(context),
                    ),
                    width: double.infinity,
                  )
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
            getRowCell(row.filial, row.planItemId, 0),
            getRowCell(row.department, row.planItemId, 1),
            getRowCell(row.type, row.planItemId, 2),
            getRowCell(row.period, row.planItemId, 3),
            getRowCell(row.responsible, row.planItemId, 4),
            getRowCell(row.result, row.planItemId, 5),
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
        text,
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

  List<Widget> getPanel(BuildContext context) {
    List<Widget> result = [];
    result.add(TextIcon(
      icon: Icons.edit,
      text: "Редактировать план",
      onTap: () async {
        // Plan copyPlan = new Plan.fromJson(plan.toJson());
        bool result = await showPlanDialog(_plan);
        if (result != null && result) //иначе перезагружать _plan?
          setState(() {
            //   plan = _plan;
          });
      },
      color: Theme.of(context).primaryColorDark,
    ));
    result.add(TextIcon(
      icon: Icons.add,
      text: "Добавить новую запись",
      onTap: () async {
        PlanItem planItem = new PlanItem(planItemId: -1);
        bool result = await showPlanItemDialog(planItem);
        if (result != null && result)
          setState(() {
            planItems.add(planItem);
            //todo refresh all list?
          });
      },
      color: Theme.of(context).primaryColorDark,
    ));
    result.add(Container(
        margin: EdgeInsets.symmetric(horizontal: 13), child: Text('год')));
    if (_type == 'cbt')
      result.add(Container(
          margin: EdgeInsets.symmetric(horizontal: 13), child: Text('дорога')));
    return result;
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
          forwartPlanInspection(planItemId);
          break;
      }
    });
  }

  Future<void> editPlanItem(int planItemId) async {
    PlanItem planItem =
        planItems.firstWhere((planItem) => planItem.planItemId == planItemId);
    bool result = await showPlanItemDialog(planItem);
    if (result != null && result)
      setState(() {
        //todo refresh all list?
      });
  }

  Future<void> deletePlanItem(int planItemId) async {
    bool result = await showConfirmDialog(
        'Вы уверены, что хотите удлить пункт плана?', context);
    if (result != null && result) {
      PlanItem deletedPlanItem =
          planItems.firstWhere((planItem) => planItem.planItemId == planItemId);
      if (deletedPlanItem == null) return;
      planItems.remove(deletedPlanItem);
      //todo delete from db
      setState(() {});
    }
  }

  Future<void> forwartPlanInspection(int planItemId) async {}

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  Future<bool> showPlanDialog(Plan plan) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return AlertDialog(
               shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
              backgroundColor: Theme.of(context).primaryColor,
              content: Container(
                  width: 500.0,
                  child: Scaffold(
                      backgroundColor: Theme.of(context).primaryColor,
                      body: Form(
                          key: formPlanKey,
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
                                    value: plan.name,
                                    onSaved: (value) => {plan.name = value},
                                    context: context,
                                  ),
                                  EditTextField(
                                    text: 'Год',
                                    value: plan.year,
                                    onSaved: (value) =>
                                        {plan.year = int.tryParse(value)},
                                    context: context,
                                  ),
                                  EditTextField(
                                    text: 'Дата утверждения',
                                    value: plan.dateSet,
                                    onSaved: (value) => {plan.dateSet = value},
                                    context: context,
                                  ),
                                  EditTextField(
                                    text: 'Номер',
                                    //value: plan.,???
                                    onSaved: (value) => {},
                                    context: context,
                                  ),
                                  EditTextField(
                                    text: 'Подписант',
                                    value: "", //plan.userSetName,
                                    onSaved: (value) =>
                                        {}, //plan.userSetName = value},
                                    context: context,
                                  ),
                                ])))),
                            Container(
                                child: MyButton(
                                    text: 'принять',
                                    parentContext: context,
                                    onPress: submitPlan))
                          ]))))));
        });
  }

  Future<bool> showPlanItemDialog(PlanItem planItem) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
              backgroundColor: Theme.of(context).primaryColor,
              content: Container(
                  width: 500.0,
                  child: Scaffold(
                      backgroundColor: Theme.of(context).primaryColor,
                      body: Form(
                          key: formPlanItemKey,
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
                                    text: 'Наименование проверяемого филиала',
                                    value: planItem.filial,
                                    onSaved: (value) =>
                                        {planItem.filial = value},
                                    context: context,
                                    // color: Theme.of(context).primaryColorDark,
                                  ),
                                  EditTextField(
                                    text: 'Подразделение, подлежащее проверке',
                                    value: planItem.department,
                                    onSaved: (value) =>
                                        {planItem.department = value},
                                    context: context,
                                  ),
                                  EditTextField(
                                    text: 'Вид проверки',
                                    value: planItem.type,
                                    onSaved: (value) => {planItem.type = value},
                                    context: context,
                                  ),
                                  EditTextField(
                                    text: 'Срок проведения проверки',
                                    value: planItem.period,
                                    onSaved: (value) =>
                                        {planItem.period = value},
                                    context: context,
                                  ),
                                  EditTextField(
                                    text:
                                        'Ответственные за организацию и проведение проверки',
                                    value: planItem.responsible,
                                    onSaved: (value) =>
                                        {planItem.responsible = value},
                                    context: context,
                                  ),
                                  EditTextField(
                                    text: 'Результаты проведенной проверки',
                                    value: planItem.result,
                                    onSaved: (value) =>
                                        {planItem.result = value},
                                    context: context,
                                  ),
                                ])))),
                            Container(
                                child: MyButton(
                                    text: 'принять',
                                    parentContext: context,
                                    onPress: submitPlanItem))
                          ]))))));
        });
  }

  void submitPlan() {
    final form = formPlanKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool result = true;
      Navigator.pop<bool>(context, result);
      if (result)
        Scaffold.of(context).showSnackBar(successSnackBar);
      else
        Scaffold.of(context).showSnackBar(errorSnackBar);
    }
  }

  void submitPlanItem() {
    final form = formPlanItemKey.currentState;
    hideKeyboard();
    if (form.validate()) {
      form.save();
      bool result = true;
      Navigator.pop<bool>(context, result);
      if (result)
        Scaffold.of(context).showSnackBar(successSnackBar);
      else
        Scaffold.of(context).showSnackBar(errorSnackBar);
    }
  }

  void hideKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
}
