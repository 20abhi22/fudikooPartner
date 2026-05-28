import 'dart:io';
import 'package:dio/dio.dart';

class MenuUploadModel {
  final File file;
  final String menuName;

  MenuUploadModel({required this.file, required this.menuName});

  Future<FormData> toFormData() async {
    return FormData.fromMap({
      "pdf_file": await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
        contentType: DioMediaType('application', 'pdf'),
      ),
      "menu_name": menuName,
    });
  }
}

class MenuUploadResponseModel {
  final bool status;
  final String message;

  MenuUploadResponseModel({required this.status, required this.message});

  factory MenuUploadResponseModel.fromJson(Map<String, dynamic> json) {
    return MenuUploadResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}