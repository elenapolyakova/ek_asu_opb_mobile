import 'dart:ui';

import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/src/exchangeData.dart' as exchange;
import 'package:ek_asu_opb_mobile/utils/network.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';
import 'package:ek_asu_opb_mobile/screens/screens.dart' as screens;
import 'package:ek_asu_opb_mobile/utils/config.dart' as config;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ek_asu_opb_mobile/controllers/syn.dart';
import 'package:flutter/services.dart';


final _storage = FlutterSecureStorage();

class HomeScreen extends StatefulWidget {
  BuildContext context;
  bool stop;

  HomeScreen({this.context, this.stop});
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
  String errorPin = '';

  final _sizeTextWhite = const TextStyle(fontSize: 20.0, color: Colors.white);
  final _sizeTextBlack =
      const TextStyle(fontSize: 20.0, color: Color(0xFF252A0E));

  var pinFormKey = new GlobalKey<FormState>();
  String _pin;

  Map<String, dynamic> screenList = {};
  bool isSyncData = false;

//SpinKitFadingCircle(color: Color(0xFFADB439));

  List<dynamic> logRows = []; // = ['test', 'test2'];
  void hideLoading() {
    setState(() {
      showLoading = false;
      hideDialog(context);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    auth.getBaseUrl().then((baseUrl) {
      auth.setBaseUrl(baseUrl).then((isSet) {
        auth.getDB().then((db) {
          auth.setDB(db).then((isSet) {
            auth.checkLoginStatus(context).then((isLogin) {
              if (isLogin) {
                showLoadingDialog(context);
                auth.getUserInfo().then((userInfo) {
                  _userInfo = userInfo;
                  _navigationMenu = getNavigationMenu(userInfo.f_user_role_txt);
                  setState(() {});

                  try {
                    if (arguments == null || arguments['showPin'])
                      showPasswordDialog(setState);
                    else if (arguments != null && arguments['load']) {
                      fistLoadData();
                    } else
                      hideLoading();
                  } catch (e) {
                    hideLoading();
                  } finally {}

                  //checkConnection
                });
              } //isLogin == true
            }); //checkLoginStatus
          }); //setBaseUrl
        }); //getBaseUrl
      }); //setBaseUrl
    }); //getBaseUrl
  }

  fistLoadData() {
    checkConnection().then((isConnect) {
      if (isConnect) {
        auth.checkSession(context).then((isSessionExist) {
          if (isSessionExist) {
            exchange.getDictionaries(all: true).then((result) {
              SynController.loadFromOdoo().then((value) {
                hideLoading();
              }).catchError((err) {
                hideLoading();
              });
            }).catchError((err) {
              hideLoading();
            });
            //getDictionary
          } //isSessionExist = true
        }); //checkSession

      } //isConnect == true
    });
  }



  showPasswordDialog(StateSetter setState) {

    _storage.write(key: 'isHomePinDialogShow', value: 'true');
   
    showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
              title: Text("Введите ПИН-код"),
              backgroundColor: Theme.of(context).primaryColor,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              content: new Form(
                  key: pinFormKey,
                  child: new Container(
                      height: 150,
                      child: new Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Container(
                              decoration: new BoxDecoration(
                                border: Border.all(
                                    color: Theme.of(context).primaryColorLight,
                                    width: 1.5),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Colors.white,
                              ),
                              height: 56,
                              child: new TextFormField(
                                decoration: new InputDecoration(
                                  prefixIcon: Icon(Icons.vpn_key,
                                      color:
                                          Theme.of(context).primaryColorLight),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide.none),
                                ),
                                // inputFormatters: [widget._amountValidator],
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly
                                ], // Only numbers can be entered
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                maxLines: 1,
                                maxLength: 5,
                                obscureText: true,
                                cursorColor: Theme.of(context).cursorColor,
                                style: _sizeTextBlack,
                                onSaved: (val) => _pin = val,
                                onTap: () => setState(() {
                                  errorPin = '';
                                }),
                                /*validator: (val) => val.length < 5
                                ? "ПИН-код должен состоять из 5 цифр"
                                : null*/
                              ),
                            ),
                            new Expanded(
                                child: new Container(
                                    padding: new EdgeInsets.all(5.0),
                                    child: new Text(
                                      errorPin,
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 15),
                                      textAlign: TextAlign.left,
                                    ))),
                            new Container(
                              width: 200,
                              height: 40.0,
                              margin: new EdgeInsets.only(top: 15.0),
                              decoration: new BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                color: Theme.of(context).buttonColor,
                              ),
                              child: new MaterialButton(
                                  onPressed: () => pinConfirm(setState),
                                  child: new Text(
                                    "OK",
                                    style: _sizeTextWhite,
                                  )),
                            ),
                            Container(
                                padding: EdgeInsets.only(top: 10),
                                child: GestureDetector(
                                  onTap: () => showAlertDialog(context),
                                    child: Text(
                                  'Войти с помощью логина и пароля',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColorDark,
                                      decoration: TextDecoration.underline),
                                )))
                          ]))),
            );
          });
        });
  }

  pinConfirm(setState) async {
    final form = pinFormKey.currentState;
    if (form.validate()) {
      form.save();
      var isPinValid = await auth.isPinValid(_pin);
      if (!isPinValid) {
        setState(() {
          errorPin = 'Неверный ПИН-код';
          // pinFormKey = new GlobalKey();
        });
        return;
      }
      if (isPinValid) {
        setState(() {
          errorPin = '';
        });

        Navigator.pop(context, true);
        _storage.write(key: 'isHomePinDialogShow', value: 'false');

        if (arguments != null && arguments['load']) {
          fistLoadData();
        } else
          hideLoading();
      }
    }
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
    });
    if (role_txt == config.getItem('cbtRole')) {
      result.add({
        'key': 'checkListTemplate',
        'label': 'Шаблоны',
        'icon': Icon(Icons.fact_check)
      });
    }*/

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
      case "map":
        screenList[screenKey] = screens.MapScreen();
        break;
      case "report":
        screenList[screenKey] = screens.ReportScreen();
        break;
      case "checkListTemplate":
        // screenList[screenKey] = screens.CheckListTemplateScreen();
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
    // print('stop: ' + (widget.stop != null ? widget.stop.toString() : 'null'));
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
                    showBack: (arguments != null && !arguments['load']),
                    userInfo: _userInfo,
                    parentScreen: 'homeScreen',
                    stop: widget.stop,
                    syncTask: syncTask)),
            body: getBodyContent(isSyncData),
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
