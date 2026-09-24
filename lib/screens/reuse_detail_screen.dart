import 'package:flutter/material.dart';
import '../models/reuse_idea.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ReuseDetailScreen extends StatefulWidget {
  final ReuseIdea idea;
  final AppState appState;

  const ReuseDetailScreen({
    super.key,
    required this.idea,
    required this.appState,
  });

  @override
  State<ReuseDetailScreen> createState() => _ReuseDetailScreenState();
}

class _ReuseDetailScreenState extends State<ReuseDetailScreen> {
  bool _isReused = false;

  void _handleMarkAsReused() {
    if (_isReused) return;
    setState(() {
      _isReused = true;
    });
    widget.appState.markItemAsReused(widget.idea);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.accentLightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Awesome Work! 🌱',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You marked "${widget.idea.title}" as reused! Your environmental impact and reward points have been updated.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.subtitleGrey,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close sheet
                    Navigator.pop(context); // Return to previous screen
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final idea = widget.idea;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIY Reuse Guide'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentLightGreen.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          idea.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Difficulty: ${idea.difficulty}',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    idea.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    idea.shortDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Estimated time: ${idea.timeRequired}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Materials needed
            const Text(
              'Materials Needed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Column(
                children: idea.materialsNeeded.map((material) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_box_outlined,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            material,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Step-by-Step Instructions
            const Text(
              'Step-by-Step Instructions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 12),

            ...idea.steps.asMap().entries.map((entry) {
              final stepIndex = entry.key + 1;
              final stepText = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentLightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$stepIndex',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          stepText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.darkText,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 28),

            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isReused ? null : _handleMarkAsReused,
                icon: Icon(_isReused ? Icons.check : Icons.eco),
                label: Text(_isReused ? 'Already Marked as Reused' : 'Mark as Reused'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isReused ? Colors.grey : AppTheme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
