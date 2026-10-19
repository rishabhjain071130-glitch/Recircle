import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/pickup.dart';
import '../models/impact_stats.dart';
import '../models/reuse_idea.dart';
import '../features/requests/data/recircle_api.dart';

class AppState extends ChangeNotifier {
  AppState({ReCircleApi? api}) : api = api ?? ReCircleApi();

  User _user = User.defaultUser;
  final List<Pickup> _pickups = [];
  final ReCircleApi api;
  bool sessionReady = false;
  bool loadingRequests = false;
  String? currentRole;
  String? requestError;
  bool get isAuthenticated => currentRole != null;
  bool get isPartner => currentRole == 'partner';
  ImpactStats _impactStats = const ImpactStats(
    itemsReused: 0,
    itemsRecycled: 0,
    pickupsCompleted: 0,
    rewardPoints: 0,
  );
  final List<RewardActivity> _rewardActivities = [];
  final Set<String> _savedReuseIdeaIds = {};

  User get user => _user;
  List<Pickup> get pickups => List.unmodifiable(_pickups);
  ImpactStats get impactStats => _impactStats;
  List<RewardActivity> get rewardActivities =>
      List.unmodifiable(_rewardActivities);
  bool isReuseIdeaSaved(String ideaId) => _savedReuseIdeaIds.contains(ideaId);

  Future<void> restoreSession() async {
    try {
      await api.restoreToken();
      if (!api.hasSessionToken) return;
      final profile = (await api.get('/auth/me') as Map)
          .cast<String, dynamic>();
      _setProfile(profile);
      await refreshRequests();
    } on ApiException catch (error) {
      requestError = error.message;
      if (error.statusCode == 401) await logout();
    } finally {
      sessionReady = true;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    final result = (await api.login(email, password) as Map)
        .cast<String, dynamic>();
    await api.saveToken(result['token'] as String);
    _setProfile((result['user'] as Map).cast<String, dynamic>());
    try {
      await refreshRequests();
    } on ApiException {
      /* Keep a valid session when the request list is temporarily offline. */
    }
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    final result = (await api.register(name, email, password) as Map)
        .cast<String, dynamic>();
    await api.saveToken(result['token'] as String);
    _setProfile((result['user'] as Map).cast<String, dynamic>());
    try {
      await refreshRequests();
    } on ApiException {
      /* Keep a valid session when the request list is temporarily offline. */
    }
    notifyListeners();
  }

  void _setProfile(Map<String, dynamic> profile) {
    currentRole = profile['role']?.toString();
    _user = User(
      name: profile['name']?.toString() ?? 'ReCircle User',
      email: profile['email']?.toString() ?? '',
      phone: _user.phone,
      location: _user.location,
    );
  }

  Future<void> logout() async {
    await api.clearToken();
    currentRole = null;
    _pickups.clear();
    requestError = null;
    notifyListeners();
  }

  Future<void> refreshRequests() async {
    loadingRequests = true;
    requestError = null;
    notifyListeners();
    try {
      final result = isPartner
          ? await api.get('/partner/requests/mine')
          : await api.get('/requests/mine');
      final data = (result as List?) ?? const [];
      _pickups
        ..clear()
        ..addAll(
          data.whereType<Map>().map(
            (entry) => Pickup.fromApiJson(entry.cast<String, dynamic>()),
          ),
        );
    } on ApiException catch (error) {
      requestError = error.message;
      if (error.statusCode == 401) {
        currentRole = null;
        _pickups.clear();
      }
      rethrow;
    } finally {
      loadingRequests = false;
      notifyListeners();
    }
  }

  Future<Pickup> createRequest({
    required String itemName,
    required String category,
    required String condition,
    required int quantity,
    required String address,
    required String contactName,
    required String contactPhone,
    String? notes,
    String? preferredDate,
    String? preferredTime,
  }) async {
    final pickupDetails = <String, dynamic>{
      'address': address,
      'contactName': contactName,
      'contactPhone': contactPhone,
    };
    if (preferredDate != null) pickupDetails['preferredDate'] = preferredDate;
    if (preferredTime != null) pickupDetails['preferredTime'] = preferredTime;
    if (notes != null && notes.isNotEmpty) pickupDetails['notes'] = notes;
    final result = await api.post('/requests', {
      'item': {
        'category': category,
        'name': itemName,
        'condition': condition,
        'quantity': quantity,
      },
      'pickup': pickupDetails,
    });
    final raw = (result as Map).cast<String, dynamic>();
    final pickup = Pickup.fromApiJson(raw);
    _pickups.insert(0, pickup);
    notifyListeners();
    return pickup;
  }

  Future<List<Pickup>> eligibleRequests() async {
    final result = await api.get('/partner/requests/eligible');
    return ((result as List?) ?? const [])
        .whereType<Map>()
        .map((entry) => Pickup.fromApiJson(entry.cast<String, dynamic>()))
        .toList();
  }

  Future<void> acceptRequest(String id) async {
    await api.post('/partner/requests/$id/accept');
    await refreshRequests();
  }

  Future<void> updatePartnerStatus(
    String id,
    PickupStatus target, {
    String note = '',
  }) async {
    final status = switch (target) {
      PickupStatus.collected => 'Collected',
      PickupStatus.processing => 'ReceivedForProcessing',
      PickupStatus.completed => 'Completed',
      _ => throw const ApiException('This status transition is not available.'),
    };
    await api.patch('/partner/requests/$id/status', {
      'status': status,
      if (note.isNotEmpty) 'note': note,
    });
    await refreshRequests();
  }

  void toggleSavedReuseIdea(String ideaId) {
    if (!_savedReuseIdeaIds.add(ideaId)) {
      _savedReuseIdeaIds.remove(ideaId);
    }
    notifyListeners();
  }

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
        note: 'Demo points only. No reward has been verified or issued.',
      ),
    );
    notifyListeners();
  }
}
