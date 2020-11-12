import 'dart:ui';
import 'package:ek_asu_opb_mobile/controllers/controllers.dart' as controllers;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/components/flutter_rounded_date_picker/rounded_picker.dart';
import 'package:ek_asu_opb_mobile/components/time_picker_spinner.dart';
import 'package:intl/intl.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import 'package:ek_asu_opb_mobile/utils/dictionary.dart';
import 'package:ek_asu_opb_mobile/models/department.dart' as dep;
export 'search/search.dart';

class TextIcon extends StatefulWidget {
  IconData icon;
  String text;
  Function onTap;
  Color color;
  double margin;

  TextIcon(
      {this.icon, this.text = "", this.onTap, this.color, this.margin = 13.0});
  @override
  State<TextIcon> createState() => _TextIcon();
}

class _TextIcon extends State<TextIcon> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: widget.onTap,
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: widget.margin),
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
  //AnimationController(vsync: this);
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
  Function(String) onSaved;
  BuildContext context;
  Color color;
  bool showEditDialog;
  double height;
  int maxLines;

  EditTextField(
      {this.text = "",
      this.value = "",
      this.context,
      this.color,
      this.onSaved,
      this.showEditDialog = true,
      this.height = 35.0,
      this.maxLines = 1});
  @override
  State<EditTextField> createState() => _EditTextField(value);
}

class _EditTextField extends State<EditTextField> {
  String _value;
  _EditTextField(value) {
    _value = value != null ? value.toString() : "";
  }

  @override
  Widget build(BuildContext context) {
    // String _value = widget.value.toString();
    final color = widget.color ?? Theme.of(widget.context).buttonColor;
    final textStyle = TextStyle(fontSize: 16.0, color: color);
    return Container(
        margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        child: Column(children: <Widget>[
          Container(
              alignment: Alignment.bottomLeft,
              padding: EdgeInsets.only(bottom: 5.0),
              child: Text(widget.text,
                  textAlign: TextAlign.left, style: textStyle)),
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1.5),
              borderRadius: BorderRadius.all(Radius.circular(12)),
              color: Colors.white,
            ),
            child: TextFormField(
              readOnly: widget.showEditDialog,
              controller: TextEditingController.fromValue(TextEditingValue(
                  text: widget.value != null ? widget.value.toString() : "")),
              decoration: new InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.all(5.0)),
              // initialValue:
              //     _value, //widget.value != null ? widget.value.toString() : '',
              onTap: () {
                if (!widget.showEditDialog) return;
                showEdit(widget.value, widget.text, widget.context)
                    .then((newValue) => setState(() {
                          widget.value = newValue ?? "";
                        }));
              },
              cursorColor: widget.color,
              style: textStyle,
              onSaved: widget.onSaved,
              maxLines: widget.maxLines,
              // maxLength: 256,
            ),
          )
        ]));
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

SnackBar errorSnackBar({String text}) => SnackBar(
      elevation: 100,
      backgroundColor: Color(0xAAE57373),
      padding: EdgeInsets.all(5.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.0), topRight: Radius.circular(12.0))),
      content: Text(text ?? 'Ошибка при сохранении данных!',
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

class EditPopUp extends StatefulWidget {
  String sourceValue;
  String text;
  BuildContext parentContext;

  EditPopUp({this.parentContext, this.text, this.sourceValue});

  @override
  State<EditPopUp> createState() => _EditPopUp();
}

class _EditPopUp extends State<EditPopUp> {
  final formKey = new GlobalKey<FormState>();
  String newValue;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(widget.parentContext).buttonColor;
    final textStyle = TextStyle(fontSize: 16.0, color: color);

    return AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0))),
        backgroundColor: Theme.of(context).primaryColor,
        content: ConstrainedBox(
            constraints: BoxConstraints.tight(new Size(700, 200)),
            child: Form(
                key: formKey,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                          alignment: Alignment.bottomLeft,
                          padding: EdgeInsets.only(bottom: 5.0),
                          child: Text(
                            widget.text ?? '',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: color,
                            ),
                          )),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Colors.white,
                        ),
                        child: TextFormField(
                          decoration: new InputDecoration(
                              border: OutlineInputBorder(
                                  borderSide: BorderSide.none),
                              contentPadding: EdgeInsets.all(5.0)),
                          initialValue: widget.sourceValue ?? '',
                          cursorColor: color,
                          style: textStyle,
                          onSaved: (value) => newValue = value,
                          maxLines: 5,
                          // maxLength: 256,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MyButton(
                              text: 'принять',
                              parentContext: widget.parentContext,
                              onPress: () {
                                submitEditPopUp();
                                // Navigator.pop<String>(context, true);
                              }),
                          MyButton(
                              text: 'отменить',
                              parentContext: widget.parentContext,
                              onPress: () {
                                Navigator.pop<String>(
                                    context, widget.sourceValue);
                              })
                        ],
                      )
                    ]))
            //Navigator.pop<bool>(context, result);
            ));
  }

  void submitEditPopUp() {
    final form = formKey.currentState;
    hideKeyboard();
    form.save();
    Navigator.pop<String>(context, newValue);
  }
}

