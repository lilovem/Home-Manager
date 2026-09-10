import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';

/// מסך שמוצג כשלמשתמש עדיין אין household.
/// מאפשר לבחור בין יצירת household חדש לבין הצטרפות לקיים
/// באמצעות קוד הזמנה.
class CreateOrJoinHouseholdScreen extends ConsumerStatefulWidget {
  const CreateOrJoinHouseholdScreen({super.key});

  @override
  ConsumerState<CreateOrJoinHouseholdScreen> createState() =>
      _CreateOrJoinHouseholdScreenState();
}

class _CreateOrJoinHouseholdScreenState
    extends ConsumerState<CreateOrJoinHouseholdScreen> {
  bool _showJoinForm = false;
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(householdRepositoryProvider);
      if (_showJoinForm) {
        await repo.joinHousehold(householdId: _textController.text, uid: uid);
      } else {
        await repo.createHousehold(
          name: _textController.text.trim(),
          creatorUid: uid,
        );
      }
      // בהצלחה - myHouseholdProvider יזהה אוטומטית את השינוי
      // ו-HouseholdGate יעביר למסך הבית.
    } on Failure catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = AppStrings.errorGeneric);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.home_rounded, size: 56, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text(
                    AppStrings.noHouseholdYet,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _textController,
                    decoration: InputDecoration(
                      labelText: _showJoinForm
                          ? AppStrings.inviteCode
                          : AppStrings.householdName,
                    ),
                    validator: (value) => Validators.requiredText(
                      value,
                      fieldName: _showJoinForm
                          ? AppStrings.inviteCode
                          : AppStrings.householdName,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _showJoinForm
                                ? AppStrings.joinButton
                                : AppStrings.createHousehold,
                            style: AppTextStyles.button,
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showJoinForm = !_showJoinForm;
                        _errorMessage = null;
                        _textController.clear();
                      });
                    },
                    child: Text(
                      _showJoinForm
                          ? AppStrings.createNewHousehold
                          : AppStrings.haveInviteCode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

