enum PickupStatus {
  booked,
  partnerAssigned,
  pickupInProgress,
  collected,
  processing,
  completed,
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
  final String quantity; // e.g. "2 kg", "3 items"
  final String pickupAddress;
  final String preferredDate;
  final String preferredTime;
  final PickupStatus status;
  final DateTime createdAt;
  final String? notes;

  const Pickup({
    required this.id,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.pickupAddress,
    required this.preferredDate,
    required this.preferredTime,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  bool get isActive => status != PickupStatus.completed;

  List<PickupTimelineItem> get timeline {
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
      'Partner is en route to your address.',
      'Items collected and verified by partner.',
      'Items transported to sorting & recycling facility.',
      'Recycling complete. Rewards updated!',
    ];

    return List.generate(allSteps.length, (index) {
      return PickupTimelineItem(
        title: allSteps[index],
        description: descriptions[index],
        isCompleted: index <= currentIndex,
        timestamp: index <= currentIndex ? createdAt.add(Duration(hours: index * 2)) : null,
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
  }) {
    return Pickup(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTime: preferredTime ?? this.preferredTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  static List<Pickup> samplePickups = [
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
  ];
}