void hideKeyboard() {
  SystemChannels.textInput.invokeMethod('TextInput.hide');
}

Future<String> showEdit(
    String sourceValue, String text, BuildContext parentContext) {
  return showDialog<String>(
      context: parentContext,
      barrierDismissible: false,
      barrierColor: Color(0x88E6E6E6),
      builder: (context) {
        return EditPopUp(
          sourceValue: sourceValue,
          text: text,
          parentContext: parentContext,
        );
      });
}

class MyDropdown extends StatefulWidget {
  String text;
  String dropdownValue;
  double width;
  double height;
  BuildContext parentContext;
  Function(String) onChange;
  List<Map<String, dynamic>> items;

  MyDropdown(
      {this.dropdownValue,
      this.items,
      this.text,
      this.onChange,
      this.parentContext,
      this.width = double.infinity,
      this.height});
  @override
  State<MyDropdown> createState() => _MyDropdown();
}

class _MyDropdown extends State<MyDropdown> {
  @override
  Widget build(BuildContext) {
    final color = Theme.of(widget.parentContext).buttonColor;
    final textStyle = TextStyle(fontSize: 16.0, color: color);
    final text = widget.text ?? "";
    return Container(
        width: widget.width,
        child: Column(children: <Widget>[
          Container(
              alignment: Alignment.bottomLeft,
              height: text == "" ? 0 : 35.0,
              padding: EdgeInsets.only(bottom: text == "" ? 0 : 5.0),
              child: Text(text, textAlign: TextAlign.left, style: textStyle)),
          Container(
              height: 35.0,
              width: widget.width,
              padding: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Theme.of(widget.parentContext).primaryColorLight,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: false,
                  itemHeight: 200, // widget.height ?? kMinInteractiveDimension,
                  value: widget.dropdownValue,
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                  elevation: 16,
                  style: textStyle,
                  underline: Container(
                    height: 0,
                  ),
                  onChanged: (value) {
                    widget.dropdownValue = value;
                    setState(() {});
                    widget.onChange(value);
                  },
                  items: widget.items.map<DropdownMenuItem<String>>(
                      (Map<String, dynamic> value) {
                    return DropdownMenuItem<String>(
                      value: value["id"].toString(),
                      child: Text(value["value"] != null
                          ? value["value"].toString()
                          : ""),
                    );
                  }).toList()))
        ]));
  }
}

class DatePicker extends StatefulWidget {
  final ValueChanged<DateTime> onChanged;
  final DateTime selectedDate;
  final text;
  bool enable;
  double width;

  final BuildContext parentContext;
  DatePicker(
      {Key key,
      this.selectedDate,
      this.onChanged,
      this.text,
      this.parentContext,
      this.width = 200,
      this.enable = true})
      : super(key: key);

  @override
  State<DatePicker> createState() => _DatePicker(selectedDate);
}

class _DatePicker extends State<DatePicker> {
  static const _YEAR = 365;
  DateTime _selectedDate;

