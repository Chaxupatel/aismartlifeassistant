import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/custom_snackbar.dart';
import 'providers/auth_provider.dart';

/// Upgraded Login Screen allowing users to sign in via Email or Mobile number.
/// Includes premium Google and Apple OAuth placeholder controls and inputs.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailPasswordController.dispose();
    super.dispose();
  }

  void _handleEmailLogin() {
    if (_emailFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      ref.read(authNotifierProvider.notifier).signIn(
        _emailController.text.trim(),
        _emailPasswordController.text,
        onSuccess: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            context.go('/home');
          }
        },
        onFailure: (error) {
          if (mounted) {
            setState(() => _isLoading = false);
            CustomSnackBar.showError(context, error);
          }
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GradientBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.l),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Branding Header
              Text(
                AppStrings.loginTitle,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.s),
              Text(
                AppStrings.loginSubtitle,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xl),

              // Form & Tabs Container
              GlassContainer(
                blur: 24,
                opacity: isDark ? 0.08 : 0.15,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? const Color(0x22FFFFFF) : const Color(0x55FFFFFF),
                padding: const EdgeInsets.all(AppSizes.l),
                child: Column(
                  children: [
                    // Email Form
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
                          const SizedBox(height: AppSizes.m),
                          CustomTextField(
                            controller: _emailPasswordController,
                            labelText: 'Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.s),

                    // Forgot password trigger link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.s),

                    // Sign In Button
                    PrimaryButton(
                      label: 'Sign In',
                      isLoading: _isLoading,
                      onPressed: _handleEmailLogin,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.l),

              // Separator
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.m),
                    child: Text(
                      'Or connect with',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.black12)),
                ],
              ),
              const SizedBox(height: AppSizes.m),

              // Social Sign-In buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google button
                  _buildSocialButton(
                    isDark,
                    isLoading: _isGoogleLoading,
                    icon: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    onTap: _isGoogleLoading
                        ? null
                        : () {
                            setState(() => _isGoogleLoading = true);
                            ref.read(authNotifierProvider.notifier).signInWithGoogle(
                              onSuccess: () {
                                if (mounted) {
                                  setState(() => _isGoogleLoading = false);
                                  context.go('/home');
                                }
                              },
                              onFailure: (error) {
                                if (mounted) {
                                  setState(() => _isGoogleLoading = false);
                                  CustomSnackBar.showError(context, error);
                                }
                              },
                              onCancel: () {
                                if (mounted) {
                                  setState(() => _isGoogleLoading = false);
                                }
                              },
                            );
                          },
                  ),
                  const SizedBox(width: AppSizes.m),
                  // Apple button
                  _buildSocialButton(
                    isDark,
                    isLoading: _isAppleLoading,
                    icon: Icon(
                      Icons.apple_rounded,
                      size: 26,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onTap: _isAppleLoading || _isGoogleLoading
                        ? null
                        : () async {
                            setState(() => _isAppleLoading = true);
                            await ref.read(authNotifierProvider.notifier).signInWithApple(
                              onSuccess: () {
                                if (mounted) {
                                  context.go('/home');
                                }
                              },
                              onFailure: (error) {
                                if (mounted) {
                                  setState(() => _isAppleLoading = false);
                                  CustomSnackBar.showError(context, error);
                                }
                              },
                              onCancel: () {
                                if (mounted) {
                                  setState(() => _isAppleLoading = false);
                                }
                              },
                            );
                          },
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.l),

              // Sign Up Route trigger
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSocialButton(
    bool isDark, {
    required Widget icon,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        width: 60,
        height: 60,
        borderRadius: 30, // Perfect circular capsule
        blur: 15,
        opacity: isDark ? 0.08 : 0.12,
        color: isDark ? Colors.black : Colors.white,
        borderColor: isDark ? Colors.white10 : Colors.black12,
        padding: EdgeInsets.zero,
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
              : icon,
        ),
      ),
    );
  }
}
