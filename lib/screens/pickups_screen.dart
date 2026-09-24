import 'package:flutter/material.dart';
import '../models/pickup.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/pickup_card.dart';
import 'pickup_booking_screen.dart';
import 'pickup_tracking_screen.dart';

class PickupsScreen extends StatefulWidget {
  final AppState appState;

  const PickupsScreen({
    super.key,
    required this.appState,
  });

  @override
  State<PickupsScreen> createState() => _PickupsScreenState();
}

class _PickupsScreenState extends State<PickupsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPickups = widget.appState.pickups;
    final activePickups = allPickups.where((p) => p.isActive).toList();
    final completedPickups = allPickups.where((p) => !p.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pickups'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PickupBookingScreen(appState: widget.appState),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Book New'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.subtitleGrey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: 'Active (${activePickups.length})'),
            Tab(text: 'Completed (${completedPickups.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPickupList(activePickups, 'No active pickup requests', 'Book a pickup for your recyclable plastic or e-waste items.'),
          _buildPickupList(completedPickups, 'No completed pickups yet', 'When your items are collected and recycled, they will appear here.'),
        ],
      ),
    );
  }

  Widget _buildPickupList(List<Pickup> pickups, String emptyTitle, String emptySubtitle) {
    if (pickups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.accentLightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 48,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.subtitleGrey,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PickupBookingScreen(appState: widget.appState),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Book New Pickup'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pickups.length,
      itemBuilder: (context, index) {
        final pickup = pickups[index];
        return PickupCard(
          pickup: pickup,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PickupTrackingScreen(
                  pickup: pickup,
                  appState: widget.appState,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
