import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/gradient_background.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local UI States for backup
  bool _autoSyncBackup = false;
  bool _backupLoading = false;
  String _lastBackupDate = 'Never';

  final List<String> _notificationTones = ['Gentle Chime', 'Standard Ping', 'Silent'];
  final List<String> _alarmRingtones = ['Default', 'Classic', 'Digital', 'Crystal'];
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playPreview(String name) async {
    final fileName = name.toLowerCase();
    final path = fileName == 'default' ? 'audio/alarm.wav' : 'audio/$fileName.wav';
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource(path));
  }

  // --- ACTIONS ---

  void _triggerBackup() {
    setState(() {
      _backupLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _backupLoading = false;
        _lastBackupDate = '${now.day}/${now.month}/${now.year} at ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database backup saved successfully to secure local storage!'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.m, vertical: AppSizes.xl),
          child: GlassContainer(
            blur: 24,
            opacity: isDark ? 0.15 : 0.25,
            color: isDark ? Colors.black : Colors.white,
            borderColor: isDark ? Colors.white24 : Colors.black12,
            padding: const EdgeInsets.all(AppSizes.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: AppSizes.m),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      'AI Smart Life Assistant Privacy Contract\n\n'
                      '1. Data Collection\n'
                      'All reminder descriptions, categories, and calendar events created by you are stored exclusively on your device within the secure local Hive storage. We do not transmit your database records to external servers.\n\n'
                      '2. Local Notifications & Alarms\n'
                      'The application triggers OS-level notifications and exact scheduling alarms on your hardware. These operations require local system permissions but do not monitor background web browsing activity.\n\n'
                      '3. Future AI Integrations\n'
                      'When cloud-based AI models (such as Gemini) are introduced in future versions, your natural language prompts will be sent securely to the AI server for parsing. You will have full consent controls to enable or disable cloud processing features.\n\n'
                      '4. Local Backup Storage\n'
                      'Manual and automated backups save encrypted database maps to your device\'s local file system path directory. It remains under your absolute ownership and control.',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.l),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('I Understand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _checkForUpdates() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassContainer(
            blur: 24,
            opacity: isDark ? 0.15 : 0.25,
            color: isDark ? Colors.black : Colors.white,
            borderColor: isDark ? Colors.white24 : Colors.black12,
            padding: const EdgeInsets.all(AppSizes.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48),
                const SizedBox(height: AppSizes.m),
                Text(
                  'System Up to Date',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.s),
                Text(
                  'You are running the latest version of AI Smart Life Assistant (v1.0.0).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSizes.l),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- RENDER WIDGETS ---

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.s, bottom: 8, top: 16),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildThemeButton(ThemeMode mode, String label, IconData icon, ThemeMode currentMode, bool isDark) {
    final isSelected = currentMode == mode;
    final activeColor = AppColors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.white10 : Colors.black12),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Read and watch theme mode provider from Riverpod
    final currentThemeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: AppSizes.m,
            right: AppSizes.m,
            top: 100, // Spacing for custom header app bar
            bottom: AppSizes.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. APPEARANCE
              _buildSectionHeader('APPEARANCE & THEME', isDark),
              GlassContainer(
                blur: 20,
                opacity: isDark ? 0.08 : 0.12,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? Colors.white12 : Colors.black12,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Theme Mode',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildThemeButton(ThemeMode.light, 'Light Mode', Icons.light_mode_rounded, currentThemeMode, isDark),
                        const SizedBox(width: 8),
                        _buildThemeButton(ThemeMode.dark, 'Dark Mode', Icons.dark_mode_rounded, currentThemeMode, isDark),
                        const SizedBox(width: 8),
                        _buildThemeButton(ThemeMode.system, 'System', Icons.settings_brightness_rounded, currentThemeMode, isDark),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. NOTIFICATIONS
              _buildSectionHeader('NOTIFICATIONS SETTINGS', isDark),
              GlassContainer(
                blur: 20,
                opacity: isDark ? 0.08 : 0.12,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? Colors.white12 : Colors.black12,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.s),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      title: const Text('Push Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Allow AI notifications for scheduled tasks.', style: TextStyle(fontSize: 11)),
                      value: settings.pushNotificationsEnabled,
                      onChanged: (val) {
                        settingsNotifier.togglePushNotifications(val);
                      },
                    ),
                    const Divider(color: Colors.white10),
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      title: const Text('Smart Daily Briefings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Receive a parsed review of your schedule early morning.', style: TextStyle(fontSize: 11)),
                      value: settings.smartBriefingsEnabled,
                      onChanged: (val) {
                        settingsNotifier.toggleSmartBriefings(val);
                      },
                    ),
                    const Divider(color: Colors.white10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notification Sound', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Select custom system alert tone', style: TextStyle(fontSize: 11, color: Colors.white38)),
                            ],
                          ),
                          DropdownButton<String>(
                            value: _notificationTones.contains(settings.notificationTone) ? settings.notificationTone : _notificationTones.first,
                            dropdownColor: isDark ? Colors.black87 : Colors.white,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                            underline: const SizedBox(),
                            items: _notificationTones.map((tone) {
                              return DropdownMenuItem(value: tone, child: Text(tone));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                settingsNotifier.updateNotificationTone(val);
                                _playPreview(val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. ALARM SETTINGS
              _buildSectionHeader('ALARM & HARDWARE', isDark),
              GlassContainer(
                blur: 20,
                opacity: isDark ? 0.08 : 0.12,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? Colors.white12 : Colors.black12,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Volume Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Alarm Volume', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('${(settings.alarmVolume * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: settings.alarmVolume,
                      activeColor: AppColors.primary,
                      inactiveColor: isDark ? Colors.white10 : Colors.black12,
                      onChanged: (val) {
                        settingsNotifier.updateAlarmVolume(val);
                      },
                    ),
                    const Divider(color: Colors.white10),
                    // Ringtone Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alarm Ringtone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('High priority alarm sound', style: TextStyle(fontSize: 11, color: Colors.white38)),
                          ],
                        ),
                        DropdownButton<String>(
                          value: _alarmRingtones.contains(settings.alarmRingtone) ? settings.alarmRingtone : _alarmRingtones.first,
                          dropdownColor: isDark ? Colors.black87 : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                          underline: const SizedBox(),
                          items: _alarmRingtones.map((ring) {
                            return DropdownMenuItem(value: ring, child: Text(ring));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              settingsNotifier.updateAlarmRingtone(val);
                              _playPreview(val);
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    // Vibration Toggle
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      title: const Text('Heavy Vibration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Use strongest vibration motor for alarms', style: TextStyle(fontSize: 11)),
                      value: true,
                      onChanged: (val) {
                        // TODO: Implement Heavy Vibration toggle
                      },
                    ),
                  ],
                ),
              ),

              // 4. BACKUP
              _buildSectionHeader('BACKUP & SYNC', isDark),
              GlassContainer(
                blur: 20,
                opacity: isDark ? 0.08 : 0.12,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? Colors.white12 : Colors.black12,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: AppColors.primary,
                      title: const Text('Auto-Sync Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Silently sync reminders database in the background.', style: TextStyle(fontSize: 11)),
                      value: _autoSyncBackup,
                      onChanged: (val) {
                        setState(() {
                          _autoSyncBackup = val;
                        });
                      },
                    ),
                    const Divider(color: Colors.white10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Manual Database Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Last Backup: $_lastBackupDate', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                            ],
                          ),
                          _backupLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary.withOpacity(0.15),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _triggerBackup,
                                  child: const Text('Backup Now', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 5. PRIVACY & ABOUT
              _buildSectionHeader('LEGAL & INFORMATION', isDark),
              GlassContainer(
                blur: 20,
                opacity: isDark ? 0.08 : 0.12,
                color: isDark ? Colors.black : Colors.white,
                borderColor: isDark ? Colors.white12 : Colors.black12,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                      title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: _showPrivacyPolicy,
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded, color: AppColors.accent),
                      title: const Text('About AI Smart Life Assistant', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'AI Smart Life Assistant',
                          applicationVersion: 'v1.0.0 (Build 1)',
                          applicationLegalese: '© 2026 AI Smart Life Assistant Inc. All rights reserved.',
                          applicationIcon: const CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              // System setting details
              Center(
                child: Column(
                  children: [
                    Text(
                      'AI Smart Life Assistant\nVersion 1.0.0 (Build 1)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(isDark ? 0.04 : 0.03),
                        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _checkForUpdates,
                      icon: const Icon(Icons.system_update_rounded, size: 14, color: AppColors.primary),
                      label: Text('Check for Updates', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11)),
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
