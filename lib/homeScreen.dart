import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  var _userInfo;
  var _predId;
  String _supportPhoneNumber = "123456";

  @override
  void initState() {
    super.initState();
    auth.checkLoginStatus(context).then((isLogin) => {
          if (isLogin)
            {
              auth.getUserInfo().then((userInfo) => setState(() {
                    _userInfo = userInfo;
                  }))
            }
        });
  }

  void LogOut() {
    auth.LogOut(context);
  }


  void planScreen() {
    Navigator.pushNamed(
      context,
      '/planCbt',
    );
  }

  void emptyRoute() {}

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
            title: new Text("ЕК АСУ ОПБ"),
            leading: null,
            automaticallyImplyLeading: false,
            actions: <Widget>[
              new IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Рабочая документация',
                  onPressed: () => {}),
              new IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Выход',
                  onPressed: LogOut),
            ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => UrlLauncher.launch("tel://$_supportPhoneNumber"),
          label: Text('Служба поддержки'),
          icon: Icon(Icons.phone),
          backgroundColor: Colors.green,
        ),
        body: new Padding(
            padding: new EdgeInsets.only(bottom: 50.0),
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Expanded(
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new TileButton("Планирование", planScreen),
                      new TileButton("Учёт первичных сведений", emptyRoute),
                    ],
                  ),
                ),
                new Expanded(
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new TileButton("Формирование отчетности", emptyRoute),
                      new TileButton("Просмотр карты", emptyRoute),
                    ],
                  ),
                ),
              ],
            )));
  }
}

class TileButton extends StatefulWidget {
  String _buttonText;
  Function _onPressed;
  TileButton(String buttonText, Function onPressed) {
    _buttonText = buttonText;
    _onPressed = onPressed;
  }
  @override
  State<TileButton> createState() => _TileButton();
}

class _TileButton extends State<TileButton> {
  final _sizeTextBlack = const TextStyle(fontSize: 20.0, color: Colors.black);
  final _sizeTextWhite = const TextStyle(fontSize: 20.0, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return new Expanded(
        child: new Padding(
      padding: new EdgeInsets.all(50.0),
      child: new MaterialButton(
        onPressed: widget._onPressed,
        color: Theme.of(context).accentColor,
        height: double.infinity,
        minWidth: 150.0,
        child: new Text(
          widget._buttonText,
          style: _sizeTextWhite,
        ),
      ),
    ));
  }
}
