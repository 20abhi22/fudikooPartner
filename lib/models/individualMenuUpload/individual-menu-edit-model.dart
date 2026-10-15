import 'package:dio/dio.dart';

class IndividualMenuEditModel {
  // Local file path of a newly picked replacement image. Null/empty when the
  // user kept the existing (remote) image unchanged — in that case the image
  // field is omitted entirely so the backend keeps the current image, rather
  // than trying to upload the remote URL as if it were a local file.
  final String? newImagePath;
  final String itemName;
  final String itemDescription;
  final String itemPrice;
  final String itemCategory;
  final String menuId;

  IndividualMenuEditModel({
    this.newImagePath,
    required this.itemName,
    required this.itemDescription,
    required this.itemPrice,
    required this.itemCategory,
    required this.menuId
  });

  Future<FormData> toFormData() async {
    final map = <String, dynamic>{
      "item_name" : itemName,
      "item_price" : itemPrice,
      "item_description" : itemDescription,
      "item_category" : itemCategory,
      "menu_id" : menuId
    };

    if (newImagePath != null && newImagePath!.isNotEmpty) {
      map["item_image"] = await MultipartFile.fromFile(
        newImagePath!,
        filename: newImagePath!.split('/').last,
      );
    }

    return FormData.fromMap(map);
  }

}

class IndividualMenuEditResponseModel {
  final bool status;
  final String message;

  IndividualMenuEditResponseModel({required this.status, required this.message});

  factory IndividualMenuEditResponseModel.fromJson(Map<String, dynamic> json) {
    return IndividualMenuEditResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}