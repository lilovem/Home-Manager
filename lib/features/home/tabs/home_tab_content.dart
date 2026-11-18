import 'dart:async';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_colors.dart';
import '../../../app/config/app_text_styles.dart';
import '../../../app/config/app_strings.dart';
import '../../../core/errors/failures.dart';
import '../../../models/bill_payment_model.dart';
import '../../../providers/bills_provider.dart';
import '../../../providers/household_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../bills/electricity_screen.dart';
import '../../bills/vaad_bayit_screen.dart';
import '../../bills/water_and_tax_screen.dart';
import '../../vehicles/vehicle_calendar_provider.dart';
import '../home_module.dart';

/// תוכן טאב "בית" - בראש: באנר מזג אוויר (לפי מיקום הדפדפן) - חזר
/// למקומו המקורי כאן אחרי ניסיון להעביר אותו ל-AppBar (לא נראה
/// טוב שם). "לוח המודעות" הרץ (AnnouncementsTicker, מחלקה ציבורית
/// בהמשך הקובץ) נשאר חלק מהחלק הקבוע של המסך הראשי
/// (main_shell_screen.dart), מיד מתחת ללוגו. אחרי באנר מזג האוויר:
/// רשת 4 חלונות (קניות, לוח שנה, משימות, רכבים), ואז מקטע החשבונות.
/// קניות ולוח שנה זמינים גם כטאבים משלהם בסרגל התחתון - זה כאן
/// בעצם קיצור דרך נוסף שנשאר מהעיצוב המקורי.
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

  List<Widget> _tileWidgets(BuildContext context) => [
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
          titleOverride: 'פתקים',
          subtitleOverride: 'כתיבה ושיתוף פתקים',
          onTap: () => onSelectTab(3),
        ),
        _Tile(
          module: tiles[3],
          color: AppColors.itemNotFound,
          onTap: tiles[3].screenBuilder != null
              ? () => _openModule(context, tiles[3])
              : null,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidgets = _tileWidgets(context);

        // מסך נמוך מאוד - גלילה רגילה עם אריחים בגובה קבוע.
        if (constraints.maxHeight < 330) {
          return Container(
            color: AppColors.primaryLight,
            child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const _WeatherBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Column(
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 7,
                      crossAxisSpacing: 7,
                      childAspectRatio: 2.2,
                      children: tileWidgets,
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 84,
                      child: _BillsRow(householdId: householdId),
                    ),
                  ],
                ),
              ),
            ],
          ),
          );
        }

        // שלוש שורות אריחים באותו גודל בדיוק: קניות+לוח שנה, פתקים+רכבים,
        // וועד בית+חשמל+מים/ארנונה. הגובה פרופורציונלי למסך אבל מוגבל,
        // כך שהאריחים לא נהיים ענקיים; הרווח הפנוי מתחלק ביניהם.
        // כל האזור (כולל באנר מזג האוויר) על רקע כחול בהיר אחד, עד סרגל
        // הניווט; האריחים נשארים לבנים מעליו.
        return Container(
          color: AppColors.primaryLight,
          child: Column(
          children: [
            const _WeatherBanner(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, inner) {
                  const gap = 8.0;
                  final rowH = ((inner.maxHeight - 28 - 2 * gap) / 3).clamp(76.0, 100.0).toDouble();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          height: rowH,
                          child: Row(
                            children: [
                              Expanded(child: tileWidgets[0]),
                              const SizedBox(width: gap),
                              Expanded(child: tileWidgets[1]),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: rowH,
                          child: Row(
                            children: [
                              Expanded(child: tileWidgets[2]),
                              const SizedBox(width: gap),
                              Expanded(child: tileWidgets[3]),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: rowH,
                          child: _BillsRow(householdId: householdId),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          ),
        );
      },
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

    Widget bar(Widget child, {VoidCallback? onTap}) => InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(color: AppColors.primaryLight),
            child: child,
          ),
        );

    return weatherAsync.when(
      loading: () => bar(Text(
        'טוען מזג אוויר...',
        style: AppTextStyles.bodySecondary,
      )),
      error: (_, __) => bar(
        Text(
          'מזג האוויר לא זמין - לחצו לניסיון חוזר (נדרש אישור מיקום בדפדפן)',
          style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
        ),
        onTap: () => ref.invalidate(currentWeatherProvider),
      ),
      data: (weather) {
        final info = weatherCodeInfo(weather.weatherCode);
        const dayNames = ['שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת', 'ראשון'];
        final today = weather.daily.isNotEmpty ? weather.daily.first : null;

        final lineColor = AppColors.primary.withValues(alpha: 0.28);

        Widget boxed(Widget cell, double width) => Container(
              width: width,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: lineColor, width: 1)),
              ),
              child: cell,
            );

        final todayCell = _ForecastCell(
          title: 'היום',
          emoji: info.emoji,
          high: today == null
              ? '${weather.temperatureCelsius.round()}°'
              : '${today.maxCelsius.round()}°',
          low: today == null ? '' : '${today.minCelsius.round()}°',
        );
        final futureDays = weather.daily.skip(1).toList();

        return Container(
          width: double.infinity,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            border: Border(bottom: BorderSide(color: lineColor, width: 1)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // בדיוק 4 תאים בשורה: היום + 3 ימים, כולם נראים במלואם.
              // אפשר להחליק הצידה כדי לראות עוד ימים.
              final cellW = constraints.maxWidth / 4;
              // מימין לשמאל: "היום" קבוע מימין, והשאר גוללים לצדדים.
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  children: [
                    boxed(todayCell, cellW),
                    Expanded(
                      child: _ForecastScroller(
                        cellW: cellW,
                        children: [
                          for (final d in futureDays)
                            boxed(
                              _ForecastCell(
                                title: dayNames[d.date.weekday - 1],
                                emoji: weatherCodeInfo(d.weatherCode).emoji,
                                high: '${d.maxCelsius.round()}°',
                                low: '${d.minCelsius.round()}°',
                              ),
                              cellW,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// רשימת הימים הגוללת. כל עוד היא בתחילתה, מוצג חץ קטן וחצי שקוף בקצה
/// השמאלי שרומז שאפשר להחליק לראות עוד ימים; הוא נעלם אחרי שמחליקים
/// וחוזר כשחוזרים להתחלה.
class _ForecastScroller extends StatefulWidget {
  final double cellW;
  final List<Widget> children;

  const _ForecastScroller({required this.cellW, required this.children});

  @override
  State<_ForecastScroller> createState() => _ForecastScrollerState();
}

class _ForecastScrollerState extends State<_ForecastScroller> {
  final ScrollController _controller = ScrollController();
  bool _atStart = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final atStart = !_controller.hasClients || _controller.offset <= 4;
    if (atStart != _atStart) setState(() => _atStart = atStart);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: ListView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemExtent: widget.cellW,
            children: widget.children,
          ),
        ),
        Positioned(
          left: 2,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _atStart && widget.children.length > 3 ? 0.7 : 0,
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  // ltr כדי שהחץ יצביע שמאלה (לכיוון שאליו מחליקים).
                  child: const Directionality(
                    textDirection: TextDirection.ltr,
                    child: Icon(Icons.chevron_left, size: 20, color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// תא אחד בשורת התחזית - כל התאים באותו רוחב.
class _ForecastCell extends StatelessWidget {
  final String title;
  final String emoji;
  final String high;
  final String low;

  const _ForecastCell({
    required this.title,
    required this.emoji,
    required this.high,
    required this.low,
  });

  @override
  Widget build(BuildContext context) {
    // הגבוהה (מודגשת) מימין והנמוכה (אפורה) משמאלה, באותה שורה -
    // כך התא נשאר נמוך ולא גולש מעבר לקו התחתון.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(emoji, style: const TextStyle(fontSize: 22)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(high,
                      maxLines: 1,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
                  if (low.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(low,
                        maxLines: 1,
                        style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// מידע על קוד מזג אוויר - אימוג'י ותיאור קצר, בשימוש ע"י _WeatherBanner.
class WeatherCodeInfo {
  final String emoji;
  final String label;
  const WeatherCodeInfo(this.emoji, this.label);
}

/// ממפה קוד מזג אוויר של WMO (כמו שמחזיר Open-Meteo) לאימוג'י
/// ותיאור קצר בעברית - לא כל הקודים, רק הקבוצות העיקריות.
WeatherCodeInfo weatherCodeInfo(int code) {
  if (code == 0) return const WeatherCodeInfo('☀️', 'בהיר');
  if (code <= 3) return const WeatherCodeInfo('⛅', 'מעונן חלקית');
  if (code == 45 || code == 48) return const WeatherCodeInfo('🌫️', 'ערפילי');
  if (code >= 51 && code <= 67) return const WeatherCodeInfo('🌧️', 'גשום');
  if (code >= 71 && code <= 77) return const WeatherCodeInfo('❄️', 'שלג');
  if (code >= 80 && code <= 82) return const WeatherCodeInfo('🌦️', 'ממטרים');
  if (code >= 95) return const WeatherCodeInfo('⛈️', 'סופת רעמים');
  return const WeatherCodeInfo('🌡️', 'מזג אוויר');
}

/// "מודעות" - שורה אחת רצה ברוחב המסך, נכנסת מימין וממשיכה לנוע
/// שמאלה ברצף (חבילת marquee - בלי הפסקה, לא עוצרת ומחכה, וממשיכה
/// ללולאה מהצד השני אוטומטית). מציגה ברצף אחד גם את מה שקיים היום
/// בלוח השנה (קנייה מתוכננת, תזכורת תשלום, תאריך רכב - אותם מקורות
/// בדיוק כמו "לוח שנה" הכללי), מנוסחים עם "...היום" בסוף, וגם כמה
/// הודעות ידניות (רשימה ממוספרת) - כפתור ה-"+" בצד תמיד זמין
/// לפתיחת עורך ההודעות הידניות, לגמרי בלי קשר אם יש משהו בלוח
/// השנה היום או לא. כל הודעה (מכל מקור) מופיעה פעם אחת בלבד, גם
/// אם יש כמה אירועים זהים באותו יום. אם אין שום דבר להציג - מוצג
/// טקסט סטטי "הוספת הודעה" במקום שורה ריקה רצה. ממוקם עכשיו מיד
/// מתחת ללוגו (ר. main_shell_screen.dart), ולכן הקלאס ציבורי.
class AnnouncementsTicker extends ConsumerWidget {
  final String householdId;

  const AnnouncementsTicker({super.key, required this.householdId});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// מוסיף הודעה לרשימה רק אם אין בה כבר הודעה זהה - כך לא יוצג
  /// אותו טקסט פעמיים (למשל שני תזכורות תשלום מאותה קטגוריה).
  void _addUnique(List<String> messages, String text) {
    if (!messages.contains(text)) messages.add(text);
  }

  String _withTodaySuffix(String label) => '$label ${AppStrings.homeTodaySuffix}';

  Future<void> _openNotesDialog(
    BuildContext context,
    WidgetRef ref,
    List<String> currentNotes,
  ) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => _NotesEditDialog(initialNotes: currentNotes),
    );
    if (result == null) return;

    try {
      await ref.read(householdRepositoryProvider).updateNotes(
            householdId: householdId,
            notes: result,
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
    final notes = household?.notes ?? const <String>[];

    final lists = ref.watch(shoppingListsProvider(householdId)).value ?? const [];
    final reminders = ref.watch(allScheduledRemindersProvider(householdId)).value ?? const [];
    final vehicleEvents = ref.watch(vehicleDateEventsProvider(householdId));

    final messages = <String>[];
    for (final noteText in notes) {
      final trimmed = noteText.trim();
      if (trimmed.isNotEmpty) _addUnique(messages, trimmed);
    }

    var todayShoppingCount = 0;
    for (final list in lists) {
      if (list.date == null || !_isToday(list.date!)) continue;
      final items = ref
              .watch(shoppingItemsProvider((householdId: householdId, listId: list.id)))
              .value ??
          const [];
      if (items.isNotEmpty) todayShoppingCount++;
    }
    if (todayShoppingCount > 0) {
      _addUnique(messages, _withTodaySuffix(AppStrings.shoppingEventLabel));
    }

    for (final reminder in reminders) {
      if (reminder.reminderAt != null && _isToday(reminder.reminderAt!)) {
        _addUnique(messages, _withTodaySuffix(billCategoryDisplayName(reminder.category)));
      }
    }
    for (final event in vehicleEvents) {
      if (_isToday(event.date)) {
        _addUnique(
          messages,
          _withTodaySuffix('${event.dateLabel} · ${event.vehicleLabel}'),
        );
      }
    }

    final hasMessages = messages.isNotEmpty;
    final combinedText = messages.join('     •     ');

    return Container(
      height: 44,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.itemNewBadge.withValues(alpha: 0.18),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 24),
            tooltip: AppStrings.homeNoteEmptyPrompt,
            onPressed: () => _openNotesDialog(context, ref, notes),
          ),
          Expanded(
            child: hasMessages
                ? _ScrollingTickerText(text: combinedText)
                : Text(
                    AppStrings.homeNoteEmptyPrompt,
                    style: AppTextStyles.bodySecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}

/// שורת הטיקר הרץ בפועל - מימוש עצמי (בלי חבילת marquee חיצונית)
/// כדי לתמוך גם בגרירה ידנית, לפי בקשה מפורשת: אפשר לגרור את
/// הטקסט אחורה/קדימה באצבע כדי לראות הודעה מסוימת, וברגע שמרפים
/// את האצבע - הגלילה האוטומטית פשוט ממשיכה מאותה נקודה בדיוק, בלי
/// לקפוץ בחזרה להתחלה. מבוסס על SingleChildScrollView רגיל (שכבר
/// תומך בגרירה "בחינם") עם טיימר שמזיז את הגלילה לאט-לאט, ועם
/// Listener (לא GestureDetector) כדי לתפוס את אירועי האצבע הגולמיים
/// בלי "להתחרות" על המחווה מול הגלילה הפנימית. הטקסט מוכפל פעמיים
/// ברצף כדי שהלולאה תהיה חלקה: כשמגיעים לאמצע, חוזרים ל-0 בלי
/// שיהיה הבדל ויזואלי (כי שני ההעתקים זהים).
class _ScrollingTickerText extends StatefulWidget {
  final String text;

  const _ScrollingTickerText({required this.text});

  @override
  State<_ScrollingTickerText> createState() => _ScrollingTickerTextState();
}

class _ScrollingTickerTextState extends State<_ScrollingTickerText> {
  static const _gap = '          •          ';
  static const _pixelsPerTick = 1.1;
  static const _tickInterval = Duration(milliseconds: 30);

  final ScrollController _controller = ScrollController();
  Timer? _timer;
  bool _paused = false;
  double _singleWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
  }

  @override
  void didUpdateWidget(covariant _ScrollingTickerText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndStart());
    }
  }

  void _measureAndStart() {
    final painter = TextPainter(
      text: TextSpan(text: '${widget.text}$_gap', style: AppTextStyles.body),
      textDirection: TextDirection.rtl,
    )..layout();
    _singleWidth = painter.width;
    if (_controller.hasClients) _controller.jumpTo(0);
    _timer?.cancel();
    _timer = Timer.periodic(_tickInterval, (_) => _tick());
  }

  void _tick() {
    if (_paused || !_controller.hasClients || _singleWidth <= 0) return;
    final next = (_controller.offset + _pixelsPerTick) % _singleWidth;
    _controller.jumpTo(next);
  }

  void _stopMomentum() {
    // jumpTo לאותו מיקום מבטל כל אנימציית גלילה ("תנופה") שעדיין
    // רצה, כדי שהטיימר האוטומטי לא "יתחרה" איתה אחרי שמרפים אצבע.
    if (_controller.hasClients) _controller.jumpTo(_controller.offset);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doubled = '${widget.text}$_gap${widget.text}$_gap';
    return Listener(
      onPointerDown: (_) => _paused = true,
      onPointerUp: (_) {
        _stopMomentum();
        _paused = false;
      },
      onPointerCancel: (_) {
        _stopMomentum();
        _paused = false;
      },
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Text(
          doubled,
          style: AppTextStyles.body,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}

/// חלונית עריכה של רשימת ההודעות הידניות - רשימה ממוספרת (1. 2.
/// 3. וכו'), כל שורה היא הודעה נפרדת. אפשר להוסיף שורה ("+ הוספת
/// שורה") או למחוק שורה בודדת (ה-X בסוף השורה). רק טקסט לא-ריק
/// נשמר בפועל; שורות ריקות מסוננות אוטומטית בשמירה. מחזירה את
/// הרשימה הסופית, או null אם בוטל.
class _NotesEditDialog extends StatefulWidget {
  final List<String> initialNotes;

  const _NotesEditDialog({required this.initialNotes});

  @override
  State<_NotesEditDialog> createState() => _NotesEditDialogState();
}

class _NotesEditDialogState extends State<_NotesEditDialog> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.initialNotes.isEmpty
        ? [TextEditingController()]
        : widget.initialNotes.map((note) => TextEditingController(text: note)).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeRow(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
      if (_controllers.isEmpty) _controllers.add(TextEditingController());
    });
  }

  void _save() {
    final notes = _controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    Navigator.of(context).pop(notes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.homeNoteDialogTitle),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _controllers.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text('${i + 1}.', style: AppTextStyles.body),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _controllers[i],
                          autofocus: i == 0,
                          decoration: const InputDecoration(
                            hintText: AppStrings.homeNoteFieldHint,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                        tooltip: AppStrings.homeNoteDeleteTooltip,
                        onPressed: () => _removeRow(i),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(AppStrings.homeNoteAddLineButton),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: _save,
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

  /// כשהוא true - הכרטיס ממלא את כל הגובה שנשאר (עד סרגל הניווט
  /// התחתון) והעמודות בו גדולות יותר, במקום להיות "דחוס" בגובה מינימלי.
  final bool expand;

  const _BillsSection({required this.householdId, this.expand = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _BillColumn(
                  large: expand,
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
                  large: expand,
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
                  large: expand,
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
  final bool large;
  final VoidCallback? onTap;

  const _BillColumn({
    this.large = false,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                  textAlign: TextAlign.center),
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

/// אריח אחיד: אייקון למעלה, כותרת, ותת-כותרת קטנה (אופציונלית).
class _MiniTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MiniTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = onTap != null;
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: available ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading2.copyWith(fontSize: 13),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty)
                            Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: AppTextStyles.bodySecondary
                                  .copyWith(fontSize: 10, height: 1.2),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// שורת החשבונות: שלושה אריחים באותו עיצוב וגודל של האריחים שמעליהם.
class _BillsRow extends StatelessWidget {
  final String householdId;
  const _BillsRow({required this.householdId});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    return Row(
      children: [
        Expanded(
          child: _MiniTile(
            icon: Icons.apartment_outlined,
            color: AppColors.primary,
            title: AppStrings.vaadBayitTitle,
            onTap: () => open(VaadBayitScreen(householdId: householdId)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniTile(
            icon: Icons.bolt_outlined,
            color: AppColors.primary,
            title: AppStrings.electricityTitle,
            onTap: () => open(ElectricityScreen(householdId: householdId)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniTile(
            icon: Icons.water_drop_outlined,
            color: AppColors.primary,
            title: AppStrings.waterAndTaxTitle,
            onTap: () => open(WaterAndTaxScreen(householdId: householdId)),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final HomeModule module;
  final Color color;
  final int? badgeCount;
  final VoidCallback? onTap;
  final String? titleOverride;
  final String? subtitleOverride;

  const _Tile({
    required this.module,
    required this.color,
    this.badgeCount,
    this.onTap,
    this.titleOverride,
    this.subtitleOverride,
  });

  @override
  Widget build(BuildContext context) {
    return _MiniTile(
      icon: module.icon,
      color: color,
      title: titleOverride ?? module.title,
      subtitle: onTap == null
          ? AppStrings.comingSoon
          : (subtitleOverride ?? module.subtitle),
      onTap: onTap,
    );
  }
}

