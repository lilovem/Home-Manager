import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../app/config/app_strings.dart';
import '../../../core/errors/failures.dart';
import '../../../providers/bills_provider.dart';
import '../../../providers/household_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../bills/electricity_screen.dart';
import '../../bills/vaad_bayit_screen.dart';
import '../../bills/water_and_tax_screen.dart';
import '../../vehicles/vehicle_calendar_provider.dart';
import '../home_module.dart';

/// תוכן טאב "בית" - בראש: באנר מזג אוויר (לפי מיקום הדפדפן) ולוח
/// מודעות ידני (הודעה אחת, אפשר להוסיף/לערוך/למחוק) - שניהם מוצגים
/// מתחת לבאנר "הפעלת התראות" של המסך הראשי ומעל הריבועים. אחריהם
/// רשת 4 חלונות: קניות, לוח שנה, משימות, רכבים. קניות ולוח שנה
/// זמינים גם כטאבים משלהם בסרגל התחתון - זה כאן בעצם קיצור דרך
/// נוסף שנשאר מהעיצוב המקורי.
class HomeTabContent extends ConsumerWidget {
  final String householdId;
  final List<HomeModule> tiles;
  final ValueChanged<int> onSelectTab;

  const HomeTabContent({
    super.key,
    required this.householdId,
    required this.tiles,
    required this.onSelectTab,
  });

  /// פותח את מסך המודול (אם יש לו screenBuilder זמין) - זה מה שקודם
  /// היה מקובע כ-null עבור אריח הרכבים, בלי קשר לזמינות האמיתית
  /// שמוגדרת ב-home_modules.dart.
  void _openModule(BuildContext context, HomeModule module) {
    if (module.screenBuilder == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: module.screenBuilder!),
    );
  }

  Future<void> _openNoteDialog(
    BuildContext context,
    WidgetRef ref,
    String? currentNote,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _NoteEditDialog(initialText: currentNote ?? ''),
    );
    if (result == null) return;

    try {
      await ref.read(householdRepositoryProvider).updateNote(
            householdId: householdId,
            note: result.trim().isEmpty ? null : result.trim(),
          );
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDeleteNote(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.confirmDeleteNoteTitle),
        content: const Text(AppStrings.confirmDeleteNoteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(householdRepositoryProvider).updateNote(
            householdId: householdId,
            note: null,
          );
    } on Failure catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider);
    final note = household?.note;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      children: [
        const _WeatherBanner(),
        const SizedBox(height: 10),
        _TodayScheduleBanner(householdId: householdId),
        const SizedBox(height: 10),
        _NoteBoard(
          note: note,
          onAdd: () => _openNoteDialog(context, ref, null),
          onEdit: () => _openNoteDialog(context, ref, note),
          onDelete: () => _confirmDeleteNote(context, ref),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.9,
          children: [
            _Tile(
              module: tiles[0],
              color: AppColors.itemPurchased,
              onTap: () => onSelectTab(1),
            ),
            _Tile(
              module: tiles[1],
              color: AppColors.primary,
              onTap: () => onSelectTab(2),
            ),
            _Tile(
              module: tiles[2],
              color: AppColors.itemNewBadge,
              onTap: () => onSelectTab(3),
            ),
            _Tile(
              module: tiles[3],
              color: AppColors.itemNotFound,
              onTap: tiles[3].screenBuilder != null
                  ? () => _openModule(context, tiles[3])
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _BillsSection(householdId: householdId),
      ],
    );
  }
}

