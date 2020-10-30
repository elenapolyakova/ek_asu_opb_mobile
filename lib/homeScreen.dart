import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/src/exchangeData.dart' as exchange;
//import 'package:ek_asu_opb_mobile/src/db.dart';
import 'utils/network.dart';
import "package:ek_asu_opb_mobile/controllers/controllers.dart" as controllers;

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
    // loadLog();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        setState(() {});
        checkConnection().then((isConnect) {
          if (isConnect) {
            auth.getUserInfo().then((userInfo) {
              _userInfo = userInfo;
              setState(() {});
              auth.checkSession(context).then((isSessionExist) {
                if (isSessionExist) {
                  exchange.getDictionaries(all: true).then((result) {
                    // loadLog();
                  }); //getDictionary

                } //isSessionExist = true
              }); //checkSession
            });
          } //isConnect == true
        }); //checkConnection
      } //isLogin == true
    }); //checkLoginStatus
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
          leading: null,
          title: TextIcon(
              icon: Icons.account_circle_rounded,
              text: '${_userInfo != null ? _userInfo.display_name : ""}',
              onTap: null,
              color: Theme.of(context).primaryColorLight),
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).primaryColorDark,
          actions: <Widget>[
            Padding(
                padding: EdgeInsets.only(right: 10),
                child: TextIcon(
                    icon: Icons.logout,
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

      body: Container(
          padding: EdgeInsets.all(10),
          child: ListView(
              children: List<Widget>.generate(
                  logRows.length,
                  (index) => Container(
                      color: index % 2 == 0
                          ? Colors.white
                          : Theme.of(context).shadowColor,
                      child: Text(logRows[index].toString()))))),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).bottomAppBarColor,
        selectedItemColor: Theme.of(context).primaryColorDark ,
        unselectedItemColor: Theme.of(context).primaryColor ,
        selectedFontSize: 14,
        unselectedFontSize: 14,
        onTap: (value) {
          // Respond to item press.
        },
        items: [
          BottomNavigationBarItem(
            label: 'Favorites',
            icon: Icon(Icons.favorite),
          ),
          BottomNavigationBarItem(
            label: 'Music',
            icon: Icon(Icons.music_note),
          ),
          BottomNavigationBarItem(
            label: 'Places',
            icon: Icon(Icons.location_on),
          ),
          BottomNavigationBarItem(
            label: 'News',
            icon: Icon(Icons.library_books),
          ),
        ],
      ),
    );
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

class TextIcon extends StatefulWidget {
  IconData icon;
  String text;
  Function onTap;
  Color color;

  TextIcon({this.icon, this.text = "", this.onTap, this.color});
  @override
  State<TextIcon> createState() => _TextIcon();
}

class _TextIcon extends State<TextIcon> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: widget.onTap, // LogOut,
        child: Row(children: <Widget>[
          IconButton(
              icon: Icon(widget.icon), //Icons.logout),
              color: widget.color,
              onPressed: () => widget.onTap),
          new Text(
            widget.text,
            style: TextStyle(
              color: widget.color,
            ),
          )
        ]));
  }
}
