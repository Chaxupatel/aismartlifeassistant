import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

/// Representation of the version status check.
class AppUpdateInfo {
  final bool hasUpdate;
  final bool forceUpdate;
  final String latestVersion;
  final String localVersion;
  final String updateUrl;
  final String releaseNotes;

  AppUpdateInfo({
    required this.hasUpdate,
    required this.forceUpdate,
    required this.latestVersion,
    required this.localVersion,
    required this.updateUrl,
    required this.releaseNotes,
  });
}

/// Service querying Firestore database configurations for application versioning checks.
class VersionCheckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper to compare two semantic versions. Returns true if current is older than latest.
  bool isVersionOlder(String current, String latest) {
    try {
      final currentClean = current.split('+')[0]; // Strip build number (e.g., "1.0.0+1" -> "1.0.0")
      final latestClean = latest.split('+')[0];

      final currentParts = currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latestParts = latestClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (var i = 0; i < latestParts.length; i++) {
        final latestPart = latestParts[i];
        final currentPart = i < currentParts.length ? currentParts[i] : 0;

        if (currentPart < latestPart) return true;
        if (currentPart > latestPart) return false;
      }
    } catch (e) {
      debugPrint('Error comparing versions: $e');
    }
    return false;
  }

  /// Queries the Firestore collection `app_config`, document `version` for details.
  Future<AppUpdateInfo> checkForUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersion = packageInfo.version;

    try {
      final snapshot = await _firestore.collection('app_config').doc('version').get();
      if (!snapshot.exists) {
        return AppUpdateInfo(
          hasUpdate: false,
          forceUpdate: false,
          latestVersion: localVersion,
          localVersion: localVersion,
          updateUrl: '',
          releaseNotes: '',
        );
      }

      final data = snapshot.data()!;
      final latestVersion = data['latest_version'] as String? ?? localVersion;
      final forceUpdate = data['force_update'] as bool? ?? false;
      final updateUrl = data['update_url'] as String? ?? '';
      final releaseNotes = data['release_notes'] as String? ?? 'No details provided.';

      final hasUpdate = isVersionOlder(localVersion, latestVersion);

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        forceUpdate: forceUpdate,
        latestVersion: latestVersion,
        localVersion: localVersion,
        updateUrl: updateUrl,
        releaseNotes: releaseNotes,
      );
    } catch (e) {
      debugPrint('Error checking for updates in Firestore: $e');
      return AppUpdateInfo(
        hasUpdate: false,
        forceUpdate: false,
        latestVersion: localVersion,
        localVersion: localVersion,
        updateUrl: '',
        releaseNotes: '',
      );
    }
  }

  /// Opens the App Store or Play Store link externally
  Future<bool> launchUpdateUrl(String urlString) async {
    if (urlString.isEmpty) return false;
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch update URL: $e');
    }
    return false;
  }
}

/// Provider to fetch and utilize VersionCheckService in Riverpod widgets
final versionCheckServiceProvider = Provider<VersionCheckService>((ref) {
  return VersionCheckService();
});