  _DatePicker(selectedDate) {
    _selectedDate = selectedDate;
  }
  Future<Null> _selectDate(BuildContext context) async {
    FocusScope.of(context).requestFocus(FocusNode());
    await Future.delayed(Duration(milliseconds: 100));

    DateTime picked = await showRoundedDatePicker(
        //await showDatePicker(
        context: widget.parentContext,
        theme: ThemeData(
            primaryColor:
                Theme.of(widget.parentContext).primaryColor, //фон слева
            accentColor:
                Theme.of(widget.parentContext).buttonColor, //выбранный день
            textTheme: TextTheme(
                caption: TextStyle(
                    color: Theme.of(widget.parentContext).primaryColorDark,
                    fontSize: 25))), // purple,),
        //  imageHeader: AssetImage("assets/images/background.jpg"),
        initialDate: widget.selectedDate,
        firstDate: DateTime.now().subtract(Duration(days: _YEAR * 10)),
        lastDate: DateTime.now().add(Duration(days: _YEAR * 10)),
        styleDatePicker: MaterialRoundedDatePickerStyle(
            backgroundPicker: Theme.of(widget.parentContext).primaryColorLight,
            backgroundHeaderMonth:
                Theme.of(widget.parentContext).primaryColorDark,
            paddingMonthHeader: EdgeInsets.all(30),
            //  paddingDateYearHeader: EdgeInsets.all(0),
            paddingDatePicker: EdgeInsets.all(0),
            sizeArrow: 50,
            colorArrowNext: Theme.of(widget.parentContext).primaryColorLight,
            colorArrowPrevious:
                Theme.of(widget.parentContext).primaryColorLight,
            marginRightArrowNext: 20,
            marginTopArrowNext: 20,
            marginLeftArrowPrevious: 20,
            marginTopArrowPrevious: 20,
            textStyleMonthYearHeader: TextStyle(
                color: Theme.of(widget.parentContext).primaryColorLight,
                fontSize: 25), //месяц и год в шапке

            textStyleDayHeader: TextStyle(
                color: Theme.of(widget.parentContext).primaryColor,
                fontSize: 20), //дни недели
            textStyleDayOnCalendar: TextStyle(
                color: Theme.of(widget.parentContext).primaryColorDark,
                fontSize: 20), //дни месяца
            textStyleYearButton: TextStyle(
                color: Theme.of(widget.parentContext).buttonColor,
                fontSize: 30), //год слева
            textStyleDayButton: TextStyle(
                color: Theme.of(widget.parentContext).buttonColor,
                fontSize: 30), //день и месяц слева
            textStyleButtonPositive: TextStyle(
                color: Theme.of(widget.parentContext).primaryColor,
                fontSize: 20), //кнопка ок
            textStyleButtonNegative: TextStyle(
                color: Theme.of(widget.parentContext).primaryColor,
                fontSize: 20) //кнопка отмены
            ),
        styleYearPicker: MaterialRoundedYearPickerStyle(
            textStyleYear: TextStyle(
                fontSize: 15,
                color: Theme.of(widget.parentContext).primaryColorDark),
            textStyleYearSelected: TextStyle(
                fontSize: 25,
                color: Theme.of(widget.parentContext).primaryColor)));
    if (picked != null && picked != widget.selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).buttonColor;
    final textStyle = TextStyle(fontSize: 16.0, color: color);
    final disabledColor = Color(0xAA6E6E6E);
    String _text = widget.text ?? "";
    return
        /*Row(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
      Expanded(
          child:*/
        InkWell(
            onTap: () => _selectDate(context),
            child: Container(
                width: widget.width,
                child: Column(children: [
                  Container(
                      width: double.infinity,
                      height: _text == "" ? 0 : 35.0,
                      alignment: Alignment.bottomLeft,
                      padding: EdgeInsets.only(bottom: 5.0),
                      child: Text(_text,
                          textAlign: TextAlign.left, style: textStyle)),
                  Container(
                      height: 35,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: widget.enable
                                  ? Theme.of(context).primaryColorLight
                                  : disabledColor,
                              width: 1.5),
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          color: widget.enable
                              ? Theme.of(context).primaryColorLight
                              : disabledColor),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text(
                                  DateFormat('dd.MM.yyyy')
                                      .format(_selectedDate),
                                  style: textStyle,
                                )),
                            Container(
                              padding: const EdgeInsets.only(
                                  left: 12.0, right: 12.0),
                              child: Icon(
                                Icons.today,
                                color: Theme.of(widget.parentContext)
                                    .primaryColorDark,
                              ),
                            )
                          ]))
                ])));
  }
}

