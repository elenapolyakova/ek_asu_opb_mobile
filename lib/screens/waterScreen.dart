import 'dart:ui';

import 'package:ek_asu_opb_mobile/controllers/fault.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ek_asu_opb_mobile/utils/authenticate.dart' as auth;
import 'package:ek_asu_opb_mobile/models/models.dart';
import 'package:ek_asu_opb_mobile/components/components.dart';

class WaterScreen extends StatefulWidget {
  GlobalKey key;
  int faultId;

  WaterScreen(this.faultId, this.key);

  @override
  State<WaterScreen> createState() => _WaterScreen();
}

class _WaterScreen extends State<WaterScreen> {
  UserInfo _userInfo;
  bool showLoading = true;
  double _harm;
  int _type = 1;
  bool showTypeSelection = false;
  List<Map<String, dynamic>> harmType = [];
  String harmName = "";

  List<List<Map<String, dynamic>>> _rows = [];
  List<List<double>> values = [
    List(6),
    List(6),
    List(5),
    List(7),
    List(5),
    List(7),
    List(5),
    List(5),
    List(4)
  ];

  @override
  void initState() {
    super.initState();

    auth.checkLoginStatus(context).then((isLogin) {
      if (isLogin) {
        auth.getUserInfo().then((userInfo) {
          _userInfo = userInfo;

          loadData(context);
        });
      } //isLogin == true
    }); //checkLoginStatus
  }

