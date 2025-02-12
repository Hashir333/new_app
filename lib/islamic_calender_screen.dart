import 'package:flutter/material.dart';
import 'package:islamic_hijri_calendar/islamic_hijri_calendar.dart';

class HijriCalendarExample extends StatefulWidget {
  const HijriCalendarExample({super.key});

  @override
  State<HijriCalendarExample> createState() => _HijriCalendarExampleState();
}

class _HijriCalendarExampleState extends State<HijriCalendarExample> {
  int selectedDay = 7;
  int selectedYear = 2023;
  String selectedMonth = "July";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        elevation: 1,
        title:
            const Text("Hijri Calendar", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        // leading: IconButton(
        //     onPressed: () {
        //       Navigator.push(
        //           context,
        //           MaterialPageRoute(
        //               builder: (context) => NamazTimingsScreen()));
        //     },
        //     icon: Icon(Icons.menu)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            Expanded(
              child: IslamicHijriCalendar(
                isHijriView: true,
                highlightBorder: Colors.red,
                defaultBorder: Colors.teal.shade200,
                highlightTextColor: Colors.white,
                defaultTextColor: Colors.black,
                defaultBackColor: Colors.white,
                adjustmentValue: 0,
                isGoogleFont: true,
                fontFamilyName: "Lato",
                getSelectedEnglishDate: (selectedDate) {},
                getSelectedHijriDate: (selectedDate) {},
                isDisablePreviousNextMonthDates: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
