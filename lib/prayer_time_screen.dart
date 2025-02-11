import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';

class NamazTimingsScreen extends StatefulWidget {
  const NamazTimingsScreen({super.key});

  @override
  State<NamazTimingsScreen> createState() => _NamazTimingsScreenState();
}

class _NamazTimingsScreenState extends State<NamazTimingsScreen> {
  Position? _currentPosition;
  List<Map<String, String>> _prayerTimesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 📍 لوکیشن حاصل کریں
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });

    _fetchPrayerTimes(position.latitude, position.longitude);
  }

  // 🕌 اگلے 30 دنوں کے نماز کے اوقات حاصل کریں
  void _fetchPrayerTimes(double lat, double lon) {
    final coordinates = Coordinates(lat, lon);
    final params =
        CalculationMethod.karachi.getParameters(); // 🇵🇰 پاکستان کے لیے

    List<Map<String, String>> tempPrayerTimesList = [];

    for (int i = 0; i < 30; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final dateComponents = DateComponents.from(date);
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

      tempPrayerTimesList.add({
        "date": "${date.day}-${date.month}-${date.year}",
        "Fajr": prayerTimes.fajr.toLocal().toString().substring(11, 16),
        "Dhuhr": prayerTimes.dhuhr.toLocal().toString().substring(11, 16),
        "Asr": prayerTimes.asr.toLocal().toString().substring(11, 16),
        "Maghrib": prayerTimes.maghrib.toLocal().toString().substring(11, 16),
        "Isha": prayerTimes.isha.toLocal().toString().substring(11, 16),
      });
    }

    setState(() {
      _prayerTimesList = tempPrayerTimesList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 1,
        title: const Text(
          "Namaz Timings",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prayerTimesList.isEmpty
              ? const Center(child: Text("ڈیٹا لوڈ نہیں ہو سکا"))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("Fajr AM")),
                      DataColumn(label: Text("Dhuhr PM")),
                      DataColumn(label: Text("Asr PM")),
                      DataColumn(label: Text("Maghrib PM")),
                      DataColumn(label: Text("Isha PM")),
                    ],
                    rows: _prayerTimesList.map((prayerTimes) {
                      return DataRow(cells: [
                        DataCell(Text(prayerTimes["date"]!)),
                        DataCell(Text(prayerTimes["Fajr"]!)),
                        DataCell(Text(prayerTimes["Dhuhr"]!)),
                        DataCell(Text(prayerTimes["Asr"]!)),
                        DataCell(Text(prayerTimes["Maghrib"]!)),
                        DataCell(Text(prayerTimes["Isha"]!)),
                      ]);
                    }).toList(),
                  ),
                ),
    );
  }
}
