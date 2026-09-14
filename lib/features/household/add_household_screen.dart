import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/app_colors.dart';
import '../../app/config/app_strings.dart';
import '../../app/config/app_text_styles.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/household_provider.dart';

/// מסך הוספת household **נוסף** - בשונה מ-CreateOrJoinHouseholdScreen,
/// זה נפתח כמסך רגיל (push, עם כפתור חזרה) כשלמשתמש **כבר** יש
/// לפחות household אחד. בהצלחה, ה-household החדש נבחר אוטומטית
/// כ"פעיל" (selectedHouseholdIdProvider) והמסך נסגר.
class AddHouseholdScreen extends ConsumerStatefulWidget {
  const AddHouseholdScreen({super.key});

  @override
  ConsumerState<AddHouseholdScreen> createState() => _AddHouseholdScreenState();
}

class _AddHouseholdScreenState extends ConsumerState<AddHouseholdScreen> {
  bool _showJoinForm = true;
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

    final authUser = ref.read(authStateChangesProvider).value;
    final uid = authUser?.uid;
    if (uid == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(householdRepositoryProvider);
      String newHouseholdId;

      if (_showJoinForm) {
        newHouseholdId = _textController.text.trim();
        await repo.joinHousehold(
          householdId: newHouseholdId,
          uid: uid,
          email: authUser?.email ?? '',
        );
      } else {
        final household = await repo.createHousehold(
          name: _textController.text.trim(),
          creatorUid: uid,
          creatorEmail: authUser?.email ?? '',
        );
        newHouseholdId = household.id;
      }

      // בוחרים אוטומטית את ה-household החדש כ"פעיל", וסוגרים את המסך.
      ref.read(selectedHouseholdIdProvider.notifier).state = newHouseholdId;
      if (mounted) Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text(AppStrings.addAnotherHousehold)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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

