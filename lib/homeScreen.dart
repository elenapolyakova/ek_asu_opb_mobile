import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/src/exchangeData.dart' as exchange;
import 'package:ek_asu_opb_mobile/src/db.dart';
import 'utils/network.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  UserInfo _userInfo;
  String _supportPhoneNumber = "123456";
  List<dynamic> logRows = []; // = ['test', 'test2'];

  @override
  void initState() {
    super.initState();
    loadLog();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        setState(() {
          auth.getUserInfo().then((userInfo) => {_userInfo = userInfo});
        });
        checkConnection().then((isConnect) {
          if (isConnect) {
            auth.checkSession(context).then((isSessionExist) {
              if (isSessionExist) {
                DBProvider.db.selectAll('railway').then((rows) {
                  DBProvider.db.insert('log', {
                    'date': '@@@@@@@ ',
                    'message': 'railway count ${rows.length}'
                  });
                  DBProvider.db.selectAll('department').then((rows) {
                    DBProvider.db.insert('log', {
                      'date': '@@@@@@@ ',
                      'message': 'department count ${rows.length}'
                    });
                    DBProvider.db.selectAll('user').then((rows) {
                      DBProvider.db.insert('log', {
                        'date': '@@@@@@@ ',
                        'message': 'user count ${rows.length}'
                      });
                      exchange.getDictionaries(all: true).then((result) {
                        loadLog();
                      }); //getDictionary
                    });
                  });
                });
              } //isSessionExist = true
            }); //checkSession
          } //isConnect == true
        }); //checkConnection
      } //isLogin == true
    }); //checkLoginStatus
  }

  void LogOut() {
    auth.LogOut(context);
  }

  void loadLog() {
    logRows.clear();
    DBProvider.db.selectAll("log").then((data) {
      data.forEach((logItem) {
        logRows.add("${logItem['date']}: ${logItem['message']}");
      }); //forEach
      setState(() => {});
    }); //getLog
  }

  void clearLog() {
    DBProvider.db.deleteAll('log');
    setState(() {
      logRows.clear();
    });
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
            title: new Text('${_userInfo!=null ? _userInfo.display_name : ""}',
                style:
                    new TextStyle(color: Theme.of(context).primaryColorLight)),
            leading: null,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).primaryColorDark,
            actions: <Widget>[
              new IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Рабочая документация',
                  color: Theme.of(context).buttonColor,
                  onPressed: () => {}),
              new IconButton(
                  icon: const Icon(Icons.logout),
                  color: Theme.of(context).buttonColor,
                  tooltip: 'Выход',
                  onPressed: LogOut),
            ]),
        /*floatingActionButton: FloatingActionButton.extended(
          onPressed: () => UrlLauncher.launch("tel://$_supportPhoneNumber"),
          label: Text('Служба поддержки'),
          icon: Icon(Icons.phone),
          backgroundColor: Colors.green,
        ),*/
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => {clearLog()},
          label: Text('Очистить лог'),
          icon: Icon(Icons.delete_outline),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Container(
          padding: EdgeInsets.all(10),
          child:
        ListView(
            children: List<Widget>.generate(
                logRows.length,
                (index) => Container(
                    color: index%2 == 0 ? Colors.white: Theme.of(context).shadowColor,
                    child: Text(logRows[index]
                        .toString())))) /* new Padding(
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
            ))
            */
        ));
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