class TimePicker extends StatefulWidget {
  DateTime time;
  int minutesInterval;
  bool enable;
  double spacing;
  double itemHeight;
  double width;
  BuildContext context;
  Function(DateTime) onTimeChange;

  TimePicker({
    this.time,
    this.minutesInterval = 1,
    this.spacing = 50,
    this.itemHeight = 80,
    this.context,
    this.width = 200,
    this.onTimeChange,
    this.enable = true,
  });
  @override
  State<TimePicker> createState() => _TimePicker(time);
}

class _TimePicker extends State<TimePicker> {
  DateTime _time;
  @override
  _TimePicker(time) {
    _time = time;
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    _time = _time ?? now; //DateTime(now.year, now.month, now.day, 8, 0, 0);

    String _value = '${addZero(_time.hour)}:${addZero(_time.minute)}';

    final color = Theme.of(widget.context).primaryColorDark;
    final textStyle = TextStyle(fontSize: 16.0, color: color);
    final TextStyle disableText =
        TextStyle(fontSize: 16.0, color: Color(0xAA6E6E6E));
    return Container(
        child: Column(children: <Widget>[
      Container(
        height: 35,
        width: widget.width,
        padding: EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
            border: Border.all(
                color: widget.enable
                    ? Theme.of(widget.context).primaryColorLight
                    : Color(0xAA6E6E6E),
                width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(12)),
            color: widget.enable
                ? Theme.of(widget.context).primaryColorLight
                : Color(0xAA6E6E6E)),
        child: TextFormField(
          readOnly: true,
          style: TextStyle(color: Theme.of(widget.context).buttonColor),
          controller:
              TextEditingController.fromValue(TextEditingValue(text: _value)),
          decoration: new InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding: EdgeInsets.all(5.0)),
          // initialValue:
          //     _value, //widget.value != null ? widget.value.toString() : '',
          onTap: () {
            if (!widget.enable) return;

            showTimePicker(_time, widget.context, widget.minutesInterval,
                    widget.spacing, widget.itemHeight)
                .then((time) {
              if (time == null) return;
              setState(() {
                _time = time;
                widget.onTimeChange(time);
                _value = '${addZero(_time.hour)}:${addZero(_time.minute)}';
              });
            });
          },

          // maxLength: 256,
        ),
      )
    ]));
  }
}

Future<DateTime> showTimePicker(DateTime time, BuildContext parentContext,
    int minutesInterval, double spacing, double itemHeight) {
  DateTime sourceTime = time;
  return showDialog<DateTime>(
      context: parentContext,
      barrierDismissible: true,
      barrierColor: Color(0x88E6E6E6),
      builder: (context) {
        return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0))),
            backgroundColor: Theme.of(context).primaryColor,
            content: ConstrainedBox(
                constraints: BoxConstraints.tight(new Size(300, 300)),
                child: Column(children: [
                  TimePickerSpinner(
                    time: time,
                    is24HourMode: true,
                    minutesInterval: minutesInterval,
                    normalTextStyle: TextStyle(
                        fontSize: 20,
                        color: Theme.of(parentContext).primaryColorDark),
                    highlightedTextStyle: TextStyle(
                        fontSize: 24,
                        color: Theme.of(parentContext).primaryColorLight),
                    spacing: spacing,
                    itemHeight: itemHeight,
                    isForce2Digits: true,
                    onTimeChange: (newTime) {
                      time = newTime;
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyButton(
                          text: 'принять',
                          parentContext: parentContext,
                          onPress: () {
                            Navigator.pop<DateTime>(context, time);
                          }),
                      /* MyButton(
                  text: 'отменить',
                  parentContext: parentContext,
                  onPress: () {
                    Navigator.pop<DateTime>(context, sourceTime);
                  })*/
                    ],
                  )
                ])));
      });
}

