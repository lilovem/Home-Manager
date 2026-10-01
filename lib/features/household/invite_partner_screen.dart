import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_config.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../providers/share_provider.dart';

/// מסך הזמנת בן/בת זוג. מציג את קוד ההזמנה (מזהה ה-household)
/// עם אפשרות העתקה, ושיתוף ישיר בוואטסאפ/מייל עם הודעה מוכנה
/// שכוללת גם את הקישור הקבוע לאפליקציה וגם את הקוד.
///
/// עיצוב מחודש (יותר מודרני, תואם לשאר האפליקציה): אייקון בעיגול
/// גרדיאנט (כמו בלוגו ובכרטיסיית הבית), כרטיס קוד עם מסגרת מקווקוות
/// וצל רך, כפתור העתקה מלא-רוחב, וכפתורי שיתוף בעיצוב "פיל" עם
/// עיגול צבעוני לכל אייקון במקום כפתורים שטוחים.
class InvitePartnerScreen extends ConsumerWidget {
  final String householdId;
  final String householdName;

  const InvitePartnerScreen({
    super.key,
    required this.householdId,
    required this.householdName,
  });

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: householdId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.codeCopied)),
    );
  }

  String get _inviteMessage =>
      'הצטרפ/י אליי ב-${AppStrings.appName}! 🏠\n'
      'פתח/י את הקישור, הירשמ/י, ואז לחצ/י על "יש לי קוד הזמנה" עם הקוד:\n'
      '$householdId\n\n'
      '${AppConfig.publicUrl}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text(AppStrings.invitePartner)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Text(
                householdName,
                style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                AppStrings.shareThisCode,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryLight, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: SelectableText(
                  householdId,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 18,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _copyCode(context),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(AppStrings.copyCode, style: AppTextStyles.button),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _ShareOptionButton(
                      icon: Icons.chat_bubble_rounded,
                      iconColor: const Color(0xFF25D366),
                      label: AppStrings.shareViaWhatsApp,
                      onTap: () => ref.read(shareServiceProvider).shareViaWhatsApp(_inviteMessage),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ShareOptionButton(
                      icon: Icons.email_rounded,
                      iconColor: AppColors.primary,
                      label: AppStrings.shareViaEmail,
                      onTap: () => ref.read(shareServiceProvider).shareViaEmail(
                            subject: AppStrings.inviteMessageTitle,
                            body: _inviteMessage,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// כפתור שיתוף בעיצוב "פיל" - עיגול צבעוני עם האייקון מעל הטקסט,
/// בתוך כרטיס עם מסגרת רכה. יותר מודרני מ-OutlinedButton.icon שטוח.
class _ShareOptionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ShareOptionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
