import 'package:ek_asu_opb_mobile/controllers/departmentDocument.dart';
import 'package:ek_asu_opb_mobile/utils/convert.dart';
import "package:ek_asu_opb_mobile/models/models.dart";
import 'dart:io';

class Document extends Models {
  int id;

  ///Раздел
  String section;

  ///Модель с файлом
  String model;

  ///Имя файла
  String fileName;

  ///Id файла
  int fileId;

  /// Id предприятия
  int departmentId;

  ///Имя файла
  String filePath;

  Document({
    this.id,
    this.section,
    this.model,
    this.fileName,
    this.fileId,
    this.departmentId,
    this.filePath,
  });

  ///Файл
  Future<File> get file async {
    return DepartmentDocumentController.getLocalDocument(this);
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    Document res = new Document(
      id: json["id"],
      section: getObj(json["section"]),
      model: getObj(json["model"]),
      fileName: getObj(json["file_name"]),
      fileId: getObj(json["file_id"]),
      departmentId: unpackListId(json["department_id"])['id'],
      filePath: getObj(json["file_path"]),
    );
    return res;
  }

  Map<String, dynamic> toJson([omitId = false]) {
    Map<String, dynamic> res = {
      'id': id,
      'section': section,
      'model': model,
      'file_name': fileName,
      'file_id': fileId,
      'file_path': filePath,
      'department_id': departmentId,
    };
    if (omitId) {
      res.remove('id');
    }
    return res;
  }

  @override
  String toString() {
    return 'Document{id: $id, file_name: $fileName}';
  }
}
