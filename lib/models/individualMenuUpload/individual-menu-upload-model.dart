import 'package:dio/dio.dart';

class IndividualMenuUploadModel {
  final String itemName;
  final String itemPrice;
  final String itemDescription;
  final String itemImage;
  final String itemCategory;

  IndividualMenuUploadModel({
    required this.itemName,
    required this.itemPrice,
    required this.itemDescription,
    required this.itemImage,
    required this.itemCategory,
  });

  Future<FormData> toFormData() async{
    return FormData.fromMap({
      "item_name" : itemName,
      "item_price" : itemPrice,
      "item_description" : itemDescription,
      "item_image" : await MultipartFile.fromFile(
        itemImage,
        filename:itemImage.split('/').last,
      ),
      "item_category" : itemCategory
    });
  }

}

class IndividualMenuUploadResponseModel{
  final bool status;
  final String message;

  IndividualMenuUploadResponseModel({required this.status, required this.message});

  factory IndividualMenuUploadResponseModel.fromJson(Map<String, dynamic> json) {
    return IndividualMenuUploadResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
    );
  }
}
