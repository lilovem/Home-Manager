import 'package:flutter/material.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/shopping_history_model.dart';

/// מסך פירוט קנייה בודדת מההיסטוריה - מציג את כל המוצרים לפי קטגוריה:
/// מה נקנה, מה לא נמצא והועבר לקנייה הבאה, ומה לא נמצא ונמחק.
class ShoppingHistoryDetailScreen extends StatelessWidget {
  final ShoppingHistoryEntry entry;

  const ShoppingHistoryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    // תמיכה לאחור: רשומות ישנות לא הפרידו בין "הועבר" ל"נמחק" -
    // אם שני השדות החדשים ריקים אבל יש notFoundItemNames ישן,
    // מציגים אותו כקטגוריה אחת כללית של "לא נמצא".
    final hasDetailedBreakdown =
        entry.carriedOverItemNames.isNotEmpty || entry.droppedItemNames.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(DateFormatter.short(entry.date))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: AppStrings.itemsCountLabel,
                  value: entry.totalItems.toString(),
                ),
              ),
              Expanded(
                child: _StatCard(
                  label: AppStrings.purchasedItemsLabel,
                  value: entry.purchasedCount.toString(),
                  color: AppColors.itemPurchased,
                ),
              ),
              Expanded(
                child: _StatCard(
                  label: AppStrings.notFoundItemsLabel,
                  value: entry.notFoundCount.toString(),
                  color: AppColors.itemNotFound,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (entry.purchasedItemNames.isNotEmpty)
            _ItemSection(
              title: AppStrings.purchasedItemsLabel,
              items: entry.purchasedItemNames,
              icon: Icons.check_circle_outline,
              color: AppColors.itemPurchased,
            ),
          if (hasDetailedBreakdown) ...[
            if (entry.carriedOverItemNames.isNotEmpty)
              _ItemSection(
                title: AppStrings.carriedOverSectionTitle,
                items: entry.carriedOverItemNames,
                icon: Icons.arrow_forward,
                color: AppColors.itemNotFound,
              ),
            if (entry.droppedItemNames.isNotEmpty)
              _ItemSection(
                title: AppStrings.droppedSectionTitle,
                items: entry.droppedItemNames,
                icon: Icons.close,
                color: AppColors.textSecondary,
              ),
          ] else if (entry.notFoundItemNames.isNotEmpty)
            _ItemSection(
              title: AppStrings.notFoundItemsLabel,
              items: entry.notFoundItemNames,
              icon: Icons.error_outline,
              color: AppColors.itemNotFound,
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatCard({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading1.copyWith(color: color ?? AppColors.textPrimary),
        ),
        Text(label, style: AppTextStyles.bodySecondary),
      ],
    );
  }
}

class _ItemSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  const _ItemSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${items.length})',
            style: AppTextStyles.heading2.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (name) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