/// באנר מזג אוויר קומפקטי לפי מיקום הדפדפן (Open-Meteo, חינמי,
/// בלי מפתח API). אם אין הרשאת מיקום, הדפדפן לא תומך, או שהבקשה
/// נכשלה - הבאנר פשוט לא מוצג בכלל (במקום הודעת שגיאה בולטת על
/// פיצ'ר "נחמד שיש").
class _WeatherBanner extends ConsumerWidget {
  const _WeatherBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider);

    return weatherAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (weather) {
        final info = _weatherCodeInfo(weather.weatherCode);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(info.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${weather.temperatureCelsius.round()}°C · ${info.label}',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeatherCodeInfo {
  final String emoji;
  final String label;
  const _WeatherCodeInfo(this.emoji, this.label);
}

/// ממפה קוד מזג אוויר של WMO (כמו שמחזיר Open-Meteo) לאימוג'י
/// ותיאור קצר בעברית - לא כל הקודים, רק הקבוצות העיקריות.
_WeatherCodeInfo _weatherCodeInfo(int code) {
  if (code == 0) return const _WeatherCodeInfo('☀️', 'בהיר');
  if (code <= 3) return const _WeatherCodeInfo('⛅', 'מעונן חלקית');
  if (code == 45 || code == 48) return const _WeatherCodeInfo('🌫️', 'ערפילי');
  if (code >= 51 && code <= 67) return const _WeatherCodeInfo('🌧️', 'גשום');
  if (code >= 71 && code <= 77) return const _WeatherCodeInfo('❄️', 'שלג');
  if (code >= 80 && code <= 82) return const _WeatherCodeInfo('🌦️', 'ממטרים');
  if (code >= 95) return const _WeatherCodeInfo('⛈️', 'סופת רעמים');
  return const _WeatherCodeInfo('🌡️', 'מזג אוויר');
}

/// באנר "היום בלוח השנה" - מציג בקצרה אם יש היום קנייה מתוכננת,
/// תזכורת תשלום, או תאריך רכב (רישיון/ביטוח) - בלי קשר להודעה
/// הידנית (לוח המודעות) שמוצגת בנפרד מתחתיו, ובלי קשר אם יש בה
/// תוכן או לא. נבנה מאותם מקורות נתונים בדיוק כמו "לוח שנה" הכללי
/// (ר' calendar_tab_content.dart), רק מסונן ליום הנוכחי. לא מוצג
/// בכלל אם אין היום שום דבר - כדי לא לתפוס מקום סתם.
class _TodayScheduleBanner extends ConsumerWidget {
  final String householdId;

  const _TodayScheduleBanner({required this.householdId});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListsProvider(householdId)).value ?? const [];
    final reminders = ref.watch(allScheduledRemindersProvider(householdId)).value ?? const [];
    final vehicleEvents = ref.watch(vehicleDateEventsProvider(householdId));

    var todayShoppingCount = 0;
    for (final list in lists) {
      if (list.date == null || !_isToday(list.date!)) continue;
      final items = ref
              .watch(shoppingItemsProvider((householdId: householdId, listId: list.id)))
              .value ??
          const [];
      if (items.isNotEmpty) todayShoppingCount++;
    }

    final todayReminders =
        reminders.where((b) => b.reminderAt != null && _isToday(b.reminderAt!)).toList();
    final todayVehicleEvents = vehicleEvents.where((e) => _isToday(e.date)).toList();

    if (todayShoppingCount == 0 && todayReminders.isEmpty && todayVehicleEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                AppStrings.homeTodayScheduleTitle,
                style: AppTextStyles.heading2.copyWith(fontSize: 13, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (todayShoppingCount > 0)
            _TodayScheduleLine(
              icon: Icons.shopping_cart,
              color: Colors.blue,
              label: AppStrings.shoppingEventLabel,
            ),
          ...todayReminders.map(
            (b) => _TodayScheduleLine(
              icon: Icons.alarm,
              color: Colors.green,
              label: billCategoryDisplayName(b.category),
            ),
          ),
          ...todayVehicleEvents.map(
            (e) => _TodayScheduleLine(
              icon: Icons.directions_car,
              color: Colors.deepOrange,
              label: '${e.dateLabel} · ${e.vehicleLabel}',
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayScheduleLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _TodayScheduleLine({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
        ],
      ),
    );
  }
}

/// "לוח מודעות" ידני - הודעה אחת שכל בן/בת משפחה יכולים להוסיף,
/// לערוך או למחוק. נשמר על מסמך ה-household ב-Firestore, אז זה
/// מסונכרן בזמן אמת אצל כולם.
class _NoteBoard extends StatelessWidget {
  final String? note;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteBoard({
    required this.note,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasNote = note != null && note!.trim().isNotEmpty;

    if (!hasNote) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onAdd,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
          ),
          child: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.homeNoteEmptyPrompt,
                  style: AppTextStyles.body.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.itemNewBadge.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.campaign_outlined, color: AppColors.itemNewBadge, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(note!, style: AppTextStyles.body),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: AppStrings.homeNoteEditTooltip,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: AppStrings.homeNoteDeleteTooltip,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// חלונית עריכה/הוספה של ההודעה - שדה טקסט פשוט, מחזירה את הטקסט
/// שנבחר (או null אם בוטל).
class _NoteEditDialog extends StatefulWidget {
  final String initialText;

  const _NoteEditDialog({required this.initialText});

  @override
  State<_NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<_NoteEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.homeNoteDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(hintText: AppStrings.homeNoteFieldHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text(AppStrings.homeNoteSaveButton),
        ),
      ],
    );
  }
}

/// כרטיס רחב עם 3 עמודות: ועד בית (פעיל), חשמל ומים+ארנונה
/// (בקרוב - עדיין אין להם מסכים אמיתיים).
class _BillsSection extends StatelessWidget {
  final String householdId;

  const _BillsSection({required this.householdId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.billsSectionTitle, style: AppTextStyles.heading2.copyWith(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _BillColumn(
                  icon: Icons.apartment_outlined,
                  label: AppStrings.vaadBayitTitle,
                  available: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VaadBayitScreen(householdId: householdId),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _BillColumn(
                  icon: Icons.bolt_outlined,
                  label: AppStrings.electricityTitle,
                  available: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ElectricityScreen(householdId: householdId),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _BillColumn(
                  icon: Icons.water_drop_outlined,
                  label: AppStrings.waterAndTaxTitle,
                  available: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WaterAndTaxScreen(householdId: householdId),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool available;
  final VoidCallback? onTap;

  const _BillColumn({
    required this.icon,
    required this.label,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Opacity(
        opacity: available ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(height: 4),
              Text(label, style: AppTextStyles.body.copyWith(fontSize: 11), textAlign: TextAlign.center),
              if (!available)
                Text(AppStrings.comingSoon,
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final HomeModule module;
  final Color color;
  final int? badgeCount;
  final VoidCallback? onTap;

  const _Tile({required this.module, required this.color, this.badgeCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool available = onTap != null;

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: available ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(module.icon, color: color, size: 19),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.title, style: AppTextStyles.heading2.copyWith(fontSize: 13)),
                      const SizedBox(height: 1),
                      if (badgeCount != null)
                        Text('$badgeCount', style: AppTextStyles.heading1.copyWith(fontSize: 20))
                      else if (!available)
                        Text(AppStrings.comingSoon,
                            style: AppTextStyles.bodySecondary.copyWith(fontSize: 11))
                      else
                        Text(module.subtitle,
                            style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
