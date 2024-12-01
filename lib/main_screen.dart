import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:mqtt_new/mqtt.dart';
import 'package:mqtt_new/mongodb.dart';

class main_screen extends StatefulWidget {
  @override
  _mainScreenState createState() => _mainScreenState();
}

class _mainScreenState extends State<main_screen> {
  final mqttClientWrapper = MQTTClientWrapper('broker.emqx.io', 'test/topic', 1883);
  bool isSubscribed = false;
  String latestMsg = 'No messages yet';
  double weight = 0.0;
  bool leakage = false;
  bool release = false; // Tracks if release button is pressed
  int internetIssue = 0;
  Set<int> notifiedPercentages = {}; // Tracks already notified percentages
  Timer? dailyTimer;
  List<Map<String, dynamic>> history = [];

  triggerNotification(String title, String msg) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Random().nextInt(100), // Unique ID for each notification
        channelKey: 'basic_channel',
        title: title,
        body: msg,
        color: Colors.red,
      ),
    );
  }

  void _showAlertDialog(BuildContext context, String msg, {bool showReleaseButton = false}) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.withOpacity(0.8),
          content: Text(msg, style: TextStyle(color: Colors.white)),
          actions: [
            if (showReleaseButton)
              TextButton(
                onPressed: () {
                  setState(() {
                    release = true; // Mark release as true
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Release', style: TextStyle(color: Colors.white)),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void handleWeightCheck() {
    if (weight == 0) {
      // Cylinder missing logic
      if (!release) {
        _showAlertDialog(context, 'ALERT: Cylinder Missing!', showReleaseButton: true);
        triggerNotification("ALERT!", "Cylinder Missing!");
        Timer(Duration(minutes: 5), () {
          if (!release) {
            _showAlertDialog(context, 'ALERT: Cylinder Missing!', showReleaseButton: true);
            triggerNotification("ALERT!", "Cylinder Missing!");
          }
        });
      }
    } else {
      // Reset release when weight is non-zero
      release = false;

      // Calculate percentage
      double percentage = (weight % 20) * 100 / 20;
      int roundedPercentage = (percentage ~/ 20) * 20; // Round to nearest 20%

      if (!notifiedPercentages.contains(roundedPercentage)) {
        notifiedPercentages.add(roundedPercentage);

        if (roundedPercentage == 20) {
          triggerNotification("CRITICAL ALERT!", "Gas is about to end!");
        } else if ([80, 60, 40].contains(roundedPercentage)) {
          triggerNotification("Gas Level Update", "$roundedPercentage% gas remaining.");
        }
      }

      // Clear old notifications for invalid percentages
      if (percentage > 20) {
        notifiedPercentages.removeWhere((p) => p < roundedPercentage);
      }
    }
  }

  void toggleSubscription() {
    setState(() {
      if (isSubscribed) {
        mqttClientWrapper.unsubscribe();
      } else {
        mqttClientWrapper.subscribe((message) {
          setState(() {
            latestMsg = message;
            if (message.startsWith('Weight: ')) {
              weight = double.parse(message.split(' ')[1]);
              handleWeightCheck(); // Check weight condition when updated
            } else if (message == 'Leakage: True') {
              leakage = true;
              _showAlertDialog(context, 'ALERT: Gas leakage detected!');
              triggerNotification("ALERT!", "Gas leakage detected!");
            } else if (message == 'Leakage: False') {
              leakage = false;
            }
          });
        });
      }
      isSubscribed = !isSubscribed;
      if (isSubscribed && !mqttClientWrapper.isConnected && internetIssue <= 2) {
        internetIssue++;
        _showAlertDialog(context, "Check your internet connection and Restart the app");
        triggerNotification("ERROR", "Check your internet connection and Restart the app");
      }
    });
  }

  void fetchHistory() async {
    history = await MongoDatabase().getWeightHistory();
    setState(() {});
  }

  void handleReleaseButton() {
    setState(() {
      release = true;
    });
    AwesomeNotifications().cancelAll(); // Clear all notifications
  }

  void saveDailyWeight() async {
    bool isTodaySaved = await MongoDatabase().isWeightSavedForToday(DateTime.now());
    if (!isTodaySaved) {
      await MongoDatabase().saveWeightForToday(weight);
      double? yesterdayWeight = await MongoDatabase().getYesterdayWeight();

      if (yesterdayWeight != null) {
        double gasUsed = yesterdayWeight - weight;
        if (gasUsed > 0) {
          triggerNotification("Daily Gas Usage", "Gas used in the last 24 hours: ${gasUsed.toStringAsFixed(2)} kg");
        }
      }
    }
    fetchHistory();
  }

  void setupDailyTimer() {
    DateTime now = DateTime.now();
    DateTime next12PM = DateTime(now.year, now.month, now.day, 12);
    if (now.isAfter(next12PM)) {
      next12PM = next12PM.add(Duration(days: 1));
    }
    Duration initialDelay = next12PM.difference(now);

    Timer(initialDelay, () {
      saveDailyWeight();
      dailyTimer = Timer.periodic(Duration(days: 1), (timer) => saveDailyWeight());
    });
  }


  @override
  void initState() {
    super.initState();
    mqttClientWrapper.showAlert = () {
      _showAlertDialog(context, "Check your internet connection and Restart the app");
    };
    MongoDatabase.connect().then((_) {
      fetchHistory();
      saveDailyWeight();
    });
    setupDailyTimer();
    mqttClientWrapper.connect().then((_) {
      setState(() {
        isSubscribed = mqttClientWrapper.isSubscribed;
      });
    });
  }

  @override
  void dispose() {
    dailyTimer?.cancel();
    mqttClientWrapper.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MQTT Test App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              mqttClientWrapper.isConnected ? 'Connected' : 'Connecting with server...',
              style: TextStyle(
                color: mqttClientWrapper.isConnected ? Colors.green : Colors.red,
                fontSize: 24,
              ),
            ),
            SizedBox(height: 20),
            Text('Latest Msg: $latestMsg'),
            SizedBox(height: 20),
            CircularScale(weight: weight),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: toggleSubscription,
              child: Text(isSubscribed ? 'Unsubscribe' : 'Subscribe'),
            ),
            const SizedBox(height: 15),
            const Text(
              "History",
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontSize: 24,
              ),
            ),
            Expanded(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Weight (kg)')),
                ],
                rows: history
                    .map((entry) => DataRow(cells: [
                  DataCell(Text(entry['date'])),
                  DataCell(Text(entry['weight'].toString())),
                ]))
                    .toList(),
              ),
            )],
        ),
      ),
    );
  }
}