class DepartmentSelect extends StatefulWidget {
  String text;
  dep.Department department;
  int railwayId;
  Function(dep.Department) onSaved;
  BuildContext context;
  double width;
  double height;
  int maxLine;

  DepartmentSelect(
      {this.text = "",
      this.department,
      this.railwayId = null,
      this.context,
      this.onSaved,
      this.width = 300,
      this.height = 60,
      this.maxLine = 2});
  @override
  State<DepartmentSelect> createState() =>
      _DepartmentSelect(department, railwayId);
}

class _DepartmentSelect extends State<DepartmentSelect> {
  dep.Department _department;
  int _railwayId;
  dep.Department selecteDepartment;
  int selectedRailwayId;
  int selectedId;

  String _value;
  _DepartmentSelect(dep.Department department, int railway_id) {
    _department = department;
    _railwayId = railway_id;
    selectedRailwayId =
        _railwayId ?? (_department != null ? _department.railway_id : null);
  }

  void onRailwaySelected(railwayId) {
    setState(() {
      selectedRailwayId = railwayId;
    });
  }

  @override
  Widget build(BuildContext context) {
    // String _value = widget.value.toString();
    final color = Theme.of(widget.context).buttonColor;
    final textStyle = TextStyle(fontSize: 16.0, color: color);

    return Container(
        margin: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        child: Column(children: <Widget>[
          Container(
              alignment: Alignment.bottomLeft,
              padding: EdgeInsets.only(bottom: 5.0),
              child: Text(widget.text,
                  textAlign: TextAlign.left, style: textStyle)),
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1.5),
              borderRadius: BorderRadius.all(Radius.circular(12)),
              color: Colors.white,
            ),
            child: TextFormField(
                readOnly: true,
                maxLines: widget.maxLine,
                controller: TextEditingController.fromValue(TextEditingValue(
                    text: _department != null ? _department.name : '')),
                decoration: new InputDecoration(
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.all(5.0)),
                // initialValue:
                //     _value, //widget.value != null ? widget.value.toString() : '',
                onTap: () {
                  showDepartmentSelect(_department, _railwayId, widget.text,
                          widget.context, setState,
                          onRailwaySelected: onRailwaySelected)
                      .then((department) {
                    if (department == null) return;
                    setState(() {
                      _department = department ?? null;
                      return widget.onSaved(_department);
                    });
                  });
                },
                cursorColor: Theme.of(widget.context).primaryColorDark,
                style: textStyle
                // maxLength: 256,
                ),
          )
        ]));
  }

  Future<List<dynamic>> onSearch(String template, int railwayId) async {
    List<dep.Department> list =
        await controllers.Department.select(template, railwayId);
    if (list == null) return null;
    List<dynamic> result = List.generate(list.length, (index) {
      return {
        'id': list[index].id,
        'value': '${list[index].name}(${list[index].short_name})'
      };
    });
    return result;
  }

  Future<dep.Department> showDepartmentSelect(dep.Department sourceDepartment,
      int sourceRailwayId, String text, BuildContext parentContext, setState,
      {Function(int) onRailwaySelected}) async {
    List<Map<String, dynamic>> railwayList = await getRailwayList();
    railwayList.insert(0, ({"id": 0, "value": "Центральный аппарат"}));

    setState(() {
      if (sourceRailwayId != null) selectedRailwayId = sourceRailwayId;
    });

    return showDialog<dep.Department>(
        context: parentContext,
        barrierDismissible: true,
        barrierColor: Color(0x88E6E6E6),
        builder: (context) {
          return StatefulBuilder(builder: (context, StateSetter setState) {
            return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0))),
                backgroundColor: Theme.of(context).primaryColor,
                content: SingleChildScrollView(
                    child: ConstrainedBox(
                        constraints:
                            BoxConstraints(maxHeight: 700, minWidth: 700),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_railwayId == null)
                                Container(
                                    width: 500,
                                    child: MyDropdown(
                                      text: 'Дорога',
                                      dropdownValue: selectedRailwayId != null
                                          ? selectedRailwayId.toString()
                                          : null,
                                      items: railwayList,
                                      onChange: (value) {
                                        setState(() {
                                          selectedRailwayId =
                                              int.tryParse(value);
                                        });
                                        return onRailwaySelected(
                                            selectedRailwayId);
                                      },
                                      parentContext: context,
                                    )),
                              if (selectedRailwayId != null)
                                SearchBox(
                                  (newValue) =>
                                      setState(() => selectedId = newValue),
                                  (template) {
                                    return onSearch(
                                        template, selectedRailwayId);
                                  },
                                  context,
                                  text: 'Структурное подразделение',
                                  width: 750,
                                ),
                              if (selectedRailwayId == null)
                                Expanded(
                                    child: Center(
                                        child: Text(
                                            'Для поиска структурных подразделений выберите дорогу'))),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MyButton(
                                      text: 'принять',
                                      parentContext: parentContext,
                                      onPress: () async {
                                        selecteDepartment = await controllers
                                            .Department.selectById(selectedId);
                                        Navigator.pop<dep.Department>(
                                            context, selecteDepartment);
                                      }),
                                  MyButton(
                                      text: 'отменить',
                                      parentContext: parentContext,
                                      onPress: () {
                                        Navigator.pop<dep.Department>(
                                            context, sourceDepartment);
                                      }),
                                ],
                              )
                            ])
                        //Navigator.pop<bool>(context, result);
                        )));
          });
        });
  }
}

