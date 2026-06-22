import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/gradient_background.dart';
import 'providers/auth_provider.dart';

/// Upgraded Forgot Password screen to request account recovery via Email or SMS OTP.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleEmailReset() {
    if (_emailFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      ref.read(authNotifierProvider.notifier).resetPassword(
        _emailController.text.trim(),
        onSuccess: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showSuccessDialog(
              title: 'Reset Link Sent',
              message: 'We have sent password reset instructions to ${_emailController.text}.',
            );
          }
        },
        onFailure: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: AppColors.error),
            );
          }
        },
      );
    }
  }

  void _handlePhoneReset() {
    if (_phoneFormKey.currentState!.validate()) {
      _showSuccessDialog(
        title: 'Passwordless Account info',
        message: 'Phone number logins are passwordless in Firebase. You do not need to reset your password. Simply sign in using the Mobile tab on the login screen.',
      );
    }
  }

  void _showSuccessDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? Colors.black87 : Colors.white,
          title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          content: Text(message, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/login');
              },
              child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reset Password'),
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Branding Header
              Text(
                AppStrings.forgotPasswordTitle,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.s),
              Text(
                AppStrings.forgotPasswordSubtitle,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xxl),

              // Form Glass Container
              GlassContainer(
                blur: 24,
                opacity: isDark ? 0.08 : 0.15,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? const Color(0x22FFFFFF) : const Color(0x55FFFFFF),
                padding: const EdgeInsets.all(AppSizes.l),
                child: Column(
                  children: [
                    // iOS 26 Tab Bar Capsule
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: isDark ? Colors.black : Colors.white,
                        unselectedLabelColor: isDark ? Colors.white70 : Colors.black87,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: isDark ? Colors.white : AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        tabs: const [
                          Tab(text: 'Email'),
                          Tab(text: 'Mobile'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.l),

                    // Dynamic layout switching to prevent static height overflows
                    IndexedStack(
                      index: _tabController.index,
                      children: [
                        // Email recovery input form
                        Form(
                          key: _emailFormKey,
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _emailController,
                                labelText: 'Email Address',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        // Mobile number recovery input form
                        Form(
                          key: _phoneFormKey,
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _phoneController,
                                labelText: 'Mobile Number',
                                prefixIcon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value)) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.m),

                    // Submit Action Button
                    PrimaryButton(
                      label: 'Send Recovery Details',
                      isLoading: _isLoading,
                      onPressed: () {
                        if (_tabController.index == 0) {
                          _handleEmailReset();
                        } else {
                          _handlePhoneReset();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
