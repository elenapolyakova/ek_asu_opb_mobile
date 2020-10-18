import "dart:convert";

Inspection inspectionFromJson(String str) {
  final jsonData = json.decode(str);
  return Inspection.fromJson(jsonData);
}

String inspectionToJson(Inspection data) {
  final dyn = data.toJson();
  return json.encode(dyn);
}

class Inspection {
  final int inspection_id;
  final int type_id;
  final int period_id;
  final String to_be_inspected_name;
  final String auditor_name;

  Inspection({this.inspection_id, this.type_id, this.period_id, this.to_be_inspected_name = '', this.auditor_name = ''});

  factory Inspection.fromJson(Map<String, dynamic> json) => new Inspection(
        inspection_id: json["iinspection_idd"],
        type_id: json["type_id"],
        period_id: json["period_id"],
        to_be_inspected_name: json["to_be_inspected_name"],
        auditor_name: json["auditor_name"],
      );

  Map<String, dynamic> toJson() {
    return {
      'inspection_id': inspection_id,
      'type_id': type_id,
      'period_id': period_id,
      'to_be_inspected_name': to_be_inspected_name,
      'auditor_name': auditor_name,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Inspection{inspection_id: $inspection_id, type_id: $type_id, period_id: $period_id, ' +
    'to_be_inspected_name: $to_be_inspected_name, auditor_name: $auditor_name, }';
  }
}
