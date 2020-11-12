import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/screens/screens.dart' as screens;
import 'package:ek_asu_opb_mobile/controllers/syn.dart';
import 'dart:async';

class CheckScreen extends StatefulWidget {
  BuildContext context;

  @override
  CheckScreen({this.context});
  @override
  State<CheckScreen> createState() => _CheckScreen();
}

class _CheckScreen extends State<CheckScreen> {
  UserInfo _userInfo;
  List<Map<String, dynamic>> _navigationMenu;
  int _selectedIndex = 0;
  bool showLoading = true;
  final sizeTextBlack = TextStyle(fontSize: 17.0, color: Color(0xFF252A0E));
  Map<String, dynamic> checkPlanItem;
  int _checkPlanItemId;

  Map<String, dynamic> screenList = {};

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    auth.getUserInfo().then((userInfo) {
      _userInfo = userInfo;
      _navigationMenu = getNavigationMenu();
      showLoading = false;
      setState(() {});
    });
  }

  List<Map<String, dynamic>> getNavigationMenu() {
    List<Map<String, dynamic>> result = [];

    result.add({'key': 'info', 'label': 'Общее', 'icon': Icon(Icons.info)});
    result.add({
      'key': 'checkList',
      'label': 'Чек-листы',
      'icon': Icon(Icons.fact_check)
    });
    result
        .add({'key': 'map', 'label': 'Карта', 'icon': Icon(Icons.location_on)});

    result.add({
      'key': 'report',
      'label': 'Отчеты',
      'icon': Icon(Icons.insert_drive_file)
    });
    /*  result.add({
      'key': 'checkList',
      'label': 'Чек-листы',
      'icon': Icon(Icons.fact_check)
    });*/

    return result;
  }

  void LogOut() {
    auth.LogOut(context);
  }

  void toISPScreen() {
    Navigator.pushNamed(
      context,
      '/ISP',
    );
  }

  Future<void> syncTask() async {
    showLoadingDialog(context);
    try {
      bool result = await SynController.syncTask();
    } catch (e) {} finally {
      hideDialog(context);
    }
  }

  Widget getBodyContent() {
    String screenKey = _navigationMenu[_selectedIndex]["key"];
    if (screenList[screenKey] != null) return screenList[screenKey];
    switch (screenKey) {
      case 'info':
        screenList[screenKey] = screens.InfoCheckScreen(context, _checkPlanItemId);
        break;
      case "map":
        screenList[screenKey] = screens.MapScreen();
        break;
      case "report":
        screenList[screenKey] = screens.ReportScreen();
        break;
      case "checkList":
        screenList[screenKey] = screens.CheckListScreen();
        break;
      default:
        return Text("");
    }
    return screenList[screenKey] ?? Text("");
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      checkPlanItem = ModalRoute.of(context).settings.arguments;
      _checkPlanItemId = checkPlanItem["id"];
    });
    //, controller: _controller);
    return showLoading
        ? new ConstrainedBox(
            child:
                new Container(decoration: BoxDecoration(color: Colors.white)),
            constraints: BoxConstraints.tightFor(
                height: double.infinity, width: double.infinity),
          )
        : new Scaffold(
            appBar: new AppBar(
                //leading: null,
                title: TextIcon(
                    icon: Icons.account_circle_rounded,
                    text: '${_userInfo != null ? _userInfo.display_name : ""}',
                    onTap: null,
                    color: Theme.of(context).primaryColorLight),
                //  automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).primaryColorDark,
                actions: <Widget>[
                  TextIcon(
                      icon: Icons.cached,
                      text: 'Синхронизировать',
                      onTap: syncTask,
                      color: Theme.of(context).primaryColorLight),
                  TextIcon(
                      icon: Icons.plagiarism,
                      text: 'ИСП',
                      onTap: toISPScreen,
                      color: Theme.of(context).primaryColorLight),
                  Padding(
                      padding: EdgeInsets.only(right: 26),
                      child: TextIcon(
                          icon: Icons.exit_to_app,
                          text: 'Выход',
                          onTap: LogOut,
                          color: Theme.of(context).buttonColor)),
                ]),
            /*floatingActionButton: FloatingActionButton.extended(
          onPressed: () => UrlLauncher.launch("tel://$_supportPhoneNumber"),
          label: Text('Служба поддержки'),
          icon: Icon(Icons.phone),
          backgroundColor: Colors.green,
        ),*/

            body: Column(children: [
              getBodyContent(),
              //  if (errorText != '')
             
            ]),
            bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).bottomAppBarColor,
                selectedItemColor: Theme.of(context).primaryColorDark,
                unselectedItemColor: Theme.of(context).primaryColor,
                selectedFontSize: 14,
                unselectedFontSize: 14,
                onTap: (value) {
                
                    setState(() {
                      _selectedIndex = value;

                      // selectedMenu = _navigationMenu[value]["key"];
                    });
                 
                },
                currentIndex: _selectedIndex,
                items: _navigationMenu == null
                    ? []
                    : List.generate(
                        _navigationMenu.length,
                        (i) => BottomNavigationBarItem(
                              label: _navigationMenu[i]["label"],
                              icon: _navigationMenu[i]["icon"],
                            ))),
          );
  }
}
