import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> getStreakData() async {
    User? user = _auth.currentUser;
    if (user == null) return {'currentStreak': 0, 'lastStudyDate': null};

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc['streaks'] != null) {
      return doc['streaks'];
    } else {
      // Initialize streak data if not present
      await resetStreak();
      return {'currentStreak': 0, 'lastStudyDate': null};
    }
  }

  Future<void> updateStreak() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference userDoc = _firestore.collection('users').doc(user.uid);

    Map<String, dynamic> streakData = await getStreakData();
    DateTime? lastStudyDate = streakData['lastStudyDate'] != null
        ? (streakData['lastStudyDate'] as Timestamp).toDate()
        : null;
    int currentStreak = streakData['currentStreak'];

    DateTime today = DateTime.now();
    if (lastStudyDate != null) {
      Duration difference = today.difference(lastStudyDate);
      if (difference.inDays == 1) {
        // Continue the streak
        currentStreak += 1;
      } else if (difference.inDays > 1) {
        // Missed a day, reset the streak
        currentStreak = 1;
      }
    } else {
      // First-time study
      currentStreak = 1;
    }

    // Update streak data
    await userDoc.set({
      'streaks': {
        'lastStudyDate': today,
        'currentStreak': currentStreak,
      }
    }, SetOptions(merge: true));
  }

  Future<void> resetStreak() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'streaks': {
        'lastStudyDate': null,
        'currentStreak': 0,
      }
    }, SetOptions(merge: true));
  }
}

class DailyStreakTracker extends StatefulWidget {
  @override
  _DailyStreakTrackerState createState() => _DailyStreakTrackerState();
}

class _DailyStreakTrackerState extends State<DailyStreakTracker> {
  int currentStreak = 0;
  final StreakService _streakService = StreakService();

  @override
  void initState() {
    super.initState();
    _fetchStreakData();
  }

  Future<void> _fetchStreakData() async {
    Map<String, dynamic> streakData = await _streakService.getStreakData();
    setState(() {
      currentStreak = streakData['currentStreak'] ?? 0;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E),
        title: Text('Daily Streak', style: TextStyle(fontSize: 22, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {
                // Help button action
              },
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xFF1C1C1E),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          // decoration: BoxDecoration(
          //   gradient: LinearGradient(
          //     colors: [Color(0xFF1C1C1E), Color(0xFF343A40)],
          //     begin: Alignment.topCenter,
          //     end: Alignment.bottomCenter,
          //   ),
          // ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStreakCard(),
              SizedBox(height: 30),
              _buildDailyTrackerContent(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Card(
      color: Color(0xFF2C2C2E),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15,horizontal: 25),
        child: Column(
          children: [
            Icon(Icons.local_fire_department_rounded,size: 120,color: Colors.orangeAccent,),
            Text(
              "Current Streak",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            SizedBox(height: 10),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              child: Text(
                "$currentStreak Days",
                key: ValueKey<int>(currentStreak),
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Achievements",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        SizedBox(height: 20),
        Wrap(
          spacing: 15,
          runSpacing: 10,
          children: [
            _buildBadge("5 Days", currentStreak >= 5),
            _buildBadge("10 Days", currentStreak >= 10),
            _buildBadge("15 Days", currentStreak >= 15),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text, bool achieved) {
    return Chip(
      label: Text(
        text,
        style: TextStyle(color: achieved ? Colors.white : Colors.grey,fontSize: 18),
      ),
      backgroundColor: achieved ? Colors.greenAccent : Color(0xFF2C2C2E),
    );
  }
  Widget _buildDailyTrackerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAchievements(),
        SizedBox(height: 20),
        _buildMotivationalQuote(),
        SizedBox(height: 20),
        _buildProgressTimeline(),
        SizedBox(height: 20),
        _buildInsightsSection(),
      ],
    );
  }

  Widget _buildMotivationalQuote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Motivation",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(16),
          child: Text(
            "“Success is the sum of small efforts, repeated day in and day out.” – Robert Collier",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Streak Progress",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        SizedBox(height: 10),
        Row(
          children: List.generate(5, (index) {
            bool isAchieved = currentStreak > index * 5;
            return Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: isAchieved ? Colors.greenAccent : Colors.grey,
                    radius: 15,
                  ),
                  if (index < 4)
                    Container(height: 2, width: 30, color: isAchieved ? Colors.greenAccent : Colors.grey),
                ],
              ),
            );
          }),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("0 Days", style: TextStyle(color: Colors.grey)),
            Text("25+ Days", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Insights",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildInsightCard("This Week", "12h 30m"),
            _buildInsightCard("Consistency", "90%"),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value) {
    return Card(
      color: Color(0xFF2C2C2E),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70),
            ),
            SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

}

