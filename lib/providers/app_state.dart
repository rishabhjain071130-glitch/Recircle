import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/pickup.dart';
import '../models/impact_stats.dart';
import '../models/reuse_idea.dart';

class AppState extends ChangeNotifier {
  User _user = User.defaultUser;
  List<Pickup> _pickups = List.from(Pickup.samplePickups);
  ImpactStats _impactStats = const ImpactStats(
    itemsReused: 0,
    itemsRecycled: 0,
    pickupsCompleted: 0,
    rewardPoints: 0,
  );
  final List<RewardActivity> _rewardActivities = [];

  User get user => _user;
  List<Pickup> get pickups => List.unmodifiable(_pickups);
  ImpactStats get impactStats => _impactStats;
  List<RewardActivity> get rewardActivities => List.unmodifiable(_rewardActivities);

  Pickup? get activePickup {
    final active = _pickups.where((p) => p.isActive).toList();
    if (active.isNotEmpty) {
      return active.first;
    }
    return null;
  }

  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  void markItemAsReused(ReuseIdea idea) {
    const pointsEarned = 20;
    _impactStats = _impactStats.copyWith(
      itemsReused: _impactStats.itemsReused + 1,
      rewardPoints: _impactStats.rewardPoints + pointsEarned,
    );
    _rewardActivities.insert(
      0,
      RewardActivity(
        title: 'Reused: ${idea.title}',
        category: idea.category,
        points: pointsEarned,
        date: DateTime.now(),
        note: 'Eligible reward credited upon verification.',
      ),
    );
    notifyListeners();
  }

  void bookPickup(Pickup pickup) {
    _pickups.insert(0, pickup);
    notifyListeners();
  }

  void advancePickupStatus(String pickupId) {
    final index = _pickups.indexWhere((p) => p.id == pickupId);
    if (index != -1) {
      final current = _pickups[index];
      final currentStep = current.status.stepIndex;
      if (currentStep < PickupStatus.values.length - 1) {
        final nextStatus = PickupStatus.values[currentStep + 1];
        _pickups[index] = current.copyWith(status: nextStatus);

        if (nextStatus == PickupStatus.completed) {
          const pointsEarned = 50;
          _impactStats = _impactStats.copyWith(
            pickupsCompleted: _impactStats.pickupsCompleted + 1,
            itemsRecycled: _impactStats.itemsRecycled + 1,
            rewardPoints: _impactStats.rewardPoints + pointsEarned,
          );
          _rewardActivities.insert(
            0,
            RewardActivity(
              title: 'Pickup Completed: #${current.id}',
              category: current.category,
              points: pointsEarned,
              date: DateTime.now(),
              note: 'Eligible reward credited upon verification.',
            ),
          );
        }
        notifyListeners();
      }
    }
  }
}
