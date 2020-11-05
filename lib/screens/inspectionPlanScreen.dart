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
  List<InspectionItem> _inspectionItems = <InspectionItem>[
    /*добавить тестовые пункты проверки */
  ];
  List<InspectionItem> inspectionItems = [];
  @override
  _InspectionPlanScreen(this.planItem);

  @override
  void initState() {
    super.initState();

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
    return new Text(
        'Здесь будет редактирование плана проверок по ${planItem["typeName"]} ${planItem["filial"]}');
  }
}
