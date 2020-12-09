import 'dart:async';
import 'package:ek_asu_opb_mobile/controllers/syn.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart' as WM;
import 'package:ek_asu_opb_mobile/screens/loginPage.dart';
import 'package:ek_asu_opb_mobile/screens/homeScreen.dart';
import 'package:ek_asu_opb_mobile/screens/screens.dart';
import 'package:ek_asu_opb_mobile/src/exchangeData.dart' as exchange;
import 'utils/authenticate.dart' as auth;
import 'utils/config.dart' as config;
import 'utils/network.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void callbackDispatcher() {
  WM.Workmanager.executeTask((task, inputData) async {
    if (task == 'syn') {
      return SynController.syncTask();
    }
    return false;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Background tasks
  await WM.Workmanager.initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode:
          true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
      );
  await WM.Workmanager.registerPeriodicTask(
    "1", "syn",
    // When no frequency is provided the default 15 minutes is set.
    // Minimum frequency is 15 min. Android will automatically change your frequency to 15 min if you have configured a lower frequency.
    frequency: Duration(minutes: 15),
    constraints: WM.Constraints(
        networkType: WM.NetworkType.connected, requiresDeviceIdle: true),
  );
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(MyApp());
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
String _lastScreen = "";

Timer _pinTimer;

class MyApp extends StatefulWidget {
  static final navKey = new GlobalKey<NavigatorState>();
  const MyApp({Key navKey}) : super(key: navKey);

  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> with WidgetsBindingObserver {
  String _pin;
  bool _showErrorPin = false;
  bool _isPinDialogShow = false;
  bool _isTimeExpire = false;
  bool _showLoading = false;
  final _sizeTextBlack =
      const TextStyle(fontSize: 20.0, color: Color(0xFF252A0E));
  final _sizeTextWhite = const TextStyle(fontSize: 20.0, color: Colors.white);
  final pinFormKey = new GlobalKey<FormState>();
  RouteAwareWidget prevWidget;
  RouteAwareWidget curWidget;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [const Locale('ru', 'RU')],
        navigatorKey: MyApp.navKey,
        theme: ThemeData(
            primaryColor: Color(0xFFADB439), //салатовый
            cardColor: Color(0x00ADB439), //прозрачный,
            accentColor: Color(0xFF465C0B), //оливковый
            primaryColorLight: Color(0xFFEFF0D7), //бежевый
            primaryColorDark: Color(0xFF465C0B), //оливковый
            buttonColor: Color(0xFF252A0E), //почти черный
            backgroundColor: Colors.white,
            focusColor: Color(0xFF465C0B),
            cursorColor: Color(0xFF252A0E),
            bottomAppBarColor: Colors.white,
            shadowColor: Color(0xFFE6E6E6), //cерый для зебры таблицы
            textTheme: TextTheme(bodyText2: TextStyle(color: Colors.black)),
            splashColor: Colors.white),
        navigatorObservers: [routeObserver],
        home: RouteAwareWidget('/home'),
        // child: HomeScreen(context: context, stop: pageStopState['/home']),),
        routes: <String, WidgetBuilder>{
          '/login': (context) => RouteAwareWidget('/login',
              context: context), //, child: LoginPage(context: context)),
          '/home': (context) => RouteAwareWidget('/home', context: context), //
          // child: HomeScreen(context: context, stop: pageStopState['/home'] )),
          '/ISP': (context) => RouteAwareWidget('/ISP',
              context: context), //, child: ISPScreen(context: context)),
          '/inspection': (context) =>
              RouteAwareWidget('/inspection', context: context),
          //  child: InspectionScreen(context: context)),
          '/checkItem': (context) =>
              RouteAwareWidget('/checkItem', context: context),
          // child: CheckScreen(context: context)),
          '/messenger': (context) =>
              RouteAwareWidget('/messenger', context: context),
          //  child: MessengerScreen(/*context: context*/)),

          /* '/planCbt': (context) =>
              RouteAwareWidget('planCbt', child: PlanCbtScreen()),
          '/planCbtEdit': (context) =>
              RouteAwareWidget('planCbtEdit', child: PlanCbtEditScreen()),*/
        });
  }

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_lastScreen == '/login' || _isPinDialogShow) return;
        if (_isTimeExpire) {
          setState(() {
            _isTimeExpire = false;
            showPasswordDialog();
          });
        } else if (_pinTimer != null) _pinTimer.cancel();

        //user returned to our app
        break;
      case AppLifecycleState.paused:
        if (_lastScreen == '/login' || _isPinDialogShow) return;
        //user is about quit our app temporally

        int sessionExpire =
            int.tryParse(config.getItem("sessionExpire").toString());
        Duration seconds = new Duration(
            seconds: (sessionExpire != null ? sessionExpire : 10 * 60));
        _pinTimer = Timer(seconds, sessionExpired);
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.inactive:
        //app is inactive
        break;
    }
  }

  void sessionExpired() {
    setState(() {
      _isTimeExpire = true;
    });
  }

  pinConfirm() async {
    final context = MyApp.navKey.currentState.overlay.context;
    final form = pinFormKey.currentState;
    if (form.validate()) {
      form.save();
      var isPinValid = await auth.isPinValid(_pin);
      if (!isPinValid) {
        setState(() {
          _showErrorPin = true;
        });
        return;
      }
      if (isPinValid) {
        setState(() {
          _isPinDialogShow = false;
          _showErrorPin = false;
          _showLoading = true;
        });
        try {
          checkConnection().then((isConnect) {
            if (isConnect) {
              auth.checkSession(context).then((isSessionExist) {
                if (isSessionExist) {
                  exchange
                      .getDictionaries(all: true, isLastUpdate: true)
                      .then((result) {
                    SynController.loadFromOdoo().then((value) {
                      setState(() {
                        _showLoading = false;
                      });
                      Navigator.pop(context, true);
                    });
                    //?
                  }); //getDictionary
                } //isSessionExist = true
              }); //checkSession
            } //isConnect == true
          });
        } catch (e) {
          Navigator.pop(context, true);
        }
//checkConnection

      }
    }
  }

  showPasswordDialog() {
    if (_isPinDialogShow) return;

    final context = MyApp.navKey.currentState.overlay.context;
    setState(() {
      _isPinDialogShow = true;
    });
    showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Color(0x88E6E6E6),
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0))),
            title: Text("Введите ПИН-код"),
            backgroundColor: Theme.of(context).primaryColor,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                    color: Theme.of(context).primaryColorLight),
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
                                _showErrorPin = false;
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
                                    _showErrorPin ? "Неверный ПИН-код" : '',
                                    style: TextStyle(
                                        color: Colors.redAccent, fontSize: 15),
                                    textAlign: TextAlign.left,
                                  ))),
                          new Container(
                            width: 200,
                            height: 50.0,
                            margin: new EdgeInsets.only(top: 15.0),
                            decoration: new BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              color: Theme.of(context).buttonColor,
                            ),
                            child: new MaterialButton(
                              onPressed: pinConfirm,
                              child: (!_showLoading) ? new Text(
                                "OK",
                                style: _sizeTextWhite,
                              ):  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColorLight),
                                  ),

                            ),
                          )
                        ]))),
          );
        });
  }
}

