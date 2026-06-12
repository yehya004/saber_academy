import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/router/app_router.dart';
import '../models/lesson_schedule_model.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background notifications if needed.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _messaging;
  FlutterLocalNotificationsPlugin? _localNotifications;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  static String? initError;
  static String? lastToken;
  static String? lastTokenError;
  static Map<String, dynamic>? pendingNotificationPayload;

  /// Setup push notifications
  Future<void> initialize() async {
    // Initialize Windows local notifications
    if (!kIsWeb && Platform.isWindows) {
      try {
        await localNotifier.setup(
          appName: 'Saber Academy',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
        _initialized = true;
        debugPrint("Windows LocalNotifier initialized successfully.");
      } catch (e) {
        debugPrint("Error initializing Windows LocalNotifier: $e");
      }
      return;
    }

    try {
      _messaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();

      // 1. Initialize Firebase Messaging
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Setup Foreground Notification presentation
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Initialize Local Notifications for Android foreground
      const androidInit = AndroidInitializationSettings('notification_icon');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      await _localNotifications!.initialize(
        settings: const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (details) {
          debugPrint("Notification clicked: ${details.payload}");
          if (details.payload != null && details.payload!.isNotEmpty) {
            try {
              final Map<String, dynamic> data = jsonDecode(details.payload!);
              handleNotificationPayload(data);
            } catch (e) {
              debugPrint("Error parsing notification response payload: $e");
            }
          }
        },
      );

      // Create Android channel
      const channel = AndroidNotificationChannel(
        'saber_academy_notifications_v3',
        'Saber Academy Notifications',
        description: 'Notifications for lessons, homeworks, and chats',
        importance: Importance.max,
      );

      await _localNotifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null && !kIsWeb) {
          _localNotifications?.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: 'notification_icon',
                largeIcon: const DrawableResourceAndroidBitmap('app_icon'),
                color: const Color(0xFF0F5132),
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });

      // 5. Handle Background/Terminated clicks via FCM
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("FCM message opened app: ${message.data}");
        handleNotificationPayload(message.data);
      });

      // Check for initial message when app is launched from terminated state
      _messaging!.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint("FCM initial message: ${message.data}");
          // Delay slightly to ensure GoRouter is fully initialized
          Future.delayed(const Duration(milliseconds: 1500), () {
            handleNotificationPayload(message.data);
          });
        }
      });

      _initialized = true;
      debugPrint("NotificationService initialized successfully.");

      // Listen to token refresh globally
      _messaging!.onTokenRefresh.listen((newToken) async {
        final client = Supabase.instance.client;
        final currentUserId = client.auth.currentUser?.id;
        if (currentUserId != null) {
          try {
            await client
                .from('profiles')
                .update({'fcm_token': newToken})
                .eq('id', currentUserId);
            debugPrint("FCM Token refreshed and saved: $newToken");
          } catch (e) {
            debugPrint("Error saving refreshed FCM token: $e");
          }
        }
      });

      // Try updating token immediately if user is already authenticated
      updateTokenOnServer();
    } catch (e) {
      initError = e.toString();
      debugPrint("Warning: Firebase Messaging initialization failed. "
          "Make sure google-services.json is added to android/app/. Error: $e");
    }
  }

  Future<void> requestPermissions() async {
    try {
      if (!kIsWeb) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }
    } catch (e) {
      debugPrint("Error requesting system notification permission: $e");
    }

    if (!_initialized || _messaging == null) return;
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('User granted permission: ${settings.authorizationStatus}');
      await updateTokenOnServer();
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
    }
  }

  /// Retrieves the FCM Token of this device and saves it in Supabase profiles
  Future<void> updateTokenOnServer() async {
    if (!_initialized || _messaging == null) return;
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      // Try to get token with up to 3 retries and 2-second delay to allow initialization
      String? token;
      for (int i = 0; i < 3; i++) {
        try {
          token = await _messaging!.getToken();
          if (token != null) break;
        } catch (e) {
          lastTokenError = e.toString();
          debugPrint("Attempt ${i + 1} to get FCM token failed: $e");
        }
        await Future.delayed(const Duration(seconds: 2));
      }

      if (token == null) {
        lastToken = "Null after retries";
        debugPrint("FCM token is null after retries.");
        return;
      }

      lastToken = token;
      debugPrint("Device FCM Token: $token");
      await client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
    } catch (e) {
      lastTokenError = e.toString();
      debugPrint("Error saving FCM token to server: $e");
    }
  }

  /// Clears the token on logout
  Future<void> removeTokenFromServer(String userId) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': null})
          .eq('id', userId);
    } catch (e) {
      debugPrint("Error clearing FCM token from server: $e");
    }
  }

  RealtimeChannel? _windowsRealtimeChannel;

  /// Global realtime message listener for Windows desktop to show Toast Notifications.
  void initWindowsRealtimeListener(String userId) {
    if (!kIsWeb && Platform.isWindows) {
      // 1. Cancel previous subscription if active
      _windowsRealtimeChannel?.unsubscribe();

      final client = Supabase.instance.client;

      // 2. Subscribe to inserts on public.chat_messages table
      _windowsRealtimeChannel = client
          .channel('windows_chat_notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chat_messages',
            callback: (payload) async {
              try {
                final record = payload.newRecord;
                final receiverId = record['receiver_id'] as String?;
                final senderId = record['sender_id'] as String?;
                final text = record['message_text'] as String? ?? '';

                if (receiverId == userId) {
                  String senderName = "مستخدم";
                  try {
                    final senderProfile = await AuthService().fetchProfile(senderId ?? '');
                    if (senderProfile != null) {
                      senderName = senderProfile.fullName;
                    }
                  } catch (e) {
                    debugPrint("Failed to fetch sender profile: $e");
                  }

                  // Display Windows native toast
                  final notification = LocalNotification(
                    title: "رسالة جديدة من $senderName",
                    body: text,
                    silent: false,
                  );
                  await notification.show();
                }
              } catch (e) {
                debugPrint("Error handling windows notification event: $e");
              }
            },
          );
      _windowsRealtimeChannel!.subscribe();
      debugPrint("Windows Realtime Chat Listener subscribed for user: $userId");
    }
  }

  /// Cancel global realtime message listener for Windows desktop.
  void cancelWindowsRealtimeListener() {
    if (!kIsWeb && Platform.isWindows) {
      _windowsRealtimeChannel?.unsubscribe();
      _windowsRealtimeChannel = null;
      debugPrint("Windows Realtime Chat Listener unsubscribed.");
    }
  }

  /// Handles payload from local notifications and FCM clicks to navigate to chat
  static Future<void> handleNotificationPayload(Map<String, dynamic> data) async {
    final senderId = (data['senderId'] ?? data['sender_id']) as String?;
    if (senderId != null && senderId.isNotEmpty) {
      final currentPath = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
      if (currentPath == AppRoutes.splash) {
        debugPrint("App is on Splash Screen. Delaying navigation payload.");
        pendingNotificationPayload = data;
        return;
      }

      final senderName = (data['senderName'] ?? data['sender_name']) as String?;
      if (senderName != null && senderName.isNotEmpty) {
        // Navigate instantly using the name from payload!
        AppRouter.router.push(AppRoutes.chat, extra: {
          'partnerId': senderId,
          'partnerName': senderName,
        });
        return;
      }

      // Fallback if name is not in payload
      try {
        final profile = await AuthService().fetchProfile(senderId);
        final partnerName = profile?.fullName ?? "مستخدم";
        
        AppRouter.router.push(AppRoutes.chat, extra: {
          'partnerId': senderId,
          'partnerName': partnerName,
        });
      } catch (e) {
        debugPrint("Error navigating to chat from notification fallback: $e");
      }
    }
  }

  /// Schedules lesson reminders locally (same-day and 30 minutes before)
  Future<void> scheduleLessonReminders(List<DayScheduleEntry> localEntries, String studentName) async {
    if (kIsWeb || Platform.isWindows || _localNotifications == null) return;

    try {
      await _localNotifications!.cancelAll();
    } catch (e) {
      debugPrint("Error cancelling notifications: $e");
    }

    int notificationId = 100;
    tz.Location location;
    try {
      location = tz.local;
    } catch (_) {
      location = tz.getLocation('Africa/Cairo');
    }

    for (final entry in localEntries) {
      final localHour = entry.hourUtc;
      final localMinute = entry.minuteUtc;
      final weekday = entry.dayOfWeek;

      // ── Reminder 1: 30 minutes before the lesson
      int totalMinutes = localHour * 60 + localMinute - 30;
      int dayShift = 0;
      if (totalMinutes < 0) {
        totalMinutes += 24 * 60;
        dayShift = -1;
      }
      final remHour = totalMinutes ~/ 60;
      final remMinute = totalMinutes % 60;
      int remWeekday = weekday + dayShift;
      if (remWeekday < 1) remWeekday = 7;
      if (remWeekday > 7) remWeekday = 1;

      await _scheduleWeeklyNotification(
        id: notificationId++,
        title: "تذكير بالدرس بعد نصف ساعة",
        body: "السلام عليكم يا $studentName، للتذكير درسك سيبدأ بعد 30 دقيقة إن شاء الله.",
        weekday: remWeekday,
        hour: remHour,
        minute: remMinute,
        location: location,
      );

      // ── Reminder 2: On the same day (e.g. at 9:00 AM local time)
      // Only schedule if the lesson is after 9:30 AM
      if (localHour >= 10) {
        await _scheduleWeeklyNotification(
          id: notificationId++,
          title: "تذكير بدرس اليوم 🎓",
          body: "السلام عليكم يا $studentName، لديك درس اليوم في تمام الساعة ${_fmtTime12h(localHour, localMinute)} إن شاء الله.",
          weekday: weekday,
          hour: 9,
          minute: 0,
          location: location,
        );
      }
    }
  }

  String _fmtTime12h(int h, int m) {
    final period = h < 12 ? 'ص' : 'م';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    required tz.Location location,
  }) async {
    final now = tz.TZDateTime.now(location);
    var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    
    int daysUntil = weekday - scheduledDate.weekday;
    if (daysUntil < 0) {
      daysUntil += 7;
    } else if (daysUntil == 0 && scheduledDate.isBefore(now)) {
      daysUntil += 7;
    }
    scheduledDate = scheduledDate.add(Duration(days: daysUntil));

    const androidDetails = AndroidNotificationDetails(
      'lesson_reminders_channel',
      'Lesson Reminders',
      channelDescription: 'Scheduled reminders for upcoming lessons',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications!.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    debugPrint("Scheduled weekly reminder ID $id for weekday $weekday at $hour:$minute. Next date: $scheduledDate");
  }
}

