import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/src/exchangeData.dart' as exchange;
import 'package:ek_asu_opb_mobile/utils/network.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/screens/screens.dart' as screens;
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ek_asu_opb_mobile/controllers/syn.dart';

class HomeScreen extends StatefulWidget {
  BuildContext context;

  HomeScreen({this.context});
  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  UserInfo _userInfo;
  List<Map<String, dynamic>> _navigationMenu;
  int _selectedIndex = 0;
  bool showLoading = true;
  final sizeTextBlack = TextStyle(fontSize: 17.0, color: Color(0xFF252A0E));
  final spinkit = SpinKitFadingCircle(color: Color(0xFFADB439));
  Map<String, dynamic> arguments;

  Map<String, dynamic> screenList = {};

//SpinKitFadingCircle(color: Color(0xFFADB439));

  List<dynamic> logRows = []; // = ['test', 'test2'];

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        showLoadingDialog(context);
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;
          _navigationMenu = getNavigationMenu(userInfo.f_user_role_txt);
          setState(() {});

          try {
            if (arguments == null || arguments['first']) {
              checkConnection().then((isConnect) {
                if (isConnect) {
                  auth.checkSession(context).then((isSessionExist) {
                    if (isSessionExist) {
                      try {
                        exchange.getDictionaries(all: true).then((result) {});
                      } catch (e) {} //getDictionary
                    } //isSessionExist = true
                  }); //checkSession

                } //isConnect == true
              });
            }
          } catch (e) {} finally {
            setState(() {
              showLoading = false;
              hideDialog(context);
            });
          }

          //checkConnection
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  List<Map<String, dynamic>> getNavigationMenu(String role_txt) {
    List<Map<String, dynamic>> result = [];
    if (role_txt == config.getItem('cbtRole')) {
      result.add(
          {'key': 'cbt', 'label': 'План ЦБТ', 'icon': Icon(Icons.description)});
    }
    result.add(
        {'key': 'ncop', 'label': 'План НЦОП', 'icon': Icon(Icons.description)});
    /*  result
        .add({'key': 'map', 'label': 'Карта', 'icon': Icon(Icons.location_on)});
    result.add({
      'key': 'report',
      'label': 'Отчеты',
      'icon': Icon(Icons.insert_drive_file)
    });*/
    if (role_txt == config.getItem('cbtRole')) {
      result.add({
        'key': 'checkListTemplate',
        'label': 'Шаблоны',
        'icon': Icon(Icons.fact_check)
      });
    }

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
      case "cbt":
        screenList[screenKey] =
            screens.PlanScreen(type: screenKey, key: GlobalKey());
        break;
      case "ncop":
        screenList[screenKey] =
            screens.PlanScreen(type: screenKey, key: GlobalKey());
        break;
      case "map":
        screenList[screenKey] = screens.MapScreen();
        break;
      case "report":
        screenList[screenKey] = screens.ReportScreen();
        break;
      case "checkListTemplate":
        screenList[screenKey] = screens.CheckListTemplateScreen();
        break;
      default:
        return Text("");
    }
    return screenList[screenKey] ?? Text("");
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      arguments = ModalRoute.of(context).settings.arguments;
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
                leading: null,
                title: TextIcon(
                    icon: Icons.account_circle_rounded,
                    text: '${_userInfo != null ? _userInfo.display_name : ""}',
                    onTap: null,
                    color: Theme.of(context).primaryColorLight),
                automaticallyImplyLeading:
                    arguments != null && !arguments['first'],
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

            body: getBodyContent(),
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
                                  icon: _navigationMenu[i]["icon"],
                                )))
                : null,
          );
  }
}
