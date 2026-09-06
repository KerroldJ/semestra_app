import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Shown while auth state is [AuthStatus.unknown] (restoring on launch).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold, width: 2),
              ),
              child: const Text(
                'S',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.goldDeep,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
