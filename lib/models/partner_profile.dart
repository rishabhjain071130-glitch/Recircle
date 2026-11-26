class PartnerProfile {
  const PartnerProfile({
    required this.id,
    required this.name,
    required this.businessName,
    required this.partnerType,
    required this.acceptedCategories,
    required this.phone,
    required this.address,
    required this.city,
    required this.pinCode,
    required this.serviceArea,
    required this.partnerStatus,
    required this.available,
    required this.registeredAt,
    this.distanceKm,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String businessName;
  final String partnerType;
  final List<String> acceptedCategories;
  final String phone;
  final String address;
  final String city;
  final String pinCode;
  final String serviceArea;
  final String partnerStatus;
  final bool available;
  final DateTime? registeredAt;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;

  bool get isApproved => partnerStatus == 'approved';
  String get displayName =>
      businessName.trim().isNotEmpty ? businessName : name;

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();
    final categories = json['acceptedCategories'];
    return PartnerProfile(
      id: (json['id'] ?? json['partnerId'] ?? json['_id'] ?? '').toString(),
      name: json['name']?.toString() ?? 'Collection partner',
      businessName: json['businessName']?.toString() ?? '',
      partnerType: json['partnerType']?.toString() ?? '',
      acceptedCategories: categories is List
          ? categories.map((value) => value.toString()).toList(growable: false)
          : const [],
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pinCode: json['pinCode']?.toString() ?? '',
      serviceArea: json['serviceArea']?.toString() ?? '',
      partnerStatus: (json['partnerStatus'] ?? 'pending').toString(),
      available: (json['available'] ?? json['partnerAvailable']) == true,
      registeredAt: DateTime.tryParse(
        (json['registeredAt'] ?? json['createdAt'] ?? '').toString(),
      ),
      distanceKm: number('distanceKm'),
      latitude: number('latitude'),
      longitude: number('longitude'),
    );
  }
}
