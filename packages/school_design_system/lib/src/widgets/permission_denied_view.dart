
import 'package:flutter/material.dart';

class PermissionDeniedView extends StatelessWidget {
  const PermissionDeniedView({
    super.key,
    this.title = 'Access denied',
    this.message = 'You do not have permission to view this page.',
    this.onGoBack,
  });

  final String title;
  final String message;
  final VoidCallback? onGoBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: colors.error),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onGoBack != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onGoBack,
                child: const Text('Go back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
