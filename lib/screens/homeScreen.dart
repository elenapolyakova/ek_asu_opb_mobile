import 'dart:ui';

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
import 'package:ek_asu_opb_mobile/utils/dictionary.dart';

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
  String errorText = '';
  int _year;
  int _railway_id;
  int _checkPlanId;

  List<Map<String, dynamic>> yearList;
  List<Map<String, dynamic>> railwayList;

  final _sizeTextWhite = const TextStyle(fontSize: 20.0, color: Colors.white);
  final _sizeTextBlack =
      const TextStyle(fontSize: 20.0, color: Color(0xFF252A0E));

  var pinFormKey = new GlobalKey<FormState>();
  String _pin;

  Map<String, dynamic> screenList = {};
  bool isSyncData = false;

  void hideLoading() {
    setState(() {
      hideDialog(context);
      showLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    // initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initialize();
    });
    //WidgetsFlutterBinding.ensureInitialized();
  }

  Future<void> initialize() async {
    arguments = ModalRoute.of(context).settings.arguments;

    String baseUrl = await auth.getBaseUrl();
    await auth.setBaseUrl(baseUrl);
    String db = await auth.getDB();
    await auth.setDB(db);

    try {
      bool isLogin = await auth.checkLoginStatus(context);
      if (isLogin) {
        showLoadingDialog(context);
        _userInfo = await auth.getUserInfo();
        if (arguments == null || arguments['showPin'])
          await showPasswordDialog(setState);
        if (arguments != null && arguments['load']) await fistLoadData();
        await loadData();

        hideLoading();
        setState(() {});
      }
    } catch (e) {
      hideLoading();
    }
  }

  fistLoadData() async {
    bool isConnect = await checkConnection();
    if (isConnect) {
      bool isSessionExist = await auth.checkSession(context);
      if (isSessionExist) {
        await exchange.getDictionaries(all: true);
        await SynController.loadFromOdoo();
      }
    }
  }

  Future<bool> showPasswordDialog(StateSetter setState) {
    _storage.write(key: 'isHomePinDialogShow', value: 'true');

    return showDialog<bool>(
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
                                          color: Theme.of(context)
                                              .primaryColorDark,
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
          _pin = '';
        });

        Navigator.pop(context, true);
        _storage.write(key: 'isHomePinDialogShow', value: 'false');
        await SynController.syncTask();
      }
    }
  }

  Future<bool> reloadParam() async {
    await loadData();
    setState(() {});

    return true;
  }

  Future<bool> loadData() async {
    _year = await auth.getYear();
    _railway_id = await auth.getRailway();
    _checkPlanId = await auth.getCheckPlanId();

    yearList = getYearList(_year);
    railwayList = await getRailwayList();

    return true;
  }

  List<Map<String, dynamic>> getYearList(int year) {
    List<Map<String, dynamic>> yearList = [];
    for (int i = year - 1; i <= year + 1; i++)
      yearList.add({"id": i, "value": i});
    return yearList;
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

  bool isUserCbt() {
    return (_userInfo.f_user_role_txt == config.getItem('cbtRole'));
  }

  @override
  Widget build(BuildContext context) {
    double width = 400;

    /*setState(() {
      arguments = ModalRoute.of(context).settings.arguments;
    });*/

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
            body: Container(
                padding: EdgeInsets.only(left: 40, top: 10),
                //color: Colors.white,
                child: Column(children: [
                  Expanded(
                      child: Row(
                    children: [
                      Container(
                          width: width,
                          child: Column(
                            // mainAxisAlignment:
                            //     MainAxisAlignment.spaceEvenly,
                            children: [
                              Container(
                                  height: 70,
                                  width: width,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: MyDropdown(
                                          text: 'Год',
                                          width: 300,
                                          dropdownValue: _year.toString(),
                                          items: yearList,
                                          onChange: (value) async {
                                            setState(() {
                                              _year = int.parse(value);

                                              // reloadPlan();
                                            });
                                            await auth.setYear(_year);
                                          },
                                          parentContext: context,
                                        ),
                                      ),
                                      (isUserCbt())
                                          ? Expanded(
                                              flex: 3,
                                              child: Container(
                                                padding:
                                                    EdgeInsets.only(left: 10),
                                                child: MyDropdown(
                                                  text: 'Дорога',
                                                  width: 300,

                                                  dropdownValue: _railway_id !=
                                                          null
                                                      ? _railway_id.toString()
                                                      : null, //"0",
                                                  items: railwayList,
                                                  onChange: (value) async {
                                                    setState(() {
                                                      _railway_id =
                                                          int.parse(value);

                                                      //  reloadPlan();
                                                    });
                                                    await auth.setRailway(
                                                        _railway_id);
                                                  },
                                                  parentContext: context,
                                                ),
                                              ),
                                            )
                                          : Expanded(
                                              child: Text(''),
                                            ),
                                    ],
                                  )),
                              Expanded(
                                  child: Container(
                                height:
                                    MediaQuery.of(context).size.height - 100,
                                child: ListView(
                                  children: [
                                    if (isUserCbt())
                                      MyTile('План ЦБТ', () {
                                        Navigator.pushNamed(context, '/plan',
                                                arguments: {'type': 'cbt'})
                                            .then((value) async =>
                                                await reloadParam());
                                      }, width: width),
                                    MyTile('План НЦОП', () {
                                      Navigator.pushNamed(context, '/plan',
                                              arguments: {'type': 'ncop'})
                                          .then((value) async =>
                                              await reloadParam());
                                    }, width: width),
                                    MyTile(
                                        'План корректирующих действий', () {},
                                        width: width, disabled: true),
                                    MyTile('Внеплановые проверки', () {},
                                        width: width, disabled: true),
                                    MyTile(
                                      'Текущая проверка',
                                      () {
                                        Navigator.pushNamed(
                                            context, '/checkItem');
                                      },
                                      width: width,
                                      disabled: _checkPlanId == null,
                                    ),
                                  ],
                                ),
                              ))
                            ],
                          )),
                      Expanded(
                          child: Container(
                              child: Image(
                                  image: AssetImage("assets/images/tree_1.png"),
                                  fit: BoxFit.fitHeight)))
                    ],
                  )),
                  Container(
                      height: 20,
                      //width: double.infinity,
                      color: (errorText != "")
                          ? Color(0xAAE57373)
                          : Color(0x00E57373),
                      child: Text('$errorText',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF252A0E))))
                ])));
  }
}
