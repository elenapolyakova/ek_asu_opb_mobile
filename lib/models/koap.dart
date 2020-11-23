import 'package:ek_asu_opb_mobile/controllers/controllers.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";

class Koap extends Models {
  int id;
  String article; //Статья
  String paragraph; // Пункт // Параграф
  String text; //Описание
  int man_fine_from; //Штраф на должностное лицо. От
  int man_fine_to; //Штраф на должностное лицо. До
  int firm_fine_from; //Штраф на юридическое  лицо. От
  int firm_fine_to; //Штраф на юридическое  лицо. До
  int firm_stop; //Срок приостановки деятельности, дней
  int desc;

  Future<String> get fineName async {
    Koap koapItem = await KoapController.selectById(id);
    if (koapItem != null)
      return (koapItem.article != null ? 'ст. ${koapItem.article}' : '') +
          (koapItem.paragraph != null ? ' п. ${koapItem.paragraph}' : '');
    return null;

  }

  Koap(
      {this.id,
      this.article,
      this.paragraph,
      this.text,
      this.man_fine_from,
      this.man_fine_to,
      this.firm_fine_from,
      this.firm_fine_to,
      this.firm_stop,
      this.desc});

  factory Koap.fromJson(Map<String, dynamic> json) => new Koap(
        id: json["id"],
        article: getObj(json["article"]),
        paragraph: getObj(json["paragraph"]),
        text: getObj(json["text"]),
        man_fine_from: getObj(json["man_fine_from"]),
        man_fine_to: getObj(json["man_fine_to"]),
        firm_fine_from: getObj(json["firm_fine_from"]),
        firm_fine_to: getObj(json["firm_fine_to"]),
        firm_stop: getObj(json["firm_stop"]),
        desc: getObj(json["desc"]),
      );

  Koap fromJson(Map<String, dynamic> json) {
    return Koap.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'article': article,
      'paragraph': paragraph,
      'text': text,
      'man_fine_from': man_fine_from,
      'man_fine_to': man_fine_to,
      'firm_fine_from': firm_fine_from,
      'firm_fine_to': firm_fine_to,
      'firm_stop': firm_stop,
      'desc': desc,
      'search_field': (article ?? '') + (paragraph ?? "") + (text ?? "")
    };
  }

  @override
  String toString() {
    return 'Koap{id: $id, article: $article, paragraph: $paragraph, text: $text }';
  }
}