class CircularScale extends StatelessWidget {
  final double weight;

  CircularScale({required this.weight});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(200, 200),
      painter: ScalePainter(weight),
    );
  }
}

class ScalePainter extends CustomPainter {
  final double weight;
  final double minWeight = 0;
  final double maxWeight = 25;

  ScalePainter(this.weight);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    final outerCirclePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, outerCirclePaint);

    final tickPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i <= 25; i++) {
      final angle = (2 * pi * i / 25) - (pi / 2);
      final tickStart = Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      final tickEnd = Offset(center.dx + (radius - 10) * cos(angle), center.dy + (radius - 10) * sin(angle));
      canvas.drawLine(tickStart, tickEnd, tickPaint);

      if (i % 5 == 0 && i != 25) {
        final textSpan = TextSpan(text: '$i', style: TextStyle(color: Colors.black, fontSize: 12));
        textPainter.text = textSpan;
        textPainter.layout();
        final xOffset = center.dx + (radius - 20) * cos(angle) - textPainter.width / 2;
        final yOffset = center.dy + (radius - 20) * sin(angle) - textPainter.height / 2;
        textPainter.paint(canvas, Offset(xOffset, yOffset));
      }
    }

    final needlePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4;
    final needleAngle = (2 * pi * weight / maxWeight) - (pi / 2);
    final needleEnd = Offset(center.dx + (radius - 20) * cos(needleAngle), center.dy + (radius - 20) * sin(needleAngle));
    canvas.drawLine(center, needleEnd, needlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
