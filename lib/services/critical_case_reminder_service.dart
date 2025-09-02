import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CriticalCaseReminderService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> init(BuildContext context) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _notificationsPlugin.initialize(initializationSettings);
    _scheduleDailyReminder(context);
  }

  Future<void> _scheduleDailyReminder(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userDoc = await _firestore.collection('Users').doc(user.uid).get();
    final doctorName = userDoc['username'] ?? user.displayName;
    final query = await _firestore
        .collection('criticalCases')
        .where('doctor', isEqualTo: doctorName)
        .get();
    // Schedule for 8AM local time using timezone package
    tz.initializeTimeZones();
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    await _notificationsPlugin.zonedSchedule(
      0,
      'Critical Case Reminder',
      'You have critical cases to attend today.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails('critical_case_channel', 'Critical Case Reminders',
            channelDescription: 'Daily reminder for critical cases', importance: Importance.max, priority: Priority.high),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
