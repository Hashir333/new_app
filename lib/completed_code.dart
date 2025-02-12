import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  List<Map<String, String>> prayerTimesList = [];

  @override
  void initState() {
    super.initState();
    _calculatePrayerTimes();
  }

  void _calculatePrayerTimes() {
    final coordinates = Coordinates(24.8607, 67.0011); // Karachi, Pakistan
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    DateTime today = DateTime.now();
    List<Map<String, String>> tempList = [];

    for (int i = 0; i < 30; i++) {
      final date = today.add(Duration(days: i));
      final dateComponents = DateComponents(date.year, date.month, date.day);
      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

      String formatTime(DateTime time) {
        return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      }

      tempList.add({
        "date": "${date.toLocal().toString().split(' ')[0]}",
        "Fajr": formatTime(prayerTimes.fajr),
        "Dhuhr": formatTime(prayerTimes.dhuhr),
        "Asr": formatTime(prayerTimes.asr),
        "Maghrib": formatTime(prayerTimes.maghrib),
        "Isha": formatTime(prayerTimes.isha),
      });
    }

    setState(() {
      prayerTimesList = tempList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("30 Days Prayer Times")),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20.0,
          border: TableBorder(
            horizontalInside: BorderSide.none,
            verticalInside: BorderSide(color: Colors.red, width: 2.0),
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
    );
  }
}
