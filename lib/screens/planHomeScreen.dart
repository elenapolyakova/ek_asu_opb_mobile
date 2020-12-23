import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/screens/screens.dart' as screens;
import 'package:ek_asu_opb_mobile/controllers/syn.dart';
import 'dart:async';
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;

class PlanHomeScreen extends StatefulWidget {
  BuildContext context;
  bool stop;

  @override
  PlanHomeScreen({this.context, this.stop});
  @override
  State<PlanHomeScreen> createState() => _PlanHomeScreen();
}

class _PlanHomeScreen extends State<PlanHomeScreen> {
  UserInfo _userInfo;
  List<Map<String, dynamic>> _navigationMenu;
  int _selectedIndex = 0;
  bool showLoading = true;
  final sizeTextBlack = TextStyle(fontSize: 17.0, color: Color(0xFF252A0E));
  Map<String, dynamic> planItem;
  Map<String, dynamic> arguments;
  String errorText;
  bool isSyncData = false;



  Map<String, dynamic> screenList = {};

//SpinKitFadingCircle(color: Color(0xFFADB439));

  List<dynamic> logRows = []; // = ['test', 'test2'];

  int getIndexByName(String name) {
    return _navigationMenu.indexWhere((menuItem) => menuItem['key'] == name);
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    auth.getUserInfo().then((userInfo) {
      _userInfo = userInfo;
      _navigationMenu = getNavigationMenu(userInfo.f_user_role_txt);
      setState(() {
        arguments = ModalRoute.of(context).settings.arguments;
        if (arguments != null) {
          _selectedIndex = getIndexByName(arguments["type"]);
          /*if (arguments["type"] == 'cbt')
            _selectedIndex = 0;
          else if (arguments["type"] == 'ncop') _selectedIndex = 1;*/
        }
      });

      errorText = '';
      loadData();
    });
  }

  loadData() {
    showLoading = false;
    setState(() {});
  }

  List<Map<String, dynamic>> getNavigationMenu(String role_txt) {
    List<Map<String, dynamic>> result = [];
    if (role_txt == config.getItem('cbtRole')) {
      result.add(
          {'key': 'cbt', 'label': 'План ЦБТ', 'icon': Icon(Icons.description)});
    }
    result.add(
        {'key': 'ncop', 'label': 'План НЦОП', 'icon': Icon(Icons.description)});

    return result;
  }

  Future<void> syncTask() async {
    showLoadingDialog(context);
    try {
      bool result = await SynController.syncTask();
    } catch (e) {} finally {
      hideDialog(context);
    }
    setState(() {
      isSyncData = true;
    });
  }

  void syncComplete() {
    setState(() {
      isSyncData = false;
    });
  }

  Widget getBodyContent(bool isSyncData) {
    String screenKey = _navigationMenu[_selectedIndex]["key"];
    if (!isSyncData) if (screenList[screenKey] != null)
      return screenList[screenKey];
    switch (screenKey) {
      case "cbt":
        screenList[screenKey] =
            screens.PlanScreen(type: screenKey, key: GlobalKey());
        break;
      case "ncop":
        screenList[screenKey] =
            screens.PlanScreen(type: screenKey, key: GlobalKey());
        break;

      default:
        return Text("");
    }
    return screenList[screenKey] ?? Text("");
  }

  @override
  Widget build(BuildContext context) {
    //, controller: _controller);
    return showLoading
        ? new ConstrainedBox(
            child:
                new Container(decoration: BoxDecoration(color: Colors.white)),
            constraints: BoxConstraints.tightFor(
                height: double.infinity, width: double.infinity),
          )
        : new Scaffold(
            appBar: PreferredSize(
                preferredSize: Size.fromHeight(100),
                child: MyAppBar(
                    userInfo: _userInfo,
                    syncTask: syncTask,
                    parentScreen: 'planHomeScreen',
                    stop: widget.stop)),
            body: Column(children: [
              getBodyContent(isSyncData),
              //  if (errorText != '')
              Container(
                  height: 20,
                  width: double.infinity,
                  color:
                      (errorText != "") ? Color(0xAAE57373) : Color(0x00E57373),
                  child: Text('$errorText',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF252A0E))))
            ]),
            bottomNavigationBar: (_navigationMenu.length > 1)
                ? BottomNavigationBar(
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
                                icon: _navigationMenu[i]["icon"])))
                : null,
          );
  }
}
