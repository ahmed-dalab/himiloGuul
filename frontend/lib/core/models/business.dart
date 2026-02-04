class Business {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String? website;
  final String? description;
  final String? category;
  final double? askingPrice;
  final String? location;
  final List<BusinessImage> images;
  final String status;
  final bool isSold;
  final DateTime createdAt;
  /// Owner (seller) user id - for contact form sellerRef
  final String? ownerId;

  Business({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    this.website,
    this.description,
    this.category,
    this.askingPrice,
    this.location,
    required this.images,
    required this.status,
    required this.isSold,
    required this.createdAt,
    this.ownerId,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    final ownerId = owner is Map ? (owner['_id'] as String?) : (owner is String ? owner : null);
    return Business(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'],
      description: json['description'],
      category: json['category'],
      askingPrice: (json['askingPrice'] as num?)?.toDouble(),
      location: json['location'],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => BusinessImage.fromJson(e))
              .toList() ??
          [],
      status: json['status'] ?? 'pending',
      isSold: json['isSold'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      ownerId: ownerId,
    );
  }
}

class BusinessImage {
  final String url;
  final String publicId;

  BusinessImage({
    required this.url,
    required this.publicId,
  });

  factory BusinessImage.fromJson(Map<String, dynamic> json) {
    return BusinessImage(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }
}
