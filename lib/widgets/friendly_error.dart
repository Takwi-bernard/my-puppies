import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A calm, branded error state for anywhere a Supabase/network call fails.
/// Never show the raw exception to the user — log it if needed, but show
/// this instead.
class FriendlyError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const FriendlyError({
    super.key,
    this.message = "Something went wrong on our end. Please try again in a moment.",
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.orange, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.orange),
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}