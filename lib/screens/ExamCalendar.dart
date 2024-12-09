import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class ExamCalendarScreen extends StatefulWidget {
  @override
  _ExamCalendarScreenState createState() => _ExamCalendarScreenState();
}

class _ExamCalendarScreenState extends State<ExamCalendarScreen> {
  String? targetExam;
  DateTime? targetDate;
  String? motivationalQuote;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchExamData();
    _fetchDailyMotivation();
  }

  Future<void> _fetchExamData() async {
    try {
      DocumentSnapshot doc =
          await firestore.collection('examGoals').doc('user1').get();
      if (doc.exists) {
        setState(() {
          targetExam = doc['examName'];
          targetDate = DateTime.parse(doc['examDate']);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to load exam data.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _saveExamData(String exam, DateTime date) async {
    try {
      await firestore.collection('examGoals').doc('user1').set({
        'examName': exam,
        'examDate': date.toIso8601String(),
      });
      setState(() {
        targetExam = exam;
        targetDate = date;
      });
      Fluttertoast.showToast(
        msg: "Exam goal saved successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to save exam data.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _deleteExamData() async {
    try {
      await firestore.collection('examGoals').doc('user1').delete();
      setState(() {
        targetExam = null;
        targetDate = null;
      });
      Fluttertoast.showToast(
        msg: "Exam goal deleted successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to delete exam data.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _fetchDailyMotivation() {
    List<String> quotes = [
      "Believe in yourself and all that you are.",
      "Success is no accident. It is hard work and perseverance.",
      "Dream big, work hard, stay focused, and surround yourself with good people.",
      "The harder you work for something, the greater you'll feel when you achieve it.",
      "Don't stop until you're proud."
    ];
    setState(() {
      motivationalQuote = quotes[DateTime.now().day % quotes.length];
    });
  }

  void _showSetExamDialog({String? initialExam, DateTime? initialDate}) {
    final TextEditingController examController =
        TextEditingController(text: initialExam);
    DateTime? selectedDate = initialDate;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Text(
            "Set Exam Target",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TextField(
                  controller: examController,
                  decoration: InputDecoration(
                    hintText: "Name",
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Color(0xFF2C2C2E),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  selectedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark(),
                        child: child!,
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: Text("Pick Target Date",
                    style: TextStyle(
                      color: Colors.white,
                    )),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                if (examController.text.isNotEmpty && selectedDate != null) {
                  _saveExamData(examController.text, selectedDate!);
                  Navigator.pop(context);
                } else {
                  Fluttertoast.showToast(
                    msg: "Please enter exam name and select a date.",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
              child: Text(
                "Save",
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      focusedDay: DateTime.now(),
      firstDay: DateTime.now().subtract(Duration(days: 365)),
      lastDay: DateTime.now().add(Duration(days: 365)),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
        ),
        defaultTextStyle: TextStyle(color: Colors.white),
        weekendTextStyle: TextStyle(color: Colors.orange),
        outsideDaysVisible: false,
        disabledTextStyle: TextStyle(color: Colors.grey),
      ),
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.blueAccent,size: 28,),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.blueAccent,size: 28,),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color(0xFF2C2C2E),
        ),
      ),
      daysOfWeekHeight: 50, // Adding vertical space before week names
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.white),
        weekendStyle: TextStyle(color: Colors.orange),
      ),

      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          bool isPast = date.isBefore(DateTime.now());
          return Center(
            child: Text(
              "${date.day}",
              style: TextStyle(
                color: isPast ? Colors.red : Colors.white,
                decoration: isPast ? TextDecoration.lineThrough : null,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int daysLeft =
        targetDate != null ? targetDate!.difference(DateTime.now()).inDays : 0;

    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E),
        title: Text('Exam Calendar',
            style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      resizeToAvoidBottomInset: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSetExamDialog(),
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white),
        shape: CircleBorder(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCalendar(),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                  alignment: Alignment.topLeft,
                  child: Text("Target Exam Details",
                      style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold))),
            ),
            if (targetExam != null && targetDate != null)
              Dismissible(
                key: ValueKey(targetExam),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) => _deleteExamData(),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                child: GestureDetector(
                  onLongPress: () => _showSetExamDialog(
                      initialExam: targetExam, initialDate: targetDate),
                  child: ListTile(
                    tileColor: Color(0xFF2C2C2E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: Text(
                      targetExam!,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Days Left: $daysLeft",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    trailing: IconButton(
                      onPressed: (){
                        _showSetExamDialog(
                            initialExam: targetExam, initialDate: targetDate);
                      },
                       icon: Icon(Icons.edit, color: Colors.white)),
                  ),
                ),
              ),
            SizedBox(
              height: 10,
            ),
            if (motivationalQuote != null)
              ListTile(
                tileColor: Color(0xFF2C2C2E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                title: Text(
                  "Daily Motivation",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  motivationalQuote!,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
