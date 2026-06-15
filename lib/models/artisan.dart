class Artisan {
  final String fullName;
  final String businessName;
  final String phone;
  final String whatsapp;
  final String category;
  final String city;
  final String state;
  final double? rating;
  final double? latitude;
  final double? longitude;
  final double? priorityScore;

  Artisan({
    required this.fullName,
    required this.businessName,
    required this.phone,
    required this.whatsapp,
    required this.category,
    required this.city,
    required this.state,
    this.rating,
    this.latitude,
    this.longitude,
    this.priorityScore,
  });

  factory Artisan.fromJson(Map<String, dynamic> json) => Artisan(
        fullName: json['fullName'] ?? '',
        businessName: json['businessName'] ?? '',
        phone: json['phone'] ?? '',
        whatsapp: json['whatsapp'] ?? '',
        category: json['category'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        rating: (json['rating'] as num?)?.toDouble(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        priorityScore: (json['priorityScore'] as num?)?.toDouble(),
      );
}
