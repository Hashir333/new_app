import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final locationProvider =
    StateNotifierProvider<LocationNotifier, Position?>((ref) {
  return LocationNotifier(ref);
});

class LocationNotifier extends StateNotifier<Position?> {
  final Ref ref;
  bool isLoading = false;
  bool isDialogShown = false;
  LocationNotifier(this.ref) : super(null) {
    _listenForLocationChanges();
    getUserLocation();
  }

  Future<void> getUserLocation() async {
    isLoading = true;
    state = null;
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      isLoading = false;
      state = null;
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        isLoading = false;
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      isLoading = false;
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      state = position;
    } catch (e) {
      state = null;
    }
    isLoading = false;
  }

  void _listenForLocationChanges() {
    Geolocator.getServiceStatusStream().listen((status) async {
      if (status == ServiceStatus.enabled) {
        await getUserLocation();
      }
    });
  }
}

class PrayerTimesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(locationProvider);
    final locationNotifier = ref.read(locationProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text("30 Days Prayer Times")),
      body: FutureBuilder(
        future: Geolocator.isLocationServiceEnabled(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && !(snapshot.data as bool)) {
            if (!locationNotifier.isDialogShown) {
              locationNotifier.isDialogShown = true;
              Future.delayed(Duration.zero, () {
                _showLocationDialog(context, ref);
              });
            }
            return Center(
                child: Text("Location is required to show prayer times"));
          }

          return locationNotifier.isLoading
              ? Center(child: CircularProgressIndicator())
              : position == null
                  ? Center(
                      child: ElevatedButton(
                        onPressed: () => _showLocationDialog(context, ref),
                        child: Text("Enable Location"),
                      ),
                    )
                  : PrayerTimesTable(position: position);
        },
      ),
    );
  }

  void _showLocationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Location Required"),
        content: Text(
            "Please enable location services to get accurate prayer times."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: Text("Enable Location"),
          ),
        ],
      ),
    );
  }
}

class PrayerTimesTable extends StatelessWidget {
  final Position position;
  PrayerTimesTable({required this.position});

  @override
  Widget build(BuildContext context) {
    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    DateTime today = DateTime.now();
    List<Map<String, String>> prayerTimesList = [];

    for (int i = 0; i < 30; i++) {
      final date = today.add(Duration(days: i));
      final dateComponents = DateComponents(date.year, date.month, date.day);
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

      String formatDate(DateTime date) {
        return DateFormat("d MMM").format(date);
      }

      String formatTime(DateTime time) {
        return DateFormat('h:mm a').format(time); // 12-hour format
      }

      prayerTimesList.add({
        "date": formatDate(date),
        "Fajr": formatTime(prayerTimes.fajr),
        "Dhuhr": formatTime(prayerTimes.dhuhr),
        "Asr": formatTime(prayerTimes.asr),
        "Maghrib": formatTime(prayerTimes.maghrib),
        "Isha": formatTime(prayerTimes.isha),
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20.0,
            dividerThickness: 0,
            // showBottomBorder: false,

            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.white, width: 0),
              verticalInside: BorderSide(color: Colors.red, width: 2),
              bottom: BorderSide.none,
              top: BorderSide.none,
              right: BorderSide.none,
              left: BorderSide.none,
            ),
            columns: [
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Fajr")),
              DataColumn(label: Text("Dhuhr")),
              DataColumn(label: Text("Asr")),
              DataColumn(label: Text("Maghrib")),
              DataColumn(label: Text("Isha")),
            ],
            rows: prayerTimesList.map((prayer) {
              return DataRow(cells: [
                DataCell(Text(prayer['date']!)),
                DataCell(Text(prayer['Fajr']!)),
                DataCell(Text(prayer['Dhuhr']!)),
                DataCell(Text(prayer['Asr']!)),
                DataCell(Text(prayer['Maghrib']!)),
                DataCell(Text(prayer['Isha']!)),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
