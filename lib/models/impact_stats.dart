class ImpactStats {
  final int itemsReused;
  final int itemsRecycled;
  final int pickupsCompleted;
  final int rewardPoints;

  const ImpactStats({
    this.itemsReused = 0,
    this.itemsRecycled = 0,
    this.pickupsCompleted = 0,
    this.rewardPoints = 0,
  });

  ImpactStats copyWith({
    int? itemsReused,
    int? itemsRecycled,
    int? pickupsCompleted,
    int? rewardPoints,
  }) {
    return ImpactStats(
      itemsReused: itemsReused ?? this.itemsReused,
      itemsRecycled: itemsRecycled ?? this.itemsRecycled,
      pickupsCompleted: pickupsCompleted ?? this.pickupsCompleted,
      rewardPoints: rewardPoints ?? this.rewardPoints,
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
}
