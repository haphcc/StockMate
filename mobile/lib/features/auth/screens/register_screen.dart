import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/language_switch_button.dart';
import '../../../core/widgets/stockmate_brand.dart';
import '../../../core/services/google_sign_in_service.dart';
import '../../../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/social_login_buttons.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = true;
  bool _showReferralField = false;

  // Password rules validation
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => _passwordController.text.contains(
    RegExp(r'[!@#\$%\^&\*\(\),\.\?":{}|<>]'),
  );

  int get _passwordStrength {
    if (_passwordController.text.isEmpty) return 0;
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecialChar) score++;
    return score.clamp(1, 4);
  }

  String _getStrengthLabel(dynamic l10n) {
    if (_passwordController.text.isEmpty) return l10n.strengthEmpty;
    switch (_passwordStrength) {
      case 1:
        return l10n.strengthWeak;
      case 2:
        return l10n.strengthMedium;
      case 3:
        return l10n.strengthGood;
      case 4:
        return l10n.strengthStrong;
      default:
        return l10n.strengthEmpty;
    }
  }

  Color get _strengthColor {
    if (_passwordController.text.isEmpty) return AppColors.darkTextMuted;
    switch (_passwordStrength) {
      case 1:
        return AppColors.priceDown;
      case 2:
        return AppColors.priceRef;
      case 3:
      case 4:
        return AppColors.primary;
      default:
        return AppColors.darkTextMuted;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _register() async {
    final l10n = ref.read(l10nProvider);
    if (!_formKey.currentState!.validate() ||
        _passwordController.text != _confirmPasswordController.text) {
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.termsRequired),
          backgroundColor: AppColors.priceDown,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await ref.read(authProvider.notifier).register({
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'password': _passwordController.text,
      });

      if (mounted) {
        context.go('/home/overview');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.priceDown,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _googleSignIn() async {
    try {
      final credentials = await GoogleSignInService().signIn();
      await ref.read(authProvider.notifier).googleLogin(
            idToken: credentials.idToken,
            accessToken: credentials.accessToken,
          );
      if (mounted) {
        context.go('/home/overview');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        if (msg.contains('Đã hủy') || msg.contains('canceled') || msg.contains('cancelled')) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.priceDown,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar with Logo and Language Switch Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/login');
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        const StockMateBrand(iconSize: 28, fontSize: 18),
                      ],
                    ),
                    const LanguageSwitchButton(),
                  ],
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  l10n.registerTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Full Name Field
                _buildFieldLabel(
                  icon: Icons.badge_outlined,
                  label: l10n.fullNameLabel,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  hintText: l10n.fullNameHint,
                  controller: _nameController,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? l10n.fullNameHint : null,
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.darkTextSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Email Field
                _buildFieldLabel(
                  icon: Icons.email_outlined,
                  label: l10n.emailLabel,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  hintText: l10n.emailHint,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value == null ||
                              !RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(value.trim())
                          ? l10n.emailInvalid
                          : null,
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    color: AppColors.darkTextSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Phone Number Field
                _buildFieldLabel(
                  icon: Icons.phone_android_outlined,
                  label: l10n.phoneLabel,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  hintText: l10n.phoneHint,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value == null ||
                              !RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$').hasMatch(
                                value.trim(),
                              )
                          ? l10n.phoneInvalid
                          : null,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.darkTextSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Password Field
                _buildFieldLabel(
                  icon: Icons.lock_outline_rounded,
                  label: l10n.passwordRegisterLabel,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  hintText: l10n.passwordRegisterHint,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (val) => setState(() {}),
                  validator: (value) => value == null || value.length < 8
                      ? l10n.passwordMinLength
                      : null,
                  prefixIcon: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.darkTextSecondary,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.darkTextSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),

                // Password strength meter
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _passwordStrength / 4,
                            backgroundColor: AppColors.darkInput,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _strengthColor,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _getStrengthLabel(l10n),
                        style: TextStyle(
                          color: _strengthColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildCheckRule(l10n.ruleMinLength, _hasMinLength),
                      _buildCheckRule(l10n.ruleUppercase, _hasUppercase),
                      _buildCheckRule(l10n.ruleNumber, _hasNumber),
                      _buildCheckRule(l10n.ruleSpecial, _hasSpecialChar),
                    ],
                  ),
                ],
                const SizedBox(height: 18),

                // 5. Confirm Password Field
                _buildFieldLabel(
                  icon: Icons.check_circle_outline_rounded,
                  label: l10n.confirmPasswordLabel,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  hintText: l10n.confirmPasswordHint,
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  onChanged: (val) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.confirmPasswordHint;
                    }
                    if (value != _passwordController.text) {
                      return l10n.passwordMismatch;
                    }
                    return null;
                  },
                  prefixIcon: const Icon(
                    Icons.lock_clock_outlined,
                    color: AppColors.darkTextSecondary,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.darkTextSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () =>
                          _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Referral Field Toggle
                if (!_showReferralField)
                  GestureDetector(
                    onTap: () => setState(() => _showReferralField = true),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.referralOptional,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _buildFieldLabel(
                    icon: Icons.card_giftcard_rounded,
                    label: l10n.referralOptional,
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    hintText: l10n.referralHint,
                    controller: _referralController,
                    prefixIcon: const Icon(
                      Icons.redeem_rounded,
                      color: AppColors.darkTextSecondary,
                      size: 20,
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Terms Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: _agreeTerms
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _agreeTerms
                                ? AppColors.primary
                                : AppColors.darkTextMuted,
                            width: 1.5,
                          ),
                        ),
                        child: _agreeTerms
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Color(0xFF0B1410),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 12,
                            height: 1.45,
                          ),
                          children: [
                            TextSpan(text: l10n.agreeTermsPrefix),
                            TextSpan(
                              text: l10n.termsOfService,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: l10n.termsAndUnderstand),
                            TextSpan(
                              text: l10n.termsRiskFree,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: l10n.termsPurpose),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // CTA Button
                GradientButton(
                  text: l10n.registerButton,
                  isLoading: isLoading,
                  trailingIcon: const Icon(
                    Icons.trending_up_rounded,
                    size: 20,
                    color: Color(0xFF032617),
                  ),
                  onPressed: _register,
                ),
                const SizedBox(height: 28),

                // Social registration
                SocialAuthSection(
                  dividerText: l10n.orRegisterWith,
                  onGoogleTap: _googleSignIn,
                  onAppleTap: () => _register(),
                ),
                const SizedBox(height: 28),

                // Bottom Login Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.alreadyHaveAccount,
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                        child: Text(
                          l10n.loginNow,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.darkTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckRule(String label, bool isSatisfied) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSatisfied
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: isSatisfied ? AppColors.primary : AppColors.darkTextMuted,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isSatisfied ? Colors.white : AppColors.darkTextMuted,
            fontSize: 12,
            fontWeight: isSatisfied ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
