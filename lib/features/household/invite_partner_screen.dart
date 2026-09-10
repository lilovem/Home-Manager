import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';

/// מסך הזמנת בן/בת זוג. מציג את קוד ההזמנה (מזהה ה-household)
/// עם אפשרות העתקה, כדי לשתף עם בן/בת הזוג בכל ערוץ (וואטסאפ, הודעה וכו').
class InvitePartnerScreen extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.invitePartner)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.group_add, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                householdName,
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.shareThisCode,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  householdId,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _copyCode(context),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text(AppStrings.copyCode, style: AppTextStyles.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

