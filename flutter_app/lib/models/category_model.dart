class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String color;
  final int orderIndex;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
    required this.color,
    required this.orderIndex,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id:         json['id'] as String,
      name:       json['name'] as String,
      slug:       json['slug'] as String,
      icon:       json['icon'] as String,
      color:      json['color'] as String? ?? '#00e664',
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':          id,
      'name':        name,
      'slug':        slug,
      'icon':        icon,
      'color':       color,
      'order_index': orderIndex,
    };
  }

  // ── Helpers ──────────────────────────────
  
  /// Retourne la couleur sous forme d'objet Color Flutter
  /// Ex: '#00e664' → Color(0xFF00e664)
  int get colorValue {
    final hex = color.replaceAll('#', '');
    return int.parse('FF$hex', radix: 16);
  }

  /// Vérifie si c'est la catégorie Single
  /// (utilisé pour afficher la square ad à la place des native ads)
  bool get isSingle => slug == 'single';

  /// Vérifie si c'est une catégorie basket
  bool get isBasketball => slug == 'basketball';

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, slug: $slug)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}