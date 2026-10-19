import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class AppMessageView extends StatelessWidget {
  const AppMessageView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.info_outline,
    this.action,
    this.actionLabel,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (action != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: action, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
