import 'package:flutter/material.dart';
import 'dart:async';

class PomodoroTimer extends StatefulWidget {
  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  static const int defaultFocusTime = 25; // Focus time in minutes
  static const int defaultBreakTime = 5;  // Break time in minutes

  int focusTime = defaultFocusTime;
  int breakTime = defaultBreakTime;
  bool isFocus = true; // Indicates whether it's a focus or break session
  bool isRunning = false;
  int remainingSeconds = defaultFocusTime * 60;
  Timer? timer;

  void startTimer() {
    setState(() {
      isRunning = true;
    });
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          switchMode();
        }
      });
    });
  }

  void pauseTimer() {
    setState(() {
      isRunning = false;
    });
    timer?.cancel();
  }

  void resetTimer() {
    setState(() {
      isRunning = false;
      timer?.cancel();
      remainingSeconds = (isFocus ? focusTime : breakTime) * 60;
    });
  }

  void switchMode() {
    setState(() {
      isFocus = !isFocus;
      remainingSeconds = (isFocus ? focusTime : breakTime) * 60;
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void openSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Color(0xFF1C1C1E),
              title: Text("Timer Settings", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10,),
                  _buildTimeSetting(
                      "Focus Time (min)", focusTime, (value) {
                    setStateDialog(() {
                      focusTime = value;
                    });
                    setState(() {
                      if (isFocus) {
                        remainingSeconds = focusTime * 60;
                      }
                    });
                  }),
                  SizedBox(height: 20),
                  _buildTimeSetting(
                      "Break Time (min)", breakTime, (value) {
                    setStateDialog(() {
                      breakTime = value;
                    });
                    setState(() {
                      if (!isFocus) {
                        remainingSeconds = breakTime * 60;
                      }
                    });
                  }),
                ],
              ),
              actions: [
                TextButton(
                  child: Text("Close", style: TextStyle(color: Colors.orangeAccent)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeSetting(String label, int currentValue, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white)),
        Slider(
          value: currentValue.toDouble(),
          min: 1,
          max: 60,
          divisions: 59,
          activeColor: Colors.orangeAccent,
          inactiveColor: Colors.grey,
          label: "$currentValue min",
          onChanged: (value) {
            onChanged(value.toInt());
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E),
        title: Text('Pomodoro Timer', style: TextStyle(fontSize: 22, color: Colors.white,fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: openSettings,
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xFF1C1C1E),
      body: Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFocus ? "Focus Session" : "Break Session",
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 280,
                  width: 280,
                  child: CircularProgressIndicator(
                    value: remainingSeconds / ((isFocus ? focusTime : breakTime) * 60),
                    backgroundColor: Colors.grey,
                    color: Colors.orangeAccent,
                    strokeWidth: 10,
                  ),
                ),
                Text(
                  formatTime(remainingSeconds),
                  style: TextStyle(fontSize: 60, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: _buttonStyle(),
                  onPressed: isRunning ? pauseTimer : startTimer,
                  child: Text(isRunning ? "Pause" : "Start ",style: TextStyle(fontSize: 17),),
                ),
                ElevatedButton(
                  style: _buttonStyle(),
                  onPressed: resetTimer,
                  child: Text("Reset",style: TextStyle(fontSize: 17),),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Color(0xFF2C2C2E),
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}
