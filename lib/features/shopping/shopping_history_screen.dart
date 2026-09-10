import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../providers/shopping_provider.dart';

/// מסך היסטוריית קניות - רשימת קניות שהושלמו בעבר, לפי household.
class ShoppingHistoryScreen extends ConsumerWidget {
  final String householdId;

  const ShoppingHistoryScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shoppingHistoryProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.shoppingHistory)),
      body: historyAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => const ErrorView(),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              message: AppStrings.noHistoryYet,
              icon: Icons.history,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                title: Text(DateFormatter.short(entry.date)),
                subtitle: Text(
                  '${entry.totalItems} ${AppStrings.itemsCountLabel} · '
                  '${entry.purchasedCount} ${AppStrings.purchasedItemsLabel} · '
                  '${entry.notFoundCount} ${AppStrings.notFoundItemsLabel}',
                  style: AppTextStyles.bodySecondary,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

