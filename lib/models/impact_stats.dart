class ImpactStats {
  final int itemsReused;
  final int itemsRecycled;
  final int pickupsCompleted;
  final int rewardPoints;
  final double estimatedWasteDivertedKg;

  const ImpactStats({
    this.itemsReused = 0,
    this.itemsRecycled = 0,
    this.pickupsCompleted = 0,
    this.rewardPoints = 0,
    this.estimatedWasteDivertedKg = 0,
  }) : assert(itemsReused >= 0),
       assert(itemsRecycled >= 0),
       assert(pickupsCompleted >= 0),
       assert(rewardPoints >= 0),
       assert(estimatedWasteDivertedKg >= 0);

  Map<String, Object?> toJson() => {
    'itemsReused': itemsReused,
    'itemsRecycled': itemsRecycled,
    'pickupsCompleted': pickupsCompleted,
    'rewardPoints': rewardPoints,
    'estimatedWasteDivertedKg': estimatedWasteDivertedKg,
  };

  factory ImpactStats.fromJson(Map<String, Object?> json) => ImpactStats(
    itemsReused: (json['itemsReused'] as num?)?.toInt() ?? 0,
    itemsRecycled: (json['itemsRecycled'] as num?)?.toInt() ?? 0,
    pickupsCompleted: (json['pickupsCompleted'] as num?)?.toInt() ?? 0,
    rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
    estimatedWasteDivertedKg:
        (json['estimatedWasteDivertedKg'] as num?)?.toDouble() ?? 0,
  );

  ImpactStats copyWith({
    int? itemsReused,
    int? itemsRecycled,
    int? pickupsCompleted,
    int? rewardPoints,
    double? estimatedWasteDivertedKg,
  }) {
    return ImpactStats(
      itemsReused: itemsReused ?? this.itemsReused,
      itemsRecycled: itemsRecycled ?? this.itemsRecycled,
      pickupsCompleted: pickupsCompleted ?? this.pickupsCompleted,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      estimatedWasteDivertedKg:
          estimatedWasteDivertedKg ?? this.estimatedWasteDivertedKg,
    );
  }
}

class RewardActivity {
  final String title;
  final String category;
  final int points;
  final DateTime date;
  final String note;

  const RewardActivity({
    required this.title,
    required this.category,
    required this.points,
    required this.date,
    this.note = 'Reward subject to applicable rules.',
  });

  Map<String, Object?> toJson() => {
    'title': title,
    'category': category,
    'points': points,
    'date': date.toIso8601String(),
    'note': note,
  };
}
