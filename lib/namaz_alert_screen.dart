import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

final locationProvider =
    StateNotifierProvider<LocationNotifier, Position?>((ref) {
  return LocationNotifier(ref);
});

class LocationNotifier extends StateNotifier<Position?> {
  final Ref ref;
  LocationNotifier(this.ref) : super(null) {
    getUserLocation();
  }

  Future<void> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    state = position;
  }
}

final notificationProvider = Provider((ref) => NotificationService());

class NotificationService {
  late final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  NotificationService() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap action if needed
      },
    );
  }

  Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'prayer_channel',
      'Prayer Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _flutterLocalNotificationsPlugin.show(
        0, title, body, notificationDetails);
  }
}

class PrayerAlertScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(locationProvider);
    return Scaffold(
      appBar: AppBar(title: Text("Today's Prayer Times")),
      body: position == null
          ? Center(child: CircularProgressIndicator())
          : PrayerTimesView(position: position),
    );
  }
}

class PrayerTimesView extends ConsumerStatefulWidget {
  final Position position;
  PrayerTimesView({required this.position});

  @override
  _PrayerTimesViewState createState() => _PrayerTimesViewState();
}

class _PrayerTimesViewState extends ConsumerState<PrayerTimesView> {
  Map<String, bool> prayerAlerts = {
    'Fajr': false,
    'Dhuhr': false,
    'Asr': false,
    'Maghrib': false,
    'Isha': false,
  };

  @override
  Widget build(BuildContext context) {
    final coordinates =
        Coordinates(widget.position.latitude, widget.position.longitude);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;
    final prayerTimes = PrayerTimes.today(coordinates, params);

    String formatTime(DateTime time) => DateFormat.jm().format(time);

    return ListView(
      children: prayerAlerts.keys.map((prayer) {
        DateTime prayerTime = _getPrayerTime(prayerTimes, prayer);
        return ListTile(
          title: Text("$prayer - ${formatTime(prayerTime)}"),
          trailing: Switch(
            value: prayerAlerts[prayer]!,
            onChanged: (value) {
              setState(() {
                prayerAlerts[prayer] = value;
              });
              if (value) {
                _scheduleNotification(prayer, prayerTime);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  DateTime _getPrayerTime(PrayerTimes prayerTimes, String prayer) {
    switch (prayer) {
      case 'Fajr':
        return prayerTimes.fajr;
      case 'Dhuhr':
        return prayerTimes.dhuhr;
      case 'Asr':
        return prayerTimes.asr;
      case 'Maghrib':
        return prayerTimes.maghrib;
      case 'Isha':
        return prayerTimes.isha;
      default:
        return DateTime.now();
    }
  }

  void _scheduleNotification(String prayer, DateTime time) {
    final notificationService = ref.read(notificationProvider);
    notificationService.showNotification(
        "$prayer Time", "It's time for $prayer prayer.");
  }
}