class SearchBox extends StatefulWidget {
  IconData icon;
  String text;
  Function(String) onSearch;
  double width;
  double height;
  BuildContext parentContext;
  Function(dynamic) valueChanged;

  SearchBox(
    this.valueChanged,
    this.onSearch,
    this.parentContext, {
    this.icon = Icons.search,
    this.text = "",
    this.width = 600,
    this.height = 400,
  });
  @override
  State<SearchBox> createState() => _SearchBox();
}

class _SearchBox extends State<SearchBox> {
  List<dynamic> result = [];
  String template;
  String emptyText = "";
  int _selectedId;
  final keyDepartmentForm = new GlobalKey<FormState>();

  Future<List<dynamic>> _onSearch() async {
    final form = keyDepartmentForm.currentState;
    form.save();

    List<dynamic> _result = await widget.onSearch(template);
    setState(() {
      emptyText = 'По Вашему запросу ничего не найдено';
      _selectedId = null;
      result = _result;
    });
  }

  void onRowSelected(int index) {
    setState(() {
      _selectedId = result[index]["id"];
    });
    widget.valueChanged(_selectedId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: BoxConstraints.tightForFinite(
          width: widget.width,
          height: widget.height,
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
                child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    child: Form(
                        key: keyDepartmentForm,
                        child: EditTextField(
                            text: widget.text,
                            value: template,
                            showEditDialog: true,
                            context: widget.parentContext,
                            onSaved: (newValue) {
                              setState(() {
                                template = newValue;
                              });
                            }))),
                Container(
                  child: IconButton(
                      padding: EdgeInsets.all(0),
                      icon: Icon(widget.icon),
                      iconSize: 40,
                      color: Theme.of(widget.parentContext).primaryColorDark,
                      onPressed: () => _onSearch()),
                )
              ],
            )),
            Expanded(
                child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1.5),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      color: Theme.of(context).primaryColorLight,
                    ),
                    child: (result != null && result.length > 0)
                        ? ListView(
                            children: List.generate(result.length, (index) {
                            return GestureDetector(
                                onTap: () => onRowSelected(index),
                                child: Row(children: [
                                  Expanded(
                                    child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        color: result[index]["id"] ==
                                                _selectedId
                                            ? Theme.of(context).primaryColorDark
                                            : null,
                                        child: Text(
                                          result[index]["value"] ?? "",
                                          style: TextStyle(
                                              color: result[index]
                                                          ["id"] ==
                                                      _selectedId
                                                  ? Theme.of(context)
                                                      .primaryColorLight
                                                  : Theme.of(context)
                                                      .buttonColor),
                                        )),
                                  )
                                ]));
                          }))
                        : Row(children: [
                            Expanded(
                                child: Text(
                              '$emptyText',
                              textAlign: TextAlign.center,
                            ))
                          ])))
          ],
        ));
  }
}
