import 'package:flutter/material.dart';

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
        onTap: widget.onTap,
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: 13),
            child: Row(children: <Widget>[
              IconButton(
                  padding: EdgeInsets.all(0),
                  icon: Icon(widget.icon), //Icons.logout),
                  color: widget.color,
                  onPressed: () => widget.onTap),
              new Text(
                widget.text,
                style: TextStyle(
                  color: widget.color,
                ),
              )
            ])));
  }
}

showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Color(0x88E6E6E6),
    builder: (BuildContext context) {
      return AlertDialog(
           shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
        backgroundColor: Theme.of(context).primaryColor,
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColorDark),
            ),
            Container(
                margin: EdgeInsets.all(5),
                child: Text("Подождите, идёт загрузка...."))
          ],
        ),
      );
    },
  );
}

hideDialog(BuildContext context) {
  Navigator.pop(context);
}

class EditTextField extends StatefulWidget {
  String text;
  dynamic value;
  Function onTap;
  Function(dynamic) onSaved;
  BuildContext context;
  Color color;

  EditTextField(
      {this.text = "",
      this.value = "",
      this.onTap,
      this.onSaved,
      this.context,
      this.color});
  @override
  State<EditTextField> createState() => _EditTextField();
}

class _EditTextField extends State<EditTextField> {
  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(widget.context).primaryColorDark;
    final textStyle = TextStyle(fontSize: 16.0, color: color);
    return GestureDetector(
        onTap: widget.onTap,
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            child: Column(children: <Widget>[
              Container(
                  alignment: Alignment.bottomLeft,
                  padding: EdgeInsets.only(bottom: 5.0),
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: widget.color,
                    ),
                  )),
              Container(
                height: 35.0,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1.5),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.white,
                ),
                child: TextFormField(
                  decoration: new InputDecoration(
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.all(5.0)),
                  initialValue:
                      widget.value != null ? widget.value.toString() : '',
                  cursorColor: widget.color,
                  style: textStyle,
                  onSaved: widget.onSaved,
                  minLines: 1,
                  maxLines: 5,
                  // maxLength: 256,
                ),
              )
            ])));
  }
}

SnackBar successSnackBar = SnackBar(
  backgroundColor: Color(0xAAADB439),
  padding: EdgeInsets.all(5.0),
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.0), topRight: Radius.circular(12.0))),
  content: Text('Данные сохранены успешно!',
      style: TextStyle(color: Color(0xFF252A0E))),
);

SnackBar errorSnackBar = SnackBar(
  backgroundColor: Color(0xAAE57373),
  padding: EdgeInsets.all(5.0),
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.0), topRight: Radius.circular(12.0))),
  content: Text('Ошибка при сохранении данных!',
      style: TextStyle(color: Color(0xFF252A0E))),
);

class CustomPopMenu extends PopupMenuEntry<Map<String, dynamic>> {
  BuildContext context;
  List<Map<String, dynamic>> choices;
  CustomPopMenu({this.context, this.choices});

  @override
  double height = 1; //100;

  @override
  bool represents(Map<String, dynamic> n) => false;

  @override
  State<CustomPopMenu> createState() => _CustomPopMenu();
}

class _CustomPopMenu extends State<CustomPopMenu> {
  void selectMenu(Map<String, dynamic> choices) {
    Navigator.pop<Map<String, dynamic>>(context, choices);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Theme.of(widget.context).primaryColor,
            borderRadius: BorderRadius.all(Radius.circular(12.0))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(widget.choices.length, (index) {
            return TextIcon(
                text: widget.choices[index]['title'],
                onTap: () => selectMenu(widget.choices[index]),
                icon: widget.choices[index]['icon'],
                color: Theme.of(widget.context).primaryColorDark);
          }),
        ));
  }
}

class MyButton extends StatelessWidget {
  String text;
  BuildContext parentContext;
  Function onPress;
  double width;
  double height;
  final _sizeTextWhite = const TextStyle(fontSize: 20.0, color: Colors.white);

  MyButton(
      {this.text, this.parentContext, this.onPress, this.width, this.height});
  @override
  Widget build(BuildContext) {
    return Container(
        height: height ?? 40.0,
        width: width ?? 150.0,
        alignment: Alignment.center,
        padding: new EdgeInsets.all(5.0),
        margin: new EdgeInsets.all(5.0),
        decoration: new BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Theme.of(parentContext).buttonColor,
        ),
        child: new MaterialButton(
          onPressed: onPress,
          child: new Text(
            text,
            style: _sizeTextWhite,
          ),
        ));
  }
}

Future<bool> showConfirmDialog(String text, BuildContext parentContext) {
  return showDialog<bool>(
      context: parentContext,
      barrierDismissible: true,
      barrierColor: Color(0x88E6E6E6),
      builder: (context) {
        return AlertDialog(
             shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0))),
            backgroundColor: Theme.of(context).primaryColor,
            content: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 100, maxWidth: 500),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(text),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MyButton(
                              text: 'принять',
                              parentContext: parentContext,
                              onPress: () {
                                Navigator.pop<bool>(context, true);
                              }),
                              MyButton(
                              text: 'отменить',
                              parentContext: parentContext,
                              onPress: () {
                                Navigator.pop<bool>(context, false);
                              })
                        ],
                      )
                    ])
                //Navigator.pop<bool>(context, result);
                ));
      });
}
