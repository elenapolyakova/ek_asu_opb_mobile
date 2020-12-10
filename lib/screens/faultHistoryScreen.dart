import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/screens/screens.dart' as screens;
import 'dart:collection';

class FaultHistoryScreen extends StatefulWidget {
  int departmentId;
  bool isSyncData;
  int checkPlanItemId;

  FaultHistoryScreen(this.departmentId, this.checkPlanItemId, this.isSyncData) {
    createState();
  }

  @override
  _FaultHistoryScreen createState() =>
      _FaultHistoryScreen(departmentId, checkPlanItemId, this.isSyncData);
}

class _FaultHistoryScreen extends State<FaultHistoryScreen> {
  UserInfo _userInfo;
  bool showLoading = true;

  int departmentId;
  int checkPlanItemId;
  int faultId;
  int faultFixId;
  dynamic _args;

  Map<String, dynamic> _screenList = {};
  bool _isSyncData;
  String _selectedPage = '';

  _FaultHistoryScreen(
      this.departmentId, this.checkPlanItemId, this._isSyncData) {
    //checkPlanItemId = parCheckPlanItemId;
    //Manager.manager.checkPlanItemId = parCheckPlanItemId;
  }
  Queue<Map<String, String>> _navigation = Queue<Map<String, String>>();

  @override
  void initState() {
    print('initState');
    super.initState();

    setState(() {
      showLoading = false;
      _selectedPage = 'faultList';
    });
  }

  void push(Map<String, String> route, dynamic args) {
    setState(() {
      _navigation.addLast(route);
      _selectedPage = route['pathTo'];

      if (args != null) {
        _args = args;

        faultId = args['faultId'] ?? faultId;
        faultFixId = args['faultFixId'] ?? faultFixId;
      }
    });
  }

  Map<String, String> pop() {
    if (_navigation != null && _navigation.length > 0) {
      setState(() {
        dynamic route = _navigation.removeLast();
        _selectedPage = route["pathFrom"];
        return route;
      });
    }
    return null;
  }

  Widget getBodyContenet(bool _isSyncData) {
    //String screenKey = _navigation[_selectedPage];
    //if (_screenList[_selectedPage] != null) return _screenList[_selectedPage];

    switch (_selectedPage) {
      case "faultList":
        _screenList[_selectedPage] = screens.FaultListScreen(
          
          departmentId: departmentId,
          push: push,
          pop: pop,
          key: GlobalKey(),
          checkPlanItemId: checkPlanItemId
        );
        break;

      case "fault":
        _screenList[_selectedPage] =
            screens.FaultScreen(faultId, null, push, pop, GlobalKey());

        break;
      case "faultFixList":
        _screenList[_selectedPage] =
            screens.FaultFixListScreen(faultId, push, pop, GlobalKey());

        break;

      case "faultFix":
        _screenList[_selectedPage] =
            screens.FaultFixScreen(faultFixId, faultId, push, pop, GlobalKey());

        break;

      default:
        return Text("");
    }
    return _screenList[_selectedPage] ?? Text("");
  }

  @override
  Widget build(BuildContext context) {
    Map<String, String> route =
        _navigation != null && _navigation.length > 0 ? _navigation.last : null;

    return Expanded(
        child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/frameScreen.png"),
                    fit: BoxFit.fill)),
            child: showLoading
                ? Text("")
                : Column(children: [
                    Container(
                        child: route != null
                            ? TextIcon(
                                icon: Icons.arrow_back_ios,
                                text: route["text"],
                                onTap: () {
                                  return pop();
                                })
                            //  Text(route["text"])
                            : Text('')),
                    Expanded(child: getBodyContenet(_isSyncData)),
                  ])));
  }
}
