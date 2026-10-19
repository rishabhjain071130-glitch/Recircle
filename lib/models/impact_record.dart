class ImpactRecord {
  const ImpactRecord({
    required this.id,
    required this.itemName,
    required this.outcome,
    required this.recordedAt,
    this.estimatedWeightKg,
  }) : assert(estimatedWeightKg == null || estimatedWeightKg >= 0);

  final String id;
  final String itemName;
  final ImpactOutcome outcome;
  final DateTime recordedAt;
  final double? estimatedWeightKg;

  Map<String, Object?> toJson() => {
    'id': id,
    'itemName': itemName,
    'outcome': outcome.name,
    'recordedAt': recordedAt.toIso8601String(),
    'estimatedWeightKg': estimatedWeightKg,
  };
}

enum ImpactOutcome { reused, recycled }