  Future<void> loadData(BuildContext context) async {
    try {
      showLoadingDialog(context);
      setState(() => {showLoading = true});

      harmType = [
        {
          "id": 1,
          "name":
              "Вред, причиненный водному объекту сбросом вредных (загрязняющих) веществ в составе сточных вод и (или) дренажных (в том числе шахтных, рудничных) вод",
          "formula": Container(
              width: 210,
              height: 60,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text('У = '),
                UnderlineIndex('К', 'вг'),
                Container(
                    height: 30,
                    child: Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    )),
                UnderlineIndex('К', 'в'),
                Container(
                    height: 30,
                    child: Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    )),
                UnderlineIndex('К', 'ин'),
                Container(
                    height: 30,
                    child: Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    )),
                Formula("sum.png"),
                UnderlineIndex('H', 'i'),
                Container(
                    height: 30,
                    child: Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    )),
                UnderlineIndex('M', 'i'),
                Container(
                    height: 30,
                    child: Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    )),
                UnderlineIndex('К', 'из'),
              ]))
        },
        {
          "id": 2,
          "name":
              "Загрязнение в результате аварий водных объектов органическими и неорганическими веществами, пестицидами и нефтепродуктами, исключая их поступление в составе сточных вод и (или) дренажных (в том числе шахтных, рудничных) вод",
          "formula": Container(
              width: 190,
              height: 60,
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text('У = '),
                UnderlineIndex('К', 'вг'),
                Container(
                    height: 30,
                    child: Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    )),
                UnderlineIndex('К', 'в'),
                Container(
                    height: 30,
                    child: Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    )),
                UnderlineIndex('К', 'ин'),
                Container(
                    height: 30,
                    child: Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    )),
                UnderlineIndex('К', 'дл'),
                Container(
                    height: 30,
                    child: Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    )),
                Formula("sum.png"),
                UnderlineIndex('H', 'i'),
              ]))
        },
        {
          "id": 3,
          "name":
              "Сброс хозяйственно-бытовых сточных вод с судов и иных плавучих объектов и сооружений",
          "formula": Container(
              width: 150,
              height: 30,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    UnderlineIndex('У', 'хв'),
                    Text(' = '),
                    UnderlineIndex('К', 'вг'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'в'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'ин'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('Н', 'хв'),
                  ])),
        },
        {
          "id": 4,
          "name":
              "Загрязнение (засорение) водных объектов мусором, отходами производства и потребления, в том числе с судов и иных плавучих и стационарных объектов и сооружений",
          "formula": Container(
              width: 215,
              height: 30,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    UnderlineIndex('У', 'м'),
                    Text(' = '),
                    UnderlineIndex('К', 'вг'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'в'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'ин'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'загр'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('Н', 'м'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('S', 'м'),
                  ])),
        },
        {
          "id": 5,
          "name":
              "Сброс и захоронение в водных объектах отходов производства и потребления, в том числе выведенных из эксплуатации судов и иных плавучих средств (их частей и механизмов), других крупногабаритных отходов производства и потребления (предметов)",
          "formula": Container(
              width: 125,
              height: 30,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    UnderlineIndex('У', 'с'),
                    Text(' = '),
                    UnderlineIndex('К', 'в'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'ин'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('Н', 'с'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('В', ''),
                  ])),
        },
        {
          "id": 6,
          "name":
              "Осуществление запрещенного молевого сплава древесины и сплава древесины без судовой тяги",
          "formula": Container(
              width: 225,
              height: 30,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    UnderlineIndex('У', 'д'),
                    Text(' = '),
                    UnderlineIndex('К', 'вг'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'в'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'ин'),
                    Text(
                      '·(',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('О', 'д'),
                    Text(
                      ' - ',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('О', 'дф'),
                    Text(
                      ')·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('Н', 'д'),
                  ])),
        },
        {
          "id": 7,
          "name":
              "Загрязнение взвешенными веществами при разведке и добыче полезных ископаемых, проведении дноуглубительных, взрывных, буровых и других работ, связанных с изменением дна и берегов водных объектов, в том числе с нарушением условий водопользования или без наличия документов, на основании которых возникает право пользования водными объектами, а также при разрушение в результате аварий гидротехнических и иных сооружений на водных объектах",
          "formula": Container(
              width: 160,
              height: 30,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    UnderlineIndex('У', 'вв'),
                    Text(' = '),
                    UnderlineIndex('К', 'вг'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'в'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'ин'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('Н', 'взв'),
                  ])),
        },
        {
          "id": 8,
          "name":
              "Частичное или полное истощении водных объектов в результате забора воды с нарушением условий водопользования или без наличия документов, на основании которых возникает право пользования водными объектами",
          "formula": Container(
              width: 135,
              height: 30,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    UnderlineIndex('У', 'и'),
                    Text(' = '),
                    UnderlineIndex('К', 'в'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'ин'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('Н', 'и'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('O', 'в'),
                  ]))
        },
        {
          "id": 9,
          "name":
              "Использование водных объектов для добычи полезных ископаемых (строительных материалов) с нарушением условий водопользования или без наличия документов, на основании которых возникает право пользования водными объектами",
          "formula": Container(
              width: 120,
              height: 30,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    UnderlineIndex('У', 'дс'),
                    Text(' = '),
                    UnderlineIndex('К', 'в'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('К', 'ин'),
                    Text(
                      '·',
                      style: TextStyle(fontSize: 20),
                    ),
                    UnderlineIndex('Н', 'пг'),
                  ]))
        }
      ];
      harmName = harmType[0]["name"];

      _rows = [
        [
          {
            'name':
                'Коэффициент,  учитывающий  природно-климатические  условия  в зависимости  от времени  года',
            'shortName': UnderlineIndex('К', 'вг'),
            'rowIndex': 0
          },
          {
            'name':
                'Коэффициент, учитывающий экологические факторы (состояние водных объектов)',
            'shortName': UnderlineIndex('К', 'в'),
            'rowIndex': 1
          },
          {
            'name':
                'Коэффициент  индексации,  учитывающий инфляционную составляющую экономического  развития',
            'shortName': UnderlineIndex('К', 'ин'),
            'rowIndex': 2
          },
          {
            'name':
                'Суммарное значение такс  для  исчисления  размера  вреда  от  сброса  вредного (загрязняющего)  вещества  в  водные  объекты, умноженных на массу сброшенных загрязняющих веществ',
            'haveSum': true,
            'shortName': Container(
                alignment: Alignment.center,
                child: Row(children: [
                  Formula("sum.png"),
                  UnderlineIndex('H', 'i'),
                  Container(
                      height: 30,
                      child: Text(
                        '·',
                        style: TextStyle(fontSize: 20),
                      )),
                  UnderlineIndex('M', 'i'),
                ])),
            'rowIndex': 3
          },
          {
            'name':
                'Коэффициент,  учитывающий интенсивность негативного воздействия вредных   (загрязняющих)   веществ   на   водный   объект',
            'shortName': UnderlineIndex('К', 'из'),
            'rowIndex': 4
          },
          {
            'name': 'Размер вреда, тыс. руб.',
            'shortName': UnderlineIndex('У', ''),
            'showToolTip': true,
            'readOnly': true,
            'rowIndex': 5,
            'bold': true
          }
        ],
        [
          {
            'name':
                'Коэффициент,  учитывающий  природно-климатические  условия  в зависимости  от времени  года',
            'shortName': UnderlineIndex('К', 'вг'),
            'rowIndex': 0
          },
          {
            'name':
                'Коэффициент, учитывающий экологические факторы (состояние водных объектов)',
            'shortName': UnderlineIndex('К', 'в'),
            'rowIndex': 1
          },
          {
            'name':
                'Коэффициент  индексации,  учитывающий инфляционную составляющую экономического  развития',
            'shortName': UnderlineIndex('К', 'ин'),
            'rowIndex': 2
          },
          {
            'name':
                'Коэффициент,  учитывающий  длительность негативного воздействия вредных  (загрязняющих)  веществ на водный объект при непринятии мер по его ликвидации',
            'shortName': UnderlineIndex('К', 'дл'),
            'rowIndex': 3
          },
          {
            'name':
                'Суммарное значение такс  для  исчисления  размера  вреда  от  сброса вредных (загрязняющих)  веществ  в  водные  объекты',
            'haveSum': true,
            'shortName': Container(
                width: 50,
                alignment: Alignment.center,
                child: Row(children: [
                  Formula("sum.png"),
                  UnderlineIndex('H', 'i'),
                ])),
            'rowIndex': 4
          },
          {
            'name': 'Размер вреда, тыс. руб.',
            'shortName': UnderlineIndex('У', ''),
            'showToolTip': true,
            'readOnly': true,
            'rowIndex': 5,
            'bold': true
          }
        ],
        [
          {
            'name':
                'Коэффициент,  учитывающий  природно-климатические  условия  в зависимости  от времени  года',
            'shortName': UnderlineIndex('К', 'вг'),
            'rowIndex': 0
          },
          {
            'name':
                'Коэффициент, учитывающий экологические факторы (состояние водных объектов)',
            'shortName': UnderlineIndex('К', 'в'),
            'rowIndex': 1
          },
          {
            'name':
                'Коэффициент  индексации,  учитывающий инфляционную составляющую экономического  развития',
            'shortName': UnderlineIndex('К', 'ин'),
            'rowIndex': 2
          },
          {
            'name':
                'Такса для исчисления размера вреда от сброса хозяйственно-бытовых сточных  вод с судов и иных плавучих и стационарных объектов и сооружений в водные  объекты  в  зависимости  от  объема накопительной емкости для сбора хозяйственно-бытовых  сточных  вод',
            'shortName': UnderlineIndex('Н', 'хв'),
            'rowIndex': 3
          },
          {
            'name': 'Размер вреда, тыс. руб.',
            'shortName': UnderlineIndex('У', 'хв'),
            'showToolTip': true,
            'readOnly': true,
            'rowIndex': 4,
            'bold': true
          }
        ],
        [
          {
            'name':
                'Коэффициент,  учитывающий  природно-климатические  условия  в зависимости  от времени  года',
            'shortName': UnderlineIndex('К', 'вг'),
            'rowIndex': 0
          },
          {
            'name':
                'Коэффициент, учитывающий экологические факторы (состояние водных объектов)',
            'shortName': UnderlineIndex('К', 'в'),
            'rowIndex': 1
          },
          {
            'name':
                'Коэффициент  индексации,  учитывающий инфляционную составляющую экономического  развития',
            'shortName': UnderlineIndex('К', 'ин'),
            'rowIndex': 2
          },
          {
            'name':
                'Коэффициент, характеризующий степень загрязненности акватории водного  объекта  мусором,  отходами  производства  и потребления в баллах',
            'shortName': UnderlineIndex('К', 'загр'),
            'rowIndex': 3
          },
          {
            'name':
                'Такса для исчисления размера вреда, причиненного водным объектам загрязнением  (засорением)  мусором,  отходами  производства и потребления, тыс. руб./м²',
            'shortName': UnderlineIndex('Н', 'м'),
            'rowIndex': 4
          },
          {
            'name':
                'Площадь  акватории,  дна  и  береговых  полос  водного  объекта, загрязненная мусором, отходами производства и потребления, определяется на основании инструментальных замеров, в том числе при необходимости с помощью визуальных наблюдений, м²',
            'shortName': UnderlineIndex('S', 'м'),
            'rowIndex': 5
          },
          {
            'name': 'Размер вреда, тыс. руб.',
            'shortName': UnderlineIndex('У', 'м'),
            'showToolTip': true,
            'readOnly': true,
            'rowIndex': 6,
            'bold': true
          }
        ],
        [
          {
            'name':
                'Коэффициент, учитывающий экологические факторы (состояние водных объектов)',
            'shortName': UnderlineIndex('К', 'в'),
            'rowIndex': 0
          },
          {
            'name':
                'Коэффициент  индексации,  учитывающий инфляционную составляющую экономического  развития',
            'shortName': UnderlineIndex('К', 'ин'),
            'rowIndex': 1
          },
          {
            'name':
                'Такса для исчисления размера вреда, причиненного водным объектам сбросом  и  захоронением  в  них  отходов производства и потребления, в том числе выведенных из эксплуатации судов и иных плавучих средств (их частей и механизмов), других крупногабаритных  отходов  производства и потребления (предметов), тыс. руб./т',
            'shortName': UnderlineIndex('Н', 'с'),
            'rowIndex': 2
          },
          {
            'name':
                'Тоннаж брошенных судов и иных плавучих средств (их частей и механизмов), других крупногабаритных отходов производства и потребления (предметов)',
            'shortName': UnderlineIndex('В', ''),
            'rowIndex': 3
          },
          {
            'name': 'Размер вреда, тыс. руб.',
            'shortName': UnderlineIndex('У', 'с'),
            'showToolTip': true,
            'readOnly': true,
            'rowIndex': 4,
            'bold': true
          }
        ],
        [
          {
            'name':
                'Коэффициент,  учитывающий  природно-климатические  условия  в зависимости  от времени  года',
            'shortName': UnderlineIndex('К', 'вг'),
            'rowIndex': 0
          },
          {
            'name':
                'Коэффициент, учитывающий экологические факторы (состояние водных объектов)',
            'shortName': UnderlineIndex('К', 'в'),
            'rowIndex': 1
          },
          {
            'name':
                'Коэффициент  индексации,  учитывающий инфляционную составляющую экономического  развития',
            'shortName': UnderlineIndex('К', 'ин'),
            'rowIndex': 2
          },
          {
            'name':
                'Объем  древесины,  сброшенной  в  водный объект для запрещенного молевого  сплава  древесины  и  сплава  древесины без судовой тяги, а также подтвержденный организацией  (поставщиком)соответствующими  документами учета и органом, установившим нарушение, тыс. м³',
            'shortName': UnderlineIndex('О', 'д'),
            'rowIndex': 3
          },
          {
            'name':
                'Фактический  объем  древесины, доставленный получателю согласно акту приемки-сдачи, тыс. м³',
            'shortName': UnderlineIndex('О', 'дф'),
            'rowIndex': 4
          },
          {
            'name':
                'Такса для исчисления размера вреда, причиненного водным объектам затоплением древесины, тыс. руб./м³',
            'shortName': UnderlineIndex('Н', 'д'),
            'rowIndex': 5
          },
          {
            'name': 'Размер вреда, тыс. руб.',
            'shortName': UnderlineIndex('У', 'д'),
            'showToolTip': true,
            'readOnly': true,
            'rowIndex': 6,
            'bold': true
          }
        ],
        [
          {
            'name':
                'Коэффициент,  учитывающий  природно-климатические  условия  в зависимости  от времени  года',
            'shortName': UnderlineIndex('К', 'вг'),
            'rowIndex': 0
          },
          {
            'name':
                'Коэффициент, учитывающий экологические факторы (состояние водных объектов)',
            'shortName': UnderlineIndex('К', 'в'),
            'rowIndex': 1
          },
          {
            'name':
                'Коэффициент  индексации,  учитывающий инфляционную составляющую экономического  развития',
            'shortName': UnderlineIndex('К', 'ин'),
            'rowIndex': 2
          },
          {
            'name':
                'Таксы для исчисления размера вреда, причиненного водным объектам загрязнением   взвешенными веществами  при  разведке  и  добыче  полезных ископаемых,  проведении дноуглубительных, взрывных, буровых и других работ, связанных  с  изменением  дна  и  берегов водных  объектов,  а  также  приразрушении в результате аварий гидротехнических и иных сооружений на водных объектах, млн. руб',
            'shortName': UnderlineIndex('Н', 'взв'),
            'rowIndex': 3
          },
          {
            'name': 'Размер вреда, тыс. руб.',
            'shortName': UnderlineIndex('У', 'вв'),
            'showToolTip': true,
            'readOnly': true,
            'rowIndex': 4,
            'bold': true
          }
        ],
        [
          {
            'name':
                'Коэффициент, учитывающий экологические факторы (состояние водных объектов)',
            'shortName': UnderlineIndex('К', 'в'),
            'rowIndex': 0
          },
          {
            'name':
                'Коэффициент  индексации,  учитывающий инфляционную составляющую экономического  развития',
            'shortName': UnderlineIndex('К', 'ин'),
            'rowIndex': 1
          },
          {
            'name':
                'Такса для исчисления размера вреда, причиненного водным объектам при  их  частичном или полном истощении в результате забора (изъятия) воды',
            'shortName': UnderlineIndex('Н', 'и'),
            'rowIndex': 2
          },
          {
            'name':
                'Объем воды, необходимый для восстановления водного объекта от истощения, принимается равным двойному объему безвозвратного изъятия (забора) воды из водного объекта (при превышении установленного договором водопользования общего объема забора (изъятия) водных ресурсов или без наличия документов, на основании которых возникает право пользования водными объектами), тыс. м³',
            'shortName': UnderlineIndex('О', 'в'),
            'rowIndex': 3
          },
          {
            'name': 'Размер вреда, тыс. руб.',
            'shortName': UnderlineIndex('У', 'и'),
            'showToolTip': true,
            'readOnly': true,
            'rowIndex': 4,
            'bold': true
          }
        ],
        [
          {
            'name':
                'Коэффициент, учитывающий экологические факторы (состояние водных объектов)',
            'shortName': UnderlineIndex('К', 'в'),
            'rowIndex': 0
          },
          {
            'name':
                'Коэффициент  индексации,  учитывающий инфляционную составляющую экономического  развития',
            'shortName': UnderlineIndex('К', 'ин'),
            'rowIndex': 1
          },
          {
            'name':
                'Такса для исчисления размера вреда, причиненного водным объектам при  добыче  полезных ископаемых (строительных материалов) в зависимости от массы  их  добычи',
            'shortName': UnderlineIndex('Н', 'пг'),
            'rowIndex': 2
          },
          {
            'name': 'Размер вреда, тыс. руб.',
            'shortName': UnderlineIndex('У', 'дс'),
            'showToolTip': true,
            'readOnly': true,
            'rowIndex': 3,
            'bold': true
          }
        ],
      ];

      values[3][4] = 0.8;
      values[4][2] = 40;
      values[5][5] = 1;
    } catch (e) {} finally {
      hideDialog(context);
      showLoading = false;
      setState(() => {});
    }
    return;
  }

  Widget generateTable(
      BuildContext context, List<List<Map<String, dynamic>>> rowsList) {
    Map<int, TableColumnWidth> columnWidths = {
      0: FlexColumnWidth(10),
      1: FlexColumnWidth(1),
      2: FlexColumnWidth(1),
      3: FlexColumnWidth(2),
      4: FlexColumnWidth(.5)
    };

    List<TableRow> tableRows = [];
    List<Map<String, dynamic>> rows = rowsList[_type - 1];

    rows.forEach((row) {
      TableRow tableRow = TableRow(children: [
        Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Expanded(
                  child: Container(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        '${row["name"]}',
                        style: TextStyle(
                            fontStyle: FontStyle.normal,
                            fontWeight: row["bold"] == true
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                            color: Theme.of(context).buttonColor),
                      ))),
            ])),
        Container(
          padding: EdgeInsets.symmetric(
              vertical: row["haveSum"] == true ? 0 : 10, horizontal: 3),
          alignment: Alignment.center,
          child: row["shortName"] ?? Text(''),
        ),
        Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              (row["rowIndex"] + 1).toString(),
            )),
        EditDigitField(
          text: null,

          value: values[_type - 1][row["rowIndex"]]
                  ?.toString()
                  ?.replaceAll('.', ',') ??
              '',
          onSaved: (value) => {
            setState(() {
              values[_type - 1][row["rowIndex"]] =
                  double.tryParse(value.replaceAll(',', '.'));
            })
          },
          context: context,

          readOnly: row["readOnly"] ?? false,
          backgroundColor: row["readOnly"] == true
              ? Theme.of(context).primaryColorLight
              : null,
          //height: 30,
          margin: 3,
          borderColor: Theme.of(context).primaryColorDark,
        ),
        (row["showToolTip"] == true)
            ? MyToolTip(
                Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).primaryColor, width: 0),
                      color: Theme.of(context).primaryColor,
                    ),
                    //  height: 75,
                    //   width: 300,
                    // alignment: Alignment.center,
                    padding: EdgeInsets.all(5),
                    child: harmType[_type - 1]["formula"]),
                bgColor: Theme.of(context).primaryColor)
            : Text(''),
      ]);
      tableRows.add(tableRow);
    });

    return Table(
        border: TableBorder.all(color: Colors.transparent),
        columnWidths: columnWidths,
        children: tableRows);
  }

  calc() {
    double harm = 1.0;
    bool hasValue = false;
    switch (_type) {
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 7:
      case 8:
      case 9:
        for (int i = 0; i < values[_type - 1].length - 1; i++) {
          harm *= values[_type - 1][i] ?? 1;
          if (values[_type - 1][i] != null) hasValue = true;
        }

        break;

      case 6:
        double Odif = (values[_type - 1][3] ?? 0) - (values[_type - 1][4] ?? 0);
        for (int i = 0; i < values[_type - 1].length - 1; i++) {
          if (i != 3 && i != 4) harm *= values[_type - 1][i] ?? 1;
          if (values[_type - 1][i] != null) hasValue = true;
        }
        if (values[_type - 1][3] == null && values[_type - 1][4] == null)
          Odif = 1;
        harm *= Odif;

        break;
    }
    if (!hasValue) harm = null;
    values[_type - 1].last = harm;
    _harm = harm;
    setState(() {});
  }

  save() async {
    bool hasErorr = false;
    Map<String, dynamic> result;
    double damageAmount = values[_type - 1].last;
    Fault fault = await FaultController.selectById(widget.faultId);
    fault.damageAmount = damageAmount;
    try {
      result = await FaultController.update(fault, [], []);
      hasErorr = result["code"] < 0;

      if (hasErorr) {
        // Navigator.pop<bool>(context, false);
        if (context != null) Scaffold.of(context).showSnackBar(errorSnackBar());
      } else {
        if (context != null) Scaffold.of(context).showSnackBar(successSnackBar);
      }
    } catch (e) {
      //Navigator.pop<bool>(context, false);
      if (context != null) Scaffold.of(context).showSnackBar(errorSnackBar());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/frameScreen.png"),
                fit: BoxFit.fill)),
        child: showLoading
            ? Text("")
            : Container(
                padding:
                    EdgeInsets.only(top: 10, bottom: 10, left: 50, right: 30),
                child: SingleChildScrollView(
                    child: Column(children: [
                  Container(
                      alignment: Alignment.topLeft,
                      child: FormTitle(
                          'Расчет вреда, причененного водным объектам')),
                  GestureDetector(
                      onTap: () => setState(() {
                            showTypeSelection = !showTypeSelection;
                          }),
                      child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 0),
                          child: Row(children: <Widget>[
                            IconButton(
                              iconSize: 35,
                              padding: EdgeInsets.all(0),
                              icon: showTypeSelection == true
                                  ? Icon(Icons.expand_less)
                                  : Icon(Icons.expand_more), //Icons.logout),
                              color: Theme.of(context).primaryColorDark,
                              onPressed: () => setState(() {
                                showTypeSelection = !showTypeSelection;
                              }),
                            ),
                            Expanded(
                                child: RichText(
                              text: TextSpan(
                                  text: "Тип вреда: ",
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: 16),
                                  children: [
                                    TextSpan(
                                        text: '$harmName',
                                        style: TextStyle(
                                            fontSize: 18,
                                            backgroundColor: Theme.of(context)
                                                .primaryColorLight
                                                .withOpacity(.7)))
                                  ]),
                              softWrap: true,
                            ))
                          ]))),
                  //  if (showTypeSelection)
                  AnimatedSwitcher(
                      // curve: Curves.easeOut,
                      //  opacity: showTypeSelection ? 1 : 0,
                      duration: Duration(milliseconds: 300),
                      child: showTypeSelection
                          ? Container(
                              key: UniqueKey(),
                              height: 370,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12.0)),
                                border: Border.all(
                                    color: Theme.of(context).primaryColorDark,
                                    width: 2),
                                color: Theme.of(context)
                                    .primaryColorLight
                                    .withOpacity(.5),
                              ),
                              child: ListView(
                                children: List.generate(
                                    harmType.length,
                                    (index) => ListTile(
                                          onTap: () => setState(() {
                                            _type = harmType[index]["id"];
                                            harmName = harmType[index]["name"];
                                            showTypeSelection = false;

                                            _harm = values[_type - 1].last;
                                          }),
                                          title: Text(
                                            harmType[index]["name"],
                                          ),
                                          leading: Radio(
                                            value: harmType[index]["id"],
                                            groupValue: _type,
                                            activeColor:
                                                Theme.of(context).primaryColor,
                                            onChanged: (value) {
                                              setState(() {
                                                _type = value;

                                                harmName =
                                                    harmType[index]["name"];
                                                showTypeSelection = false;

                                                _harm = values[_type - 1].last;
                                              });
                                            },
                                          ),
                                        )),
                              ))
                          : Container(
                              child: Text(''),
                              height: 0,
                            )),
                  Container(
                    constraints: BoxConstraints.tight(Size(
                        double.infinity,
                        harmName.length < 230
                            ? 320
                            : (harmName.length < 285 ? 300 : 280))),
                    // height: 350,
                    child: SingleChildScrollView(
                      child: generateTable(context, _rows),
                    ),
                  ),
                  Container(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MyButton(
                              text: 'Расчитать',
                              parentContext: context,
                              onPress: calc),
                          MyButton(
                              text: 'Сохранить',
                              disabled: _harm == null,
                              parentContext: context,
                              onPress: save),
                        ],
                      )),
                ]))));
  }
}
