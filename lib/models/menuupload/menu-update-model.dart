import 'dart:io';
import 'package:dio/dio.dart';

class MenuUpdateModel {
  final String menuId;
  final String menuName;
  final String? pdfFilePath; // nullable — only send if changed

  MenuUpdateModel({
    required this.menuId,
    required this.menuName,
    this.pdfFilePath,
  });

  Future<FormData> toFormData() async {
    final map = <String, dynamic>{
      "menu_id": menuId,
      "menu_name": menuName,
    };

    if (pdfFilePath != null) {
      final file = File(pdfFilePath!);
      map["pdf_file"] = await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
        contentType: DioMediaType('application', 'pdf'),
      );
    }

    return FormData.fromMap(map);
  }
}

class MenuUpdateResponseModel {
  final bool status;
  final String message;

  MenuUpdateResponseModel({required this.status, required this.message});

  factory MenuUpdateResponseModel.fromJson(Map<String, dynamic> json) {
    return MenuUpdateResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}