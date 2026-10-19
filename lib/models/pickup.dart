enum PickupStatus {
  booked,
  partnerAssigned,
  pickupInProgress,
  collected,
  processing,
  completed,
  cancelled,
}

extension PickupStatusExtension on PickupStatus {
  String get displayName {
    switch (this) {
      case PickupStatus.booked:
        return 'Booked';
      case PickupStatus.partnerAssigned:
        return 'Partner Assigned';
      case PickupStatus.pickupInProgress:
        return 'Pickup In Progress';
      case PickupStatus.collected:
        return 'Collected';
      case PickupStatus.processing:
        return 'Processing';
      case PickupStatus.completed:
        return 'Completed';
      case PickupStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case PickupStatus.booked:
        return 0;
      case PickupStatus.partnerAssigned:
        return 1;
      case PickupStatus.pickupInProgress:
        return 2;
      case PickupStatus.collected:
        return 3;
      case PickupStatus.processing:
        return 4;
      case PickupStatus.completed:
        return 5;
      case PickupStatus.cancelled:
        return 0;
    }
  }
}

class PickupTimelineItem {
  final String title;
  final String description;
  final DateTime? timestamp;
  final bool isCompleted;

  const PickupTimelineItem({
    required this.title,
    required this.description,
    this.timestamp,
    required this.isCompleted,
  });
}

class Pickup {
  final String id;
  final String itemName;
  final String category; // Plastic, E-Waste, Paper, Metal, Other
  final String itemCondition;
  final String quantity; // e.g. "2 kg", "3 items"
  final String pickupAddress;
  final String pickupContactName;
  final String pickupContactPhone;
  final String preferredDate;
  final String preferredTime;
  final PickupStatus status;
  final DateTime createdAt;
  final String? notes;
  final String? partnerName;
  final List<Map<String, dynamic>> statusHistory;

  factory Pickup.fromApiJson(Map<String, dynamic> json) {
    final item = (json['item'] as Map?)?.cast<String, dynamic>() ?? {};
    final pickup = (json['pickup'] as Map?)?.cast<String, dynamic>() ?? {};
    final rawStatus = json['status'] as String? ?? 'Submitted';
    final status = switch (rawStatus) {
      'Accepted' => PickupStatus.partnerAssigned,
      'Collected' => PickupStatus.collected,
      'ReceivedForProcessing' => PickupStatus.processing,
      'Completed' => PickupStatus.completed,
      'Cancelled' => PickupStatus.cancelled,
      _ => PickupStatus.booked,
    };
    return Pickup(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      itemName: item['name']?.toString() ?? 'Electronic item',
      category: item['category']?.toString() ?? 'E-Waste',
      itemCondition: item['condition']?.toString() ?? 'Not specified',
      quantity: (item['quantity'] ?? 1).toString(),
      pickupAddress: pickup['address']?.toString() ?? '',
      pickupContactName: pickup['contactName']?.toString() ?? '',
      pickupContactPhone: pickup['contactPhone']?.toString() ?? '',
      preferredDate: pickup['preferredDate']?.toString() ?? 'Requested',
      preferredTime: pickup['preferredTime']?.toString() ?? 'Flexible',
      status: status,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      notes: pickup['notes']?.toString(),
      partnerName: (json['partner'] as Map?)?['name']?.toString(),
      statusHistory: ((json['history'] as List?) ?? const [])
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'itemName': itemName,
    'category': category,
    'quantity': quantity,
    'pickupAddress': pickupAddress,
    'preferredDate': preferredDate,
    'preferredTime': preferredTime,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'notes': notes,
  };

  factory Pickup.fromJson(Map<String, Object?> json) => Pickup(
    id: json['id']! as String,
    itemName: json['itemName']! as String,
    category: json['category']! as String,
    quantity: json['quantity']! as String,
    pickupAddress: json['pickupAddress']! as String,
    preferredDate: json['preferredDate']! as String,
    preferredTime: json['preferredTime']! as String,
    status: PickupStatus.values.firstWhere(
      (status) => status.name == json['status'],
      orElse: () => PickupStatus.booked,
    ),
    createdAt: DateTime.parse(json['createdAt']! as String),
    notes: json['notes'] as String?,
  );

  const Pickup({
    required this.id,
    required this.itemName,
    required this.category,
    this.itemCondition = 'Not specified',
    required this.quantity,
    required this.pickupAddress,
    this.pickupContactName = '',
    this.pickupContactPhone = '',
    required this.preferredDate,
    required this.preferredTime,
    required this.status,
    required this.createdAt,
    this.notes,
    this.partnerName,
    this.statusHistory = const [],
  });

  bool get isActive =>
      status != PickupStatus.completed && status != PickupStatus.cancelled;

  List<PickupTimelineItem> get timeline {
    if (statusHistory.isNotEmpty) {
      return statusHistory.map((entry) {
        final status = entry['to']?.toString() ?? 'Updated';
        final at = DateTime.tryParse(entry['at']?.toString() ?? '');
        return PickupTimelineItem(
          title: status == 'ReceivedForProcessing'
              ? 'Received for Processing'
              : status,
          description: (entry['note']?.toString().isNotEmpty ?? false)
              ? entry['note'].toString()
              : 'Status recorded by the collection workflow.',
          timestamp: at,
          isCompleted: true,
        );
      }).toList();
    }
    final currentIndex = status.stepIndex;
    final allSteps = [
      'Request Created',
      'Partner Assigned',
      'Pickup In Progress',
      'Collected',
      'Processing',
      'Completed',
    ];

    final descriptions = [
      'Pickup request successfully submitted.',
      'A collection partner will be assigned soon.',
      'Collection is in progress.',
      'The item was collected by the partner.',
      'Delivery to the processing facility was recorded.',
      'Processing completion was recorded by the partner.',
    ];

    return List.generate(allSteps.length, (index) {
      return PickupTimelineItem(
        title: allSteps[index],
        description: descriptions[index],
        isCompleted: index <= currentIndex,
        timestamp: index == 0 ? createdAt : null,
      );
    });
  }

  Pickup copyWith({
    String? id,
    String? itemName,
    String? category,
    String? quantity,
    String? pickupAddress,
    String? preferredDate,
    String? preferredTime,
    PickupStatus? status,
    DateTime? createdAt,
    String? notes,
    String? partnerName,
    List<Map<String, dynamic>>? statusHistory,
  }) {
    return Pickup(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      itemCondition: itemCondition,
      quantity: quantity ?? this.quantity,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupContactName: pickupContactName,
      pickupContactPhone: pickupContactPhone,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTime: preferredTime ?? this.preferredTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      partnerName: partnerName ?? this.partnerName,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  static final List<Pickup> samplePickups = List.unmodifiable([
    Pickup(
      id: 'RC1024',
      itemName: 'Plastic Bottles & Containers',
      category: 'Plastic',
      quantity: '2.5 kg',
      pickupAddress: 'Your Location',
      preferredDate: 'Tomorrow',
      preferredTime: '10:00 AM - 12:00 PM',
      status: PickupStatus.partnerAssigned,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      notes: 'Please call before arriving.',
    ),
  ]);
}
