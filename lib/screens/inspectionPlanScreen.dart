import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/screens/planScreen.dart'; //todo delete when model PlanItem exists

class InspectionPlanScreen extends StatefulWidget {
  BuildContext context;
  PlanItem planItem;

  @override
  InspectionPlanScreen(this.context, this.planItem);

  @override
  State<InspectionPlanScreen> createState() =>
      _InspectionPlanScreen(planItem);
}

class _InspectionPlanScreen extends State<InspectionPlanScreen> {
  UserInfo _userInfo;
  PlanItem planItem;
  @override
  _InspectionPlanScreen(this.planItem);
  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;

          setState(() {});
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  @override
  Widget build(BuildContext context) {
    return new Text(
        "Здесь будет редактирование плана проверок по ${planItem.filial}");
  }
}
