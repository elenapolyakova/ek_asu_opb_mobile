import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';

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
  Inspection({
    this.id,
    this.planItemId,
    this.name,
    this.signerName,
    this.signerPost,
    this.appName,
    this.appPost,
    this.numSet,
  });
}

//todo delete when model exists
class InspectionItem {
  int inspectionId;
  int inspectionItemId;
  int departmentId; //если проверка СП
  int eventId; //для обеда, отъезда, ужина и тд
  String eventName; //событие текстом на случай встреча с руководством и тд
  String dateBegin; //Дата начала проверки
  String dateEnd; //Дата окончания проверки
  InspectionItem(
      {this.inspectionId,
      this.inspectionItemId,
      this.departmentId,
      this.eventId,
      this.eventName,
      this.dateBegin,
      this.dateEnd});
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
  String emptyTableName;
  String _tableName;
  List<InspectionItem> _inspectionItems = <InspectionItem>[
    /*добавить тестовые пункты проверки */
  ];
  List<InspectionItem> inspectionItems = [];


  
  List<Map<String, dynamic>> inspectionItemHeader = [
    {
      'text': 'Дата проверки',
      'flex': 1.0
    },
    {'text': 'Наименование структурного подразделения', 'flex': 4.0},
    {'text': 'Время проверки (мест. вр)', 'flex': 1.0},
    {'text': 'Члены комиссии', 'flex': 1.0}
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
    String tableName = "";
    if (_inspection != null && _inspection.name != null) {
      
        tableName = '${_inspection.name}';
    }

    setState(() => {_tableName = tableName});
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
            addInspectionClicked();
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
                      title: Text(_tableName, textAlign: TextAlign.center),
                      onTap: () {}),
                  Expanded(
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                        Column(children: [
                           generateTableData(context, inspectionItemHeader, inspectionItems)
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
   /* int rowIndex = 0;
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

  Future<void> editInspectionClicked() async {}
  Future<void> addInspectionClicked() async {}
}
