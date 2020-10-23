import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/loginPage.dart';
import 'package:ek_asu_opb_mobile/homeScreen.dart';
import 'package:ek_asu_opb_mobile/planCbtScreen.dart';
import 'package:ek_asu_opb_mobile/planCbtEditScreen.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'utils/authenticate.dart' as auth;
import 'dart:async';
import 'utils/config.dart' as config;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft])
      .then((_) {
    runApp(MyApp());
  });
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
  final _sizeTextBlack = const TextStyle(fontSize: 20.0, color: Colors.black);
  final pinFormKey = new GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: MyApp.navKey,
        theme: ThemeData(
          primaryColor: Color(0xFF808285), //серый
          accentColor: Color(0xFFEE1C28), //красный
          canvasColor: Color(0xFFd1d2d4),
          backgroundColor: Color(0xFFd1d2d4), //светло-серый
          focusColor: Color(0xFF808285),
          cursorColor: Color(0xFF808285),
          textTheme: TextTheme(bodyText2: TextStyle(color: Colors.black)),
        ),
        navigatorObservers: [routeObserver],
        home: RouteAwareWidget('/home', child: HomeScreen()),
        routes: <String, WidgetBuilder>{
          '/login': (context) => RouteAwareWidget('/login', child: LoginPage()),
          '/home': (context) => RouteAwareWidget('/home', child: HomeScreen()),
          '/planCbt': (context) =>
              RouteAwareWidget('planCbt', child: PlanCbtScreen()),
          '/planCbtEdit': (context) =>
              RouteAwareWidget('planCbtEdit', child: PlanCbtEditScreen()),
        });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("APP_STATE: $state");

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
        Duration seconds =
            new Duration(seconds: (sessionExpire != null ? sessionExpire : 10*60));
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
        });
        //loadData
        Navigator.pop(context, true);
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
        builder: (_) {
          return AlertDialog(
            title: Text("Введите ПИН-код"),
            content: new Form(
                key: pinFormKey,
                child: new Container(
                    height: 100,
                    child: new Column(children: <Widget>[
                      new Container(
                        height: 60,
                        color: Colors.white,
                        child: new TextFormField(
                            // inputFormatters: [widget._amountValidator],
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ], // Only numbers can be entered
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            maxLines: 1,
                            maxLength: 5,
                            cursorColor: Theme.of(context).cursorColor,
                            style: _sizeTextBlack,
                            onSaved: (val) => _pin = val,
                            onTap: () => setState(() {
                                  _showErrorPin = false;
                                }),
                            validator: (val) => val.length < 5
                                ? "ПИН-код должен состоять из 5 цифр"
                                : null),
                      ),
                      new Expanded(
                          child: new Container(
                              padding: new EdgeInsets.all(10.0),
                              child: new Text(
                                _showErrorPin ? "Неверный ПИН-код" : '',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 17),
                                textAlign: TextAlign.left,
                              ))),
                    ]))),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    pinConfirm();
                  },
                  child: Text("OK"))
            ],
          );
        });
  }
}

class RouteAwareWidget extends StatefulWidget {
  final String name;
  final Widget child;

  RouteAwareWidget(this.name, {@required this.child});
  @override
  State<RouteAwareWidget> createState() => _RouteAwareWidget();
}

class _RouteAwareWidget extends State<RouteAwareWidget> with RouteAware {
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
    _lastScreen = widget.name;
  }

  @override
  build(BuildContext context) => widget.child;
}
