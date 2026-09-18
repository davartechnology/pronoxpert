class AdModel {
  final String id;
  final String type; // splash | banner | native | square
  final String imageUrl;
  final String? linkUrl;
  final bool isActive;

  AdModel({
    required this.id,
    required this.type,
    required this.imageUrl,
    this.linkUrl,
    required this.isActive,
  });

  factory AdModel.fromJson(Map<String, dynamic> json) {
    return AdModel(
      id: json['id'],
      type: json['type'],
      imageUrl: json['image_url'],
      linkUrl: json['link_url'],
      isActive: json['is_active'] ?? true,
    );
  }
}