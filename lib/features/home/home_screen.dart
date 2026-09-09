import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// מסך הבית - כרגע placeholder פשוט שמאשר שההתחברות עבדה.
/// בשלבים הבאים (Household, Shopping List) זה יהפוך למסך המרכזי האמיתי.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    final email = authState.value?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('התחברת בהצלחה!', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              '${AppStrings.loggedInAs}: $email',
              style: AppTextStyles.bodySecondary,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text(AppStrings.signOut, style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }
}

