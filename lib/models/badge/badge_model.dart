class BadgeItemModel {
  final int id;
  final String name;
  final int points;
  final String type;
  final String image;
  final String status;

  BadgeItemModel({
    required this.id,
    required this.name,
    required this.points,
    required this.type,
    required this.image,
    required this.status,
  });

  factory BadgeItemModel.fromJson(Map<String, dynamic> json) {
    return BadgeItemModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      points: json['points'] ?? 0,
      type: json['type'] ?? '',
      image: _resolveImageUrl(json['image']),
      status: json['status'] ?? '',
    );
  }
}

class BadgesResponseModel {
  final int currentPoints;
  final BadgeItemModel? currentBadge;
  final List<BadgeItemModel> badges;

  BadgesResponseModel({
    required this.currentPoints,
    required this.currentBadge,
    required this.badges,
  });

  factory BadgesResponseModel.fromJson(Map<String, dynamic> json) {
    return BadgesResponseModel(
      currentPoints: json['current_points'] ?? 0,
      currentBadge: json['current_badge'] != null &&
              json['current_badge'] is Map<String, dynamic>
          ? BadgeItemModel.fromJson(json['current_badge'])
          : null,
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((e) => BadgeItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

const String _imageHost = 'https://fudikko.bitwissenddev.in';

String _resolveImageUrl(dynamic raw) {
  final path = (raw ?? '').toString();
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return '$_imageHost$normalizedPath';
}