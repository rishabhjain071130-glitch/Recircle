class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.relatedPickupId,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String? relatedPickupId;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final pickupId = json['relatedPickupId'] ?? json['relatedRequestId'];
    return AppNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? 'ReCircle update',
      message: json['message']?.toString() ?? '',
      relatedPickupId: pickupId?.toString(),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    relatedPickupId: relatedPickupId,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}
