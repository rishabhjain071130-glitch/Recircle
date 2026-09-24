import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class RewardsScreen extends StatelessWidget {
  final AppState appState;

  const RewardsScreen({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final stats = appState.impactStats;
    final activities = appState.rewardActivities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rewards'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    Color(0xFF1B6A3E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.stars,
                    color: Colors.amber,
                    size: 44,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reward Points',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.rewardPoints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Illustrative example • Subject to applicable rules',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // How Points Work
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentLightGreen.withOpacity(0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'How Rewards Work',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Reuse an item using DIY guides: +20 points\n'
                    '• Complete a recycling pickup: +50 points\n'
                    '• Redeem eligible eco-vouchers from sustainability partners.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.darkText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Activity History Header
            const Text(
              'Points History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 12),

            if (activities.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.history_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'No reward activity yet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.darkText,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Reuse items or book pickups to start earning points!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.subtitleGrey,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final act = activities[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppTheme.accentLightGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${act.category} • ${act.note}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.subtitleGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${act.points} pts',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
