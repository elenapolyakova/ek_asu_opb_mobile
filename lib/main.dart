import 'package:flutter/material.dart';
import 'package:ek_asu_opb_mobile/loginPage.dart';
import 'package:ek_asu_opb_mobile/homeScreen.dart';
import 'package:ek_asu_opb_mobile/planCbtScreen.dart';
import 'package:ek_asu_opb_mobile/planCbtEditScreen.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft])
      .then((_) {
    runApp(new MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       theme: ThemeData(
          primaryColor: Color(0xFF808285), //серый
          accentColor: Color(0xFFEE1C28), //красный
          canvasColor: Color(0xFFd1d2d4),
          backgroundColor: Color(0xFFd1d2d4), //светло-серый
          focusColor: Color(0xFF808285),
          cursorColor: Color(0xFF808285),
          textTheme: TextTheme(bodyText2: TextStyle(color: Colors.black)),
        ),
      initialRoute: '/home',
      
       routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => LoginPage(),
        '/home': (BuildContext context) => HomeScreen(),
        '/planCbt': (BuildContext context) => PlanCbtScreen(),
        '/planCbtEdit': (BuildContext context) => PlanCbtEditScreen(),
      });
  }
}