class RouteAwareWidget extends StatefulWidget {
  final String name;
  BuildContext context;

  // final Widget child;

  RouteAwareWidget(this.name, {this.context});

  @override
  State<RouteAwareWidget> createState() => _RouteAwareWidget(name);
}

class _RouteAwareWidget extends State<RouteAwareWidget> with RouteAware {
  Map<String, bool> stop = {};
  String name;
  @override
  _RouteAwareWidget(this.name);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    setState(() {
      _lastScreen = widget.name;
      stop = {name: false};
    });
  }

  @override
  void didPushNext() {
    setState(() {
      name = widget.name;
      stop = {name: true};
    });
  }

  @override
  void didPop() {
    setState(() {
      name = widget.name;
      stop = {name: true};
    });
  }

  @override
  void didPopNext() {
    setState(() {
      name = widget.name;
      stop = {name: false};
    });
  }

  @override
  build(BuildContext context) {
// return widget.child;
    switch (name) {
      case '/login':
        return LoginPage(context: context);
      case '/home':
        return HomeScreen(
            context: context, stop: stop != null ? stop[name] : null);
      case '/ISP':
        return ISPScreen(
            context: context, stop: stop != null ? stop[name] : null);
      case '/inspection':
        return InspectionScreen(
            context: context, stop: stop != null ? stop[name] : null);
      case '/checkItem':
        return CheckScreen(
            context: context, stop: stop != null ? stop[name] : null);
      case '/messenger':
        return MessengerScreen(
            context: context, stop: stop != null ? stop[name] : null);
    }
  }
}
