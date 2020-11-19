import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/screens/screens.dart' as screens;
import 'dart:collection';

class CheckListManagerScreen extends StatefulWidget {
  int checkPlanItemId;

  CheckListManagerScreen(this.checkPlanItemId);

  @override
  State<CheckListManagerScreen> createState() =>
      _CheckListManagerScreen(checkPlanItemId);
}

class _CheckListManagerScreen extends State<CheckListManagerScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  int checkPlanItemId;
  int checkListId;
  int checkListItemId;
  int faultId;
  dynamic _args;
  String checkListName;
  String checkListItemName;
  Map<String, dynamic> _screenList = {};
  String _selectedPage = '';
  _CheckListManagerScreen(this.checkPlanItemId);
  Queue<Map<String, String>> _navigation = Queue<Map<String, String>>();

  // List<Map<String, Object>> typeCheckListList;
  List<Map<String, Object>> typeCheckListListAll;
  int _selectedType = 0;

  @override
  void initState() {
    super.initState();

    setState(() {
      showLoading = false;
      _selectedPage = 'checkList';
    });
  }

  void push(Map<String, String> route, dynamic args) {
    setState(() {
      _navigation.addLast(route);
      _selectedPage = route['pathTo'];

      if (args != null) {
        _args = args;
        checkListId = args['checkListId'] ?? checkListId;
        checkListItemId = args['checkListItemId'] ?? checkListItemId;
        faultId = args['faultId'] ?? faultId;
        checkListName = args['checkListName'] ?? checkListName;
        checkListItemName = args['checkListItemName'] ?? checkListItemName;
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

  Widget getBodyContenet() {
    //String screenKey = _navigation[_selectedPage];
    //if (_screenList[_selectedPage] != null) return _screenList[_selectedPage];

    switch (_selectedPage) {
      case 'checkList':
        _screenList[_selectedPage] =
            screens.CheckListScreen(checkPlanItemId, push, pop);

        break;
      case "checkListItem":
        _screenList[_selectedPage] = screens.CheckListItemScreen(
          checkListId,
          push,
          pop,
          checkListName: checkListName,
        );

        break;
      case "faultList":
        _screenList[_selectedPage] = screens.FaultListScreen(
            checkListItemId, push, pop,
            checkListItemName: checkListItemName);
        break;

      case "fault":
        _screenList[_selectedPage] = screens.FaultScreen(faultId, push, pop);

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
                    fit: BoxFit.fitWidth)),
            child: showLoading
                ? Text("")
                : Column(children: [
                    Container(
                        child: route != null
                            ? TextIcon(
                                icon: Icons.arrow_back,
                                text: route["text"],
                                onTap: () {
                                  return pop();
                                })
                            //  Text(route["text"])
                            : Text('')),
                    Expanded(child: getBodyContenet()),
                  ])));
  }
}
