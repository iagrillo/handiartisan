import 'dart:convert';

enum AdType {
  featured,
  native,
  category,
  banner,
}

AdType? adTypeFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'featured':
      return AdType.featured;
    case 'native':
      return AdType.native;
    case 'category':
      return AdType.category;
    case 'banner':
      return AdType.banner;
    default:
      return null;
  }
}

String? adTypeToString(AdType? value) {
  switch (value) {
    case AdType.featured:
      return 'featured';
    case AdType.native:
      return 'native';
    case AdType.category:
      return 'category';
    case AdType.banner:
      return 'banner';
    case null:
      return null;
  }
}

class Artisan {
  final String? id;
  final String fullName;
  final String? businessName;
  String phone;
  String? email;
  final String? whatsapp;
  final String category;
  final String? bio;
  final String? address;
  final String? state;
  final String? city;
  final String? status;
  final bool? isAvailable;
  final double? latitude;
  final double? longitude;
  final String? profileImageUrl;
  final List<String>? galleryImageUrls;
  final bool? isFeatured;
  final double? rating;
  final bool isSponsored;
  final AdType? adType;
  final double priorityScore;
  final String? createdAt;
  final String? tradetype;
  // NOTE: Password storage is deprecated. Use Supabase Auth for authentication.
  // This field is kept for legacy data migration only.
  // Passwords should NEVER be stored in plaintext - use Supabase Auth instead.
  @Deprecated('Use Supabase Auth instead of storing passwords')
  final String? password;
  final String? authToken;

  // 🔥 MUST NOT BE FINAL
  bool? showDistance;

  Artisan({
    this.id,
    required this.fullName,
    this.businessName,
    required this.phone,
    this.whatsapp,
    required this.category,
    this.bio,
    this.address,
    this.state,
    this.city,
    this.status,
    this.isAvailable,
    this.latitude,
    this.longitude,
    this.email,
    this.profileImageUrl,
    this.galleryImageUrls,
    this.isFeatured,
    this.createdAt,
    this.tradetype,
    this.password,
    this.authToken,
    this.rating,
    this.isSponsored = false,
    this.adType,
    this.priorityScore = 0,
    this.showDistance,
  });

  factory Artisan.fromJson(Map<String, dynamic> json) {
    return Artisan(
      id: json['id']?.toString(),
      fullName: json['full_name'] ?? '',
      businessName: json['business_name'],
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'],
      category: json['category'] ?? '',
      bio: json['bio'],
      address: json['address'],
      state: json['state'],
      city: json['city'],
      status: json['status'],
      isAvailable: json['is_available'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      email: json['email'],
      profileImageUrl: json['profile_image_url'],
      galleryImageUrls: json['gallery_image_urls'] != null
          ? (json['gallery_image_urls'] is String
              ? List<String>.from(jsonDecode(json['gallery_image_urls']))
              : List<String>.from(json['gallery_image_urls']))
          : null,
      isFeatured: json['is_featured'],
      rating: (json['rating'] as num?)?.toDouble(),
        isSponsored: json['is_sponsored'] == true,
        adType: adTypeFromString(json['ad_type']?.toString()) ??
          ((json['is_featured'] == true) ? AdType.featured : null),
        priorityScore: (json['priority_score'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'],
      tradetype: json['tradetype'],
      authToken: json['auth_token'],
      showDistance: json['show_distance'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'business_name': businessName,
      'phone': phone,
      'whatsapp': whatsapp,
      'category': category,
      'bio': bio,
      'address': address,
      'state': state,
      'city': city,
      'status': status,
      'is_available': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'email': email,
      'profile_image_url': profileImageUrl,
      'gallery_image_urls': galleryImageUrls,
      'is_featured': isFeatured,
      'rating': rating,
      'is_sponsored': isSponsored,
      'ad_type': adTypeToString(adType),
      'priority_score': priorityScore,
      'created_at': createdAt,
      'tradetype': tradetype,
      'auth_token': authToken,
      'show_distance': showDistance,
    };
  }

  setPhone(String value) => phone = value;
  setEmail(String? value) => email = value;

  // Get profile image URL with cache busting
  String? get profileImageUrlWithCache {
    if (profileImageUrl == null || profileImageUrl!.isEmpty) return null;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = profileImageUrl!.contains('?') ? '&' : '?';
    return '$profileImageUrl$separator$timestamp';
  }

  Artisan copyWith({
    String? id,
    String? fullName,
    String? businessName,
    String? phone,
    String? whatsapp,
    String? category,
    String? bio,
    String? address,
    String? state,
    String? city,
    String? status,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    String? email,
    String? profileImageUrl,
    List<String>? galleryImageUrls,
    bool? isFeatured,
    double? rating,
    bool? isSponsored,
    AdType? adType,
    double? priorityScore,
    String? createdAt,
    String? tradetype,
    String? password,
    String? authToken,
    bool? showDistance,
  }) {
    return Artisan(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      category: category ?? this.category,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      status: status ?? this.status,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      galleryImageUrls: galleryImageUrls ?? this.galleryImageUrls,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      isSponsored: isSponsored ?? this.isSponsored,
      adType: adType ?? this.adType,
      priorityScore: priorityScore ?? this.priorityScore,
      createdAt: createdAt ?? this.createdAt,
      tradetype: tradetype ?? this.tradetype,
      password: password ?? this.password,
      authToken: authToken ?? this.authToken,
      showDistance: showDistance ?? this.showDistance,
    );
  }
}