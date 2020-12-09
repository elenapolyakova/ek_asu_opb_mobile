import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';

class FaultFixScreen extends StatefulWidget {
  int faultId;
  int faultFixId;
  Function(Map<String, String>, dynamic arg) push;
  Map<String, String> Function() pop;
  GlobalKey key;

  @override
  FaultFixScreen(
      this.faultFixId, this.faultId, this.push, this.pop, this.key);

  @override
  State<FaultFixScreen> createState() => _FaultFixScreen();
}

class _FaultFixScreen extends State<FaultFixScreen> {
  UserInfo _userInfo;
  bool showLoading = true;

 

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;

          loadData();
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData() async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});


    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
   return showLoading
        ? Text("")
        : Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 40),
            child: Column(children: [
              Expanded(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Expanded(
                       
                        child: SingleChildScrollView(
                            child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [Text('Описание')]))))
                  ]))
            ]));
  }
}
