class SponsoredItem {
  final String id;
  final String title;
  final String subtitle;
  final String offer;
  final double rating;
  final String phone;
  final String whatsapp;
  final String iconName;
  final String category; // 'artisan', 'store', 'equipment'
  final DateTime createdAt;

  SponsoredItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.offer,
    required this.rating,
    required this.phone,
    required this.whatsapp,
    required this.iconName,
    required this.category,
    required this.createdAt,
  });

  factory SponsoredItem.fromJson(Map<String, dynamic> json) {
    return SponsoredItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      offer: json['offer'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      iconName: json['icon_name'] ?? 'business',
      category: json['category'] ?? 'artisan',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'offer': offer,
      'rating': rating,
      'phone': phone,
      'whatsapp': whatsapp,
      'icon_name': iconName,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SponsoredItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? offer,
    double? rating,
    String? phone,
    String? whatsapp,
    String? iconName,
    String? category,
    DateTime? createdAt,
  }) {
    return SponsoredItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      offer: offer ?? this.offer,
      rating: rating ?? this.rating,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      iconName: iconName ?? this.iconName,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
