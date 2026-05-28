class MenuModel {
  final int id;
  final String uuid;
  final String menuName;
  final String pdfPath;
  final String status;

  MenuModel({
    required this.id,
    required this.uuid,
    required this.menuName,
    required this.pdfPath,
    required this.status,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      menuName: json['menu_name'] ?? '',
      pdfPath: json['pdf_path'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class MenuListModel {
  final bool status;
  final List<MenuModel> menus;

  MenuListModel({required this.status, required this.menus});

  factory MenuListModel.fromJson(Map<String, dynamic> json) {
    final menuList = (json['menus'] as List<dynamic>? ?? [])
        .map((e) => MenuModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return MenuListModel(
      status: json['status'] ?? false,
      menus: menuList,
    );
  }
}