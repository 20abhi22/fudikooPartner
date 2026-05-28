import 'package:dio/dio.dart';

class IndividualMenuEditModel {
  final String imageUrl;
  final String itemName;
  final String itemDescription;
  final String itemPrice;
  final String itemCategory;
  final String menuId;

  IndividualMenuEditModel({
    required this.imageUrl,
    required this.itemName,
    required this.itemDescription,
    required this.itemPrice,
    required this.itemCategory,
    required this.menuId
  });

  Future<FormData> toFormData() async {
    return FormData.fromMap({
      "item_name" : itemName,
      "item_price" : itemPrice,
      "item_description" : itemDescription,
      "item_image" : await MultipartFile.fromFile(
          imageUrl,
        filename: imageUrl.split('/').last
      ),
      "item_category" : itemCategory,
      "menu_id" : menuId
    });
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