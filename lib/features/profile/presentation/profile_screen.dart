import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// Screen presenting user profile details, allowing name/password editing, and handling authentication sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    String currentEmail,
    bool isDark,
  ) {
    final nameController = TextEditingController(text: currentName == 'User' ? '' : currentName);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? authErrorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final authState = ref.watch(authNotifierProvider);
            final user = authState.value;
            final isLoading = authState.isLoading;
            
            final hasPasswordProvider = user?.providerData.any((p) => p.providerId == 'password') ?? false;

            return Dialog(
              backgroundColor: Colors.transparent,
              child: GlassContainer(
                blur: 24,
                opacity: isDark ? 0.08 : 0.15,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? Colors.white10 : Colors.black12,
                padding: const EdgeInsets.all(AppSizes.l),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.l),

                        // ── Display Name ──────────────────────────────────
                        Text(
                          'Display Name',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CustomTextField(
                          controller: nameController,
                          labelText: 'Your Name',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Display name cannot be empty';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.l),

                        // ── Change Password ───────────────────────────────
                        if (hasPasswordProvider) ...[
                          Text(
                            'Change Password',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          CustomTextField(
                            controller: currentPasswordController,
                            labelText: 'Current Password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            validator: (value) {
                              // Only required when a new password is being set
                              if (newPasswordController.text.isNotEmpty &&
                                  (value == null || value.isEmpty)) {
                                return 'Enter your current password to change it';
                              }
                            },
                          ),
                          if (authErrorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 4),
                              child: Text(
                                authErrorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSizes.s),
                          CustomTextField(
                            controller: newPasswordController,
                            labelText: 'New Password',
                            prefixIcon: Icons.lock_reset_rounded,
                            obscureText: true,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length < 6) {
                                return 'New password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSizes.s),
                          CustomTextField(
                            controller: confirmPasswordController,
                            labelText: 'Confirm New Password',
                            prefixIcon: Icons.lock_rounded,
                            obscureText: true,
                            validator: (value) {
                              if (newPasswordController.text.isNotEmpty &&
                                  value != newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          // Forgot Password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                GoRouter.of(context).push('/forgot-password');
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(AppSizes.m),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.security_rounded,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSizes.s),
                                Expanded(
                                  child: Text(
                                    'You are signed in securely via Google. Password changes are managed by your Google account.',
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSizes.m),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: AppSizes.s),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        final newName = nameController.text.trim();
                                        final currentPw = currentPasswordController.text;
                                        final newPw = newPasswordController.text;
                                        bool hasError = false;

                                        // 1. Update Display Name if changed
                                        if (newName != currentName) {
                                          await ref.read(authNotifierProvider.notifier).updateProfileName(
                                                newName,
                                                onSuccess: () {},
                                                onFailure: (err) {
                                                  hasError = true;
                                                  setDialogState(() {
                                                    authErrorMessage = err;
                                                  });
                                                },
                                              );
                                        }

                                        // 2. Reauthenticate + change password if new password entered
                                        if (newPw.isNotEmpty && !hasError) {
                                          setDialogState(() {
                                            authErrorMessage = null;
                                          });
                                          // Reauthenticate with current password first
                                          await ref.read(authNotifierProvider.notifier).reauthenticateAndChangePassword(
                                                currentPassword: currentPw,
                                                newPassword: newPw,
                                                onSuccess: () {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Password updated successfully!'),
                                                        backgroundColor: AppColors.success,
                                                      ),
                                                    );
                                                  }
                                                },
                                                onFailure: (err) {
                                                  hasError = true;
                                                  if (context.mounted) {
                                                    setDialogState(() {
                                                      authErrorMessage = err;
                                                    });
                                                  }
                                                },
                                              );
                                        }

                                        if (context.mounted && !hasError) {
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Profile updated successfully!'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Save', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Load active Firebase user details
    final authState = ref.watch(authStateProvider);
    final user = authState.value ?? ref.read(authRepositoryProvider).currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? 'No active email';

    return GradientBackground(
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSizes.m,
          right: AppSizes.m,
          top: AppSizes.m,
          bottom: 100, // Margin to prevent overlap with bottom navigation bar
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Profile',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSizes.l),

            // Profile info card (Interactive Edit Trigger)
            GestureDetector(
              onTap: () => _showEditProfileDialog(context, ref, displayName, email, isDark),
              child: GlassContainer(
                blur: 20,
                opacity: isDark ? 0.08 : 0.12,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? Colors.white10 : Colors.black12,
                padding: const EdgeInsets.all(AppSizes.l),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.m),
                    Text(
                      displayName,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.l),

            // Menu Items List
            GlassContainer(
              blur: 15,
              opacity: isDark ? 0.06 : 0.1,
              color: isDark ? Colors.black : Colors.white,
              borderColor: isDark ? Colors.white10 : Colors.black12,
              padding: EdgeInsets.zero, // Remove inner padding for dense list tiles
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    _buildProfileTile(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () => context.push('/settings'),
                    ),
                    const Divider(height: 1),
                    _buildProfileTile(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _buildProfileTile(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Log Out',
                      iconColor: AppColors.error,
                      onTap: () async {
                        // Correctly clear remote & local session context
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (isDark ? Colors.white70 : Colors.black87),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: isDark ? Colors.white30 : Colors.black26,
      ),
      onTap: onTap,
    );
  }
}
