import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:controlapp/notificationService.dart';
import 'dart:async';

class TemperatureGraph extends StatefulWidget {
  @override
  _TemperatureGraphState createState() => _TemperatureGraphState();
}

class _TemperatureGraphState extends State<TemperatureGraph> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  List<FlSpot> temperatureSpots = [];
  Timer? resetTimer;
  String selectedPeriod = 'Today';
  bool isLoading = true; 

  @override
  void initState() {
    super.initState();
    listenToTemperatureUpdates();
    setupMidnightReset();
  }

  void setupMidnightReset() {
    DateTime now = DateTime.now();
    DateTime midnight = DateTime(now.year, now.month, now.day + 1); // Next day at 00:00
    Duration untilMidnight = midnight.difference(now);
    resetTimer = Timer(untilMidnight, () {
      listenToTemperatureUpdates(); 
      setupMidnightReset(); 
    });
  }

  void listenToTemperatureUpdates() {
    setState(() {
      isLoading = true; 
      temperatureSpots = []; // Clear the current data
    });

    DateTime now = DateTime.now();
    DateTime startTime;
    DateTime endTime;

    switch (selectedPeriod) {
      case 'Yesterday':
        startTime = DateTime(now.year, now.month, now.day - 1);
        endTime = DateTime(now.year, now.month, now.day); // end at the start of today
        break;
      case '1 Week':
        startTime = now.subtract(Duration(days: 7));
        endTime = now;
        break;
      case '1 Month':
        startTime = DateTime(now.year, now.month - 1, now.day);
        endTime = now;
        break;
      case 'Today':
      default:
        startTime = DateTime(now.year, now.month, now.day);
        endTime = now;
    }

    _firestore
        .collection('temperatures')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
        .where('timestamp', isLessThan: Timestamp.fromDate(endTime))
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      List<FlSpot> newSpots = [];
      snapshot.docs.forEach((doc) {
        double value = (doc['value'] as num).toDouble();
        DateTime currentTime = (doc['timestamp'] as Timestamp).toDate();
        double xValue;

        switch (selectedPeriod) {
          case 'Yesterday':
            xValue = currentTime.hour + currentTime.minute / 60.0;
            break;
          case '1 Week':
            xValue = currentTime.difference(startTime).inDays.toDouble();
            break;
          case '1 Month':
            xValue = currentTime.difference(startTime).inDays.toDouble();
            break;
          case 'Today':
          default:
            xValue = currentTime.hour + currentTime.minute / 60.0;
        }

        newSpots.add(FlSpot(xValue, value));
      });

      if (hasSignificantTemperatureRise(newSpots)) {
        _notificationService.showNotification(
          id: 1, // A unique identifier for this notification
          title: 'Temperature Alert',
          body: 'The temperature has reached a critical level: $newSpots',
        );
      }
      setState(() {
        temperatureSpots = newSpots;
        isLoading = false; // Set loading to false after data is received
      });
    });
  }

  bool hasSignificantTemperatureRise(List<FlSpot> spots) {
    for (int i = 1; i < spots.length; i++) {
      if ((spots[i].y - spots[i - 1].y) > 5) { 
        return true;
      }
    }
    return false;
  }

  void showTemperatureAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Temperature Alert"),
          content: Text("There's a significant rise in temperature detected."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
            ),
          ],
        );
      },
    );
  }

  void onPeriodChange(String? newPeriod) {
    if (newPeriod != null) {
      setState(() {
        selectedPeriod = newPeriod;
        listenToTemperatureUpdates();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double minX, maxX, interval;
    String Function(double) getTitles;
    DateTime now = DateTime.now();
    switch (selectedPeriod) {
      case 'Yesterday':
        minX = 0;
        maxX = 24;
        interval = 1;
        getTitles = (value) {
          final DateTime time = DateTime(now.year, now.month, now.day - 1)
              .add(Duration(hours: value.toInt(), minutes: ((value - value.toInt()) * 60).toInt()));
          return DateFormat('HH:mm').format(time);
        };
        break;
      case '1 Week':
        minX = 0;
        maxX = 6; // 7 days in a week
        interval = 1;
        getTitles = (value) {
          return DateFormat('E').format(DateTime.now().subtract(Duration(days: 6 - value.toInt())));
        };
        break;
      case '1 Month':
        minX = 0;
        maxX = now.difference(DateTime(now.year, now.month - 1, now.day)).inDays.toDouble();
        interval = 2;
        getTitles = (value) {
          DateTime date = DateTime(now.year, now.month - 1, now.day).add(Duration(days: value.toInt()));
          return DateFormat('d MMM').format(date);
        };
        break;
      case 'Today':
      default:
        minX = 0;
        maxX = 24;
        interval = 1;
        getTitles = (value) {
          final DateTime time = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
              .add(Duration(hours: value.toInt(), minutes: ((value - value.toInt()) * 60).toInt()));
          return DateFormat('HH:mm').format(time);
        };
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Temperature Graph',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedPeriod,
                    dropdownColor: Colors.deepPurpleAccent,
                    style: TextStyle(color: Colors.white),
                    items: [
                      DropdownMenuItem(child: Text('Today'), value: 'Today'),
                      DropdownMenuItem(child: Text('Yesterday'), value: 'Yesterday'),
                      DropdownMenuItem(child: Text('1 Week'), value: '1 Week'),
                      DropdownMenuItem(child: Text('1 Month'), value: '1 Month'),
                    ],
                    onChanged: onPeriodChange,
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                    underline: SizedBox(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoading 
                ? Center(child: CircularProgressIndicator())
                : temperatureSpots.isEmpty
                    ? Center(child: Text("No data available for the selected period"))
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.deepPurpleAccent, width: 2),
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple.shade700,
                                Colors.black54,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              width: 1000,
                              padding: const EdgeInsets.all(16.0),
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    getDrawingHorizontalLine: (value) {
                                      return FlLine(
                                        color: const Color(0xff37434d),
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return FlLine(
                                        color: const Color(0xff37434d),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border(
                                      bottom: BorderSide(color: Colors.deepPurpleAccent, width: 2),
                                      left: BorderSide(color: Colors.deepPurpleAccent, width: 2),
                                      right: BorderSide(color: Colors.transparent),
                                      top: BorderSide(color: Colors.transparent),
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 22,
                                        getTitlesWidget: (value, meta) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 10.0),
                                            child: Text(getTitles(value), style: TextStyle(fontSize: 11, color: Colors.white)),
                                          );
                                        },
                                        interval: interval,
                                      ),
                                    ),
                                  ),
                                  minX: minX,
                                  maxX: maxX,
                                  minY: 0,
                                  maxY: 40,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: temperatureSpots,
                                      isCurved: true,
                                      color: Colors.deepPurpleAccent,
                                      barWidth: 5,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                          radius: 4,
                                          color: Colors.white,
                                          strokeWidth: 2,
                                          strokeColor: Colors.deepPurple,
                                        ),
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.deepPurple.withOpacity(0.3),
                                            Colors.deepPurple.withOpacity(0.0),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
