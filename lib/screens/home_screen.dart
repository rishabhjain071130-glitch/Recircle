import 'package:flutter/material.dart';

import '../app/router.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/recircle_branding.dart';
import 'pickup_booking_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const ReCircleLogo(width: 122),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No new notifications'),
                duration: Duration(seconds: 2),
              ),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => onNavigateToTab(AppTab.profile.index),
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: AppTheme.accentLightGreen,
              child: Text(
                appState.user.name.isEmpty || appState.user.name == 'Your Name'
                    ? 'R'
                    : appState.user.name[0].toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHero(
                onTap: () =>
                    onNavigateToTab(AppTab.scan.index, actionMode: 'gallery'),
              ),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.85,
                children: [
                  _QuickActionTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'Book Pickup',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PickupBookingScreen(appState: appState),
                      ),
                    ),
                  ),
                  _QuickActionTile(
                    icon: Icons.volunteer_activism_outlined,
                    label: 'Sell / Reuse',
                    onTap: () => onNavigateToTab(
                      AppTab.scan.index,
                      actionMode: 'gallery',
                    ),
                  ),
                  _QuickActionTile(
                    icon: Icons.document_scanner_outlined,
                    label: 'Scan Item',
                    onTap: () => onNavigateToTab(
                      AppTab.scan.index,
                      actionMode: 'camera',
                    ),
                  ),
                  _QuickActionTile(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Assistant',
                    onTap: () => onNavigateToTab(AppTab.scan.index),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 190),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3D2E), Color(0xFF1E7F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(right: -26, top: -34, child: _HeroOrbit(size: 140)),
          const Positioned(right: 28, bottom: 20, child: _HeroOrbit(size: 74)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Give Waste\nA New Purpose',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              letterSpacing: -0.45,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Book a pickup, recycle,\nor list for reuse.',
                        style: TextStyle(
                          color: Color(0xFFE3F1E7),
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton.icon(
                        onPressed: onTap,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text(
                          'Get started',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _CircularEconomyMark(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroOrbit extends StatelessWidget {
  const _HeroOrbit({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
        width: 1.5,
      ),
      color: Colors.white.withValues(alpha: 0.035),
    ),
  );
}

class _CircularEconomyMark extends StatelessWidget {
  const _CircularEconomyMark();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 78,
    height: 96,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: const Icon(
            Icons.recycling_rounded,
            color: Color(0xFFB8E986),
            size: 39,
          ),
        ),
        const Positioned(
          right: 0,
          bottom: 1,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF6CC24A),
            child: Icon(Icons.eco_rounded, color: Color(0xFF0B3D2E), size: 20),
          ),
        ),
      ],
    ),
  );
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE7DF)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 21),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
