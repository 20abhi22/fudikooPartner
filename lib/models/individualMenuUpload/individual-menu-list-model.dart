class IndividualMenuListModel {
  final bool status;
  final List<IndividualMenuModel> menus;

  IndividualMenuListModel({required this.status, required this.menus});

  factory IndividualMenuListModel.fromJson(Map<String, dynamic> json) {
    return IndividualMenuListModel(
      status: json['status'],
      menus: (json['menus'] as List)
          .map((item) => IndividualMenuModel.fromJson(item))
          .toList(),
    );
  }
}

class IndividualMenuModel {
  final String uuid;
  final String partnerUid;
  final String itemName;
  final String itemPrice;
  final String itemDescription;
  final String itemImage;
  final String itemCategory;
  final String status;

  IndividualMenuModel({
    required this.uuid,
    required this.partnerUid,
    required this.itemName,
    required this.itemPrice,
    required this.itemDescription,
    required this.itemImage,
    required this.itemCategory,
    required this.status,
  });

  factory IndividualMenuModel.fromJson(Map<String, dynamic> json) {
    return IndividualMenuModel(
      uuid: json['uuid'],
      partnerUid: json['partner_uid'],
      itemName: json['item_name'],
      itemPrice: json['item_price'],
      itemDescription: json['item_description'],
      itemImage: json['item_image'],
      itemCategory: json['item_category'],
      status: json['status'],
    );
  }

}
