import 'dart:async';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/reminder.dart';

/// Abstract definition for reminders data repository.
abstract class ReminderRepository {
  Future<List<Reminder>> getReminders();
  Future<void> addReminder(Reminder reminder);
  Future<void> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String id);
  Future<void> syncReminders(String userId);
}

/// A repository that synchronizes local Hive data and remote Firestore data.
/// Uses Hive as an offline fallback and instant local cache.
class SyncedReminderRepository implements ReminderRepository {
  final Box<Map> _box = Hive.box<Map>('reminders_box');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _userRemindersCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('reminders');
  }

  @override
  Future<List<Reminder>> getReminders() async {
    // 1. Always load local from Hive first
    final maps = _box.values.toList();
    final localList = maps.map((m) => Reminder.fromMap(m)).toList();

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      // Offline/No auth: return local data only
      return localList;
    }

    try {
      // 2. Attempt to sync with Firestore (1.5 seconds timeout to avoid freezing offline launches)
      await syncReminders(userId).timeout(const Duration(milliseconds: 1500));
      
      // 3. Reload from updated local Hive cache
      final updatedMaps = _box.values.toList();
      return updatedMaps.map((m) => Reminder.fromMap(m)).toList();
    } catch (e) {
      // Network issues/timeout: Silently fall back to cached local storage
      print('Firestore sync timed out or failed. Running offline fallback: $e');
      return localList;
    }
  }

  @override
  Future<void> addReminder(Reminder reminder) async {
    // Save to Hive immediately
    await _box.put(reminder.id, reminder.toMap());

    // If online/authenticated, upload to Firestore
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await _userRemindersCollection(userId).doc(reminder.id).set(reminder.toMap());
      } catch (e) {
        print('Could not save to Firestore (offline fallback active): $e');
        // Let offline fallback handle it: it will sync later on next launch/connect
      }
    }
  }

  @override
  Future<void> updateReminder(Reminder reminder) async {
    await addReminder(reminder); // Add and Update are identical sets
  }

  @override
  Future<void> deleteReminder(String id) async {
    // Delete from Hive immediately
    await _box.delete(id);

    // If online/authenticated, delete from Firestore
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      try {
        await _userRemindersCollection(userId).doc(id).delete();
      } catch (e) {
        print('Could not delete from Firestore (offline fallback active): $e');
      }
    }
  }

  @override
  Future<void> syncReminders(String userId) async {
    try {
      // 1. Fetch remote records from Firestore
      final remoteSnapshot = await _userRemindersCollection(userId).get();
      final remoteReminders = remoteSnapshot.docs
          .map((doc) => Reminder.fromMap(doc.data()))
          .toList();

      // 2. Fetch local records from Hive
      final localMaps = _box.values.toList();
      final localReminders = localMaps.map((m) => Reminder.fromMap(m)).toList();

      final Map<String, Reminder> remoteMap = {for (var r in remoteReminders) r.id: r};
      final Map<String, Reminder> localMap = {for (var r in localReminders) r.id: r};

      // Write batches for Firestore uploads
      final WriteBatch batch = _firestore.batch();
      bool hasFirestoreEdits = false;

      // 3. Compare local items to remote items
      for (final local in localReminders) {
        final remote = remoteMap[local.id];
        if (remote == null) {
          // Exists locally but not remotely: upload
          batch.set(_userRemindersCollection(userId).doc(local.id), local.toMap());
          hasFirestoreEdits = true;
        } else if (local.updatedAt.isAfter(remote.updatedAt)) {
          // Local is newer: upload
          batch.set(_userRemindersCollection(userId).doc(local.id), local.toMap());
          hasFirestoreEdits = true;
        } else if (remote.updatedAt.isAfter(local.updatedAt)) {
          // Remote is newer: update local Hive cache
          await _box.put(remote.id, remote.toMap());
        }
      }

      // 4. Compare remote items to local items
      for (final remote in remoteReminders) {
        final local = localMap[remote.id];
        if (local == null) {
          // Exists remotely but not locally: save locally
          await _box.put(remote.id, remote.toMap());
        }
      }

      // 5. Commit Firestore updates in a batch
      if (hasFirestoreEdits) {
        await batch.commit();
      }
    } catch (e) {
      print('Error during syncReminders: $e');
      rethrow; // Propagate up to getReminders to trigger fallback
    }
  }
}
