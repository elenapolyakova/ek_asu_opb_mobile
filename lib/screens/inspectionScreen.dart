import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/screens/screens.dart' as screens;
import 'package:ek_asu_opb_mobile/controllers/syn.dart';
import 'dart:async';

class InspectionScreen extends StatefulWidget {
  BuildContext context;

  @override
  InspectionScreen({this.context});
  @override
  State<InspectionScreen> createState() => _InspectionScreen();
}

class _InspectionScreen extends State<InspectionScreen> {
  UserInfo _userInfo;
  List<Map<String, dynamic>> _navigationMenu;
  int _selectedIndex = 0;
  bool showLoading = true;
  final sizeTextBlack = TextStyle(fontSize: 17.0, color: Color(0xFF252A0E));
  Map<String, dynamic> planItem;
  int _checkPlanId;
  String errorText;

  Map<String, dynamic> screenList = {};

//SpinKitFadingCircle(color: Color(0xFFADB439));

  List<dynamic> logRows = []; // = ['test', 'test2'];

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    auth.getUserInfo().then((userInfo) {
      _userInfo = userInfo;
      _navigationMenu = getNavigationMenu();
      errorText = '';
      showLoading = false;
      setState(() {});
    });
  }

  List<Map<String, dynamic>> getNavigationMenu() {
    List<Map<String, dynamic>> result = [];

    result.add({
      'key': 'inspection',
      'label': 'План проверки',
      'icon': Icon(Icons.description)
    });
    result.add({
      'key': 'commission',
      'label': 'Комиссия',
      'icon': Icon(Icons.supervisor_account_outlined)
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

  void setCheckPlanId(int checkPlanId) {
    setState(() {
      _checkPlanId = checkPlanId;
    });
  }

  void showError() {
    setState(() {
      errorText = 'Сначала сохраните реквизиты плана проверок';
    });
    Timer(new Duration(seconds: 3), () {
      setState(() {
        errorText = "";
      });
    });
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
      case 'inspection':
        screenList[screenKey] =
            screens.InspectionPlanScreen(context, planItem, setCheckPlanId);
        break;
      case "map":
        screenList[screenKey] = screens.MapScreen(checkPlanId: _checkPlanId);
        break;
      case "report":
        screenList[screenKey] = screens.ReportScreen();
        break;
      case "checkList":
        //  screenList[screenKey] = screens.CheckListScreen(null);
        break;
      case "commission":
        screenList[screenKey] = screens.CommissionScreen(context, _checkPlanId);
        break;
      default:
        return Text("");
    }
    return screenList[screenKey] ?? Text("");
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      planItem = ModalRoute.of(context).settings.arguments;
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
            appBar: PreferredSize(
                preferredSize: Size.fromHeight(100),
                child: MyAppBar(userInfo: _userInfo, syncTask: syncTask)),
            body: Column(children: [
              getBodyContent(),
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
            bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Theme.of(context).bottomAppBarColor,
                selectedItemColor: Theme.of(context).primaryColorDark,
                unselectedItemColor: Theme.of(context).primaryColor,
                selectedFontSize: 14,
                unselectedFontSize: 14,
                onTap: (value) {
                  if (_checkPlanId != null)
                    setState(() {
                      _selectedIndex = value;

                      // selectedMenu = _navigationMenu[value]["key"];
                    });
                  else if (value != 0)
                    showError();
                  else
                    setState(() {
                      _selectedIndex = value;
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
