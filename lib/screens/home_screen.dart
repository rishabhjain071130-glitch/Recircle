import 'package:flutter/material.dart';
import '../models/pickup.dart';
import '../models/recycling_item.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/action_card.dart';
import '../widgets/impact_card.dart';
import '../widgets/section_title.dart';
import 'pickup_booking_screen.dart';
import 'pickup_tracking_screen.dart';
import 'reuse_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppState appState;
  final Function(int index, {String? actionMode}) onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.appState,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final activePickup = appState.activePickup;
    final sampleItem = RecyclingItem.sampleItems.first; // Plastic Bottle

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.accentLightGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.eco,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ReCircle',
              style: TextStyle(
                color: AppTheme.darkText,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Give every item a second chance.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.subtitleGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.recycling,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Sustainability First',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Reuse First.\nRecycle When Needed.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Find a new purpose for unwanted items before sending them for recycling.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onNavigateToTab(1, actionMode: 'camera'),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Scan Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onNavigateToTab(1, actionMode: 'gallery'),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Upload Photo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Quick Actions Section
            const SectionTitle(
              title: 'Quick Actions',
              subtitle: 'Select a task to get started',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ActionCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'Scan Item',
                    subtitle: 'Identify an unwanted item',
                    onTap: () => onNavigateToTab(1, actionMode: 'camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionCard(
                    icon: Icons.upload_file_outlined,
                    title: 'Upload Photo',
                    subtitle: 'Analyze an existing photo',
                    onTap: () => onNavigateToTab(1, actionMode: 'gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ActionCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Book Pickup',
                    subtitle: 'Send recyclable items',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PickupBookingScreen(appState: appState),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionCard(
                    icon: Icons.track_changes_outlined,
                    title: 'Track Pickup',
                    subtitle: 'Check collection status',
                    onTap: () => onNavigateToTab(2), // Pickups tab
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // AI Reuse Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLightGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: AppTheme.primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'ReCircle AI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            'Not sure what to do with an old item?',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.subtitleGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.primaryGreen),
                            SizedBox(width: 8),
                            Text(
                              'Example: Plastic Bottle',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.darkText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Possible reuse ideas:',
                          style: TextStyle(fontSize: 12, color: AppTheme.subtitleGrey),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: sampleItem.reuseIdeas.map((idea) {
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReuseDetailScreen(
                                      idea: idea,
                                      appState: appState,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                                ),
                                child: Text(
                                  '• ${idea.title}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '* Example ideas shown. AI scan analysis works when photo is captured.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.subtitleGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => onNavigateToTab(1), // AI tab
                      child: const Text('Explore Ideas with ReCircle AI'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Current Pickup Section
            const SectionTitle(title: 'Active Pickup'),
            const SizedBox(height: 12),
            if (activePickup != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accentLightGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_shipping,
                                color: AppTheme.primaryGreen,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activePickup.itemName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                Text(
                                  'Pickup #${activePickup.id}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.subtitleGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentLightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            activePickup.status.displayName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    LinearProgressIndicator(
                      value: (activePickup.status.stepIndex + 1) / PickupStatus.values.length,
                      backgroundColor: Colors.grey.shade200,
                      color: AppTheme.primaryGreen,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${activePickup.preferredDate}, ${activePickup.preferredTime}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.subtitleGrey,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PickupTrackingScreen(
                                  pickup: activePickup,
                                  appState: appState,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Track Details →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.inbox_outlined, size: 36, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      'No active pickups',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Schedule a pickup for your recyclable plastics or e-waste.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.subtitleGrey),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PickupBookingScreen(appState: appState),
                          ),
                        );
                      },
                      child: const Text('Book a Pickup'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // Impact Summary
            const SectionTitle(
              title: 'Impact Summary',
              subtitle: 'Your personal sustainability tally',
            ),
            const SizedBox(height: 12),
            ImpactCard(
              stats: appState.impactStats,
              onTap: () => onNavigateToTab(3), // Impact tab
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
