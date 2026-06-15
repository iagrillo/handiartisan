class SponsoredItem {
  final String id;
  final String title;
  final String subtitle;
  final String offer;
  final double rating;
  final String phone;
  final String whatsapp;
  final String iconName;
  final String category;
  final DateTime? createdAt;

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
    this.createdAt,
  });

  factory SponsoredItem.fromJson(Map<String, dynamic> json) => SponsoredItem(
        id: json['id']?.toString() ?? '',
        title: json['title'] ?? '',
        subtitle: json['subtitle'] ?? '',
        offer: json['offer'] ?? '',
        rating: (json['rating'] is int)
            ? (json['rating'] as int).toDouble()
            : (json['rating'] ?? 4.5),
        phone: json['phone'] ?? '',
        whatsapp: json['whatsapp'] ?? '',
        iconName: json['iconName'] ?? 'business',
        category: json['category'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
      );
}
