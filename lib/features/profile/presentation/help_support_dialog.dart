import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/glass_container.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// A premium, glassmorphic modal sheet displaying FAQs, a support feedback form,
/// and contact copying actions.
class HelpSupportDialog extends ConsumerStatefulWidget {
  final bool isDark;

  const HelpSupportDialog({super.key, required this.isDark});

  @override
  ConsumerState<HelpSupportDialog> createState() => _HelpSupportDialogState();
}

class _HelpSupportDialogState extends ConsumerState<HelpSupportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  int _activeFaqIndex = -1;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I create a reminder using AI?',
      'answer': 'Tap the "AI Assistant" button on the Home screen or navigate to the AI tab. Simply type or speak your request (e.g. "Remind me to buy groceries tomorrow at 5 PM") and the AI will analyze it to schedule the reminder automatically.',
    },
    {
      'question': 'Will my alarms ring in the background?',
      'answer': 'Yes! The app uses a robust background alarm system that will trigger and play your chosen ringtone even when the app is minimized or your device is locked.',
    },
    {
      'question': 'Can I use the assistant offline?',
      'answer': 'Absolutely! Your reminders and settings are cached locally. Once you are back online, your local changes will automatically sync with the cloud.',
    },
    {
      'question': 'How do I change the theme?',
      'answer': 'Go to Settings (accessible from the Profile screen) and select your preferred Theme Mode (Light, Dark, or System).',
    },
  ];

  Future<void> _submitFeedback(String name, String email, String? uid) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final message = _messageController.text.trim();

    try {
      // Write feedback to Firestore
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'userId': uid ?? 'anonymous',
        'userName': name,
        'userEmail': email,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 4));

      if (mounted) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your feedback has been submitted successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error saving feedback to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _copySupportEmail() {
    Clipboard.setData(const ClipboardData(text: 'caxu2003@gmail.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support email copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value ?? ref.read(authRepositoryProvider).currentUser;
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? 'anonymous@smartlifeassistant.com';
    final uid = user?.uid;

    final primaryColor = AppColors.primary;
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassContainer(
        blur: 28,
        forceBlur: true,
        opacity: widget.isDark ? 0.09 : 0.88,
        color: widget.isDark ? Colors.black : Colors.white,
        borderColor: widget.isDark ? Colors.white10 : Colors.black12,
        padding: const EdgeInsets.all(AppSizes.l),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Help & Support',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.l),

              // FAQ Section Title
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.s),

              // FAQ List
              ...List.generate(_faqs.length, (index) {
                final isExpanded = _activeFaqIndex == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSizes.s),
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isDark ? Colors.white10 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _activeFaqIndex = isExpanded ? -1 : index;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _faqs[index]['question']!,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: textSecondary,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                          child: Text(
                            _faqs[index]['answer']!,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: AppSizes.l),

              // Feedback Form Title
              Text(
                'Submit Feedback / Request Support',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.s),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      minLines: 2,
                      style: TextStyle(color: textPrimary, fontSize: 13),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Describe your issue or provide feedback...',
                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6), fontSize: 13),
                        contentPadding: const EdgeInsets.all(12),
                        filled: true,
                        fillColor: widget.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: widget.isDark ? Colors.white10 : Colors.black12,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.m),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : () => _submitFeedback(displayName, email, uid),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit Request',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.l),

              // Divider
              Divider(color: widget.isDark ? Colors.white10 : Colors.black12),
              const SizedBox(height: AppSizes.s),

              // Contact support block
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppSizes.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support Email',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'caxu2003@gmail.com',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded, color: primaryColor, size: 18),
                      onPressed: _copySupportEmail,
                      tooltip: 'Copy support email',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
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
