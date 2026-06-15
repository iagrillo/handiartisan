class Category {
  final int id;
  final String slug;
  final String name;
  final String icon;
// Removed to avoid duplicate type conflicts. Use lib/models/category.dart instead.
  Category({
    this.id = 0,
    required this.slug,
    required this.name,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'icon': icon,
    };
  }

  @override
  String toString() {
    return name;
  }
}