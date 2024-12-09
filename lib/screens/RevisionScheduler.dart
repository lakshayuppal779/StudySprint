import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RevisionSchedulerScreen extends StatefulWidget {
  @override
  _RevisionSchedulerScreenState createState() =>
      _RevisionSchedulerScreenState();
}

class _RevisionSchedulerScreenState extends State<RevisionSchedulerScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> revisionPlans = [];

  @override
  void initState() {
    super.initState();
    _fetchRevisionPlans();
  }

  Future<void> _fetchRevisionPlans() async {
    try {
      QuerySnapshot snapshot =
      await firestore.collection('revisionPlans').get();

      setState(() {
        revisionPlans = snapshot.docs
            .map((doc) => {
          "id": doc.id,
          ...doc.data() as Map<String, dynamic>,
        })
            .toList();
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to load revision plans.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _saveRevisionPlan(String topic, DateTime date) async {
    try {
      DocumentReference docRef =
      await firestore.collection('revisionPlans').add({
        'topic': topic,
        'targetDate': date.toIso8601String(),
        'revisionCount': 0,
      });

      setState(() {
        revisionPlans.add({
          "id": docRef.id,
          'topic': topic,
          'targetDate': date.toIso8601String(),
          'revisionCount': 0,
        });
      });

      Fluttertoast.showToast(
        msg: "Revision plan saved successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to save revision plan.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _deleteRevisionPlan(String id) async {
    try {
      await firestore.collection('revisionPlans').doc(id).delete();

      setState(() {
        revisionPlans.removeWhere((plan) => plan['id'] == id);
      });

      Fluttertoast.showToast(
        msg: "Revision plan deleted successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to delete revision plan.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _updateRevisionCount(String id, int currentCount) async {
    try {
      await firestore.collection('revisionPlans').doc(id).update({
        'revisionCount': currentCount + 1,
      });

      setState(() {
        final plan = revisionPlans.firstWhere((plan) => plan['id'] == id);
        plan['revisionCount'] += 1;
      });

      Fluttertoast.showToast(
        msg: "Revision count updated!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to update revision count.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _showAddRevisionDialog() {
    final TextEditingController topicController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Text(
            "Add Revision Plan",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TextField(
                  controller: topicController,
                  decoration: InputDecoration(
                    hintText: "Topic Name",
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
                    initialDate: DateTime.now(),
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
                if (topicController.text.isNotEmpty && selectedDate != null) {
                  _saveRevisionPlan(topicController.text, selectedDate!);
                  Navigator.pop(context);
                } else {
                  Fluttertoast.showToast(
                    msg: "Please enter a topic and select a date.",
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

  Widget _buildRevisionPlanTile(Map<String, dynamic> plan) {
    final DateTime targetDate = DateTime.parse(plan['targetDate']);
    final String topic = plan['topic'];
    final int revisionCount = plan['revisionCount'];

    return Dismissible(
      key: Key(plan['id']),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteRevisionPlan(plan['id']);
      },
      child: Card(
        color: Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          title: Text(
            topic,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Target Date: ${targetDate.day}/${targetDate.month}/${targetDate.year}\nRevisions: $revisionCount",
            style: TextStyle(color: Colors.white70),
          ),
          trailing: IconButton(
            icon: Icon(Icons.update, color: Colors.white),
            onPressed: () {
              _updateRevisionCount(plan['id'], revisionCount);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E),
        title: Text(
          'Revision Scheduler',
          style: TextStyle(fontSize: 22, color: Colors.white,fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRevisionDialog,
        backgroundColor: Colors.blueAccent,
        shape: CircleBorder(),
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (revisionPlans.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30,vertical:280),
                      child: Text(
                        "No revision plans added yet.",
                        style: TextStyle(color: Colors.white70, fontSize: 18,fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...revisionPlans.map((plan) => _buildRevisionPlanTile(plan)),
          ],
        ),
      ),
    );
  }
}
