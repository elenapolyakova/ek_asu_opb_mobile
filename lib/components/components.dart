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
