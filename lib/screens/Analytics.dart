import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:studyscheduler/screens/AllPlannarsScreen.dart';
import 'package:studyscheduler/screens/CompletedPlannarsScreen.dart';
import 'SkippedPlannersScreen.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int totalPlanners = 0;
  int completedPlanners = 0;
  int remainingPlanners = 0;
  int skippedPlanners = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> skippedPlannerDetails = [];

  @override
  void initState() {
    super.initState();
    _fetchProgressData();
  }

  Future<void> _fetchProgressData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      String userId = user.uid;

      final plannersSnapshot = await FirebaseFirestore.instance
          .collection('planners')
          .where('uid', isEqualTo: userId)
          .get();

      final completedSnapshot = await FirebaseFirestore.instance
          .collection('planners')
          .where('uid', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final skippedSnapshot = await FirebaseFirestore.instance
          .collection('planners')
          .where('uid', isEqualTo: userId)
          .where('status', isEqualTo: 'skipped')
          .get();

      setState(() {
        totalPlanners = plannersSnapshot.size;
        completedPlanners = completedSnapshot.size;
        skippedPlanners = skippedSnapshot.size;
        remainingPlanners = totalPlanners - completedPlanners - skippedPlanners;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching progress data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF1C1C1E),
        title: Text("Analytics",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: totalPlanners == 0
                  ? Center(
                      child: Text(
                        "No planners created yet. Start planning to see your progress!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Progress Overview",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            height: 250, // Set a fixed height
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 5,
                                centerSpaceRadius: 55,
                                sections: _buildPieChartSections(),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Detailed Analytics",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllPlannersScreen(),
                                ),
                              );
                            },
                            child: _buildProgressCard("Total Planners", totalPlanners,
                                Colors.blueAccent),
                          ),
                          GestureDetector(
                            onTap: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CompletedPlannersScreen(),
                                ),
                              );
                            },
                            child: _buildProgressCard("Completed Planners",
                                completedPlanners, Colors.green),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SkippedPlannersScreen(),
                                ),
                              );
                            },
                            child: _buildProgressCard("Skipped Planners",
                                skippedPlanners, Colors.orangeAccent),
                          ),
                          _buildProgressCard("Remaining Planners",
                              remainingPlanners, Colors.redAccent),
                        ],
                      ),
                    ),
            ),
      backgroundColor: Color(0xFF1C1C1E), // Dark theme background
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total =
        totalPlanners > 0 ? totalPlanners : 1; // Prevent divide-by-zero
    return [
      PieChartSectionData(
        value: completedPlanners.toDouble(),
        color: Colors.green,
        title: '${((completedPlanners / total) * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: skippedPlanners.toDouble(),
        color: Colors.orangeAccent,
        title: '${((skippedPlanners / total) * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      PieChartSectionData(
        value: remainingPlanners.toDouble(),
        color: Colors.redAccent,
        title: '${((remainingPlanners / total) * 100).toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ];
  }

  Widget _buildProgressCard(String title, int count, Color color) {
    return Card(
      color: Color(0xFF2C2C2E),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(Icons.show_chart, color: Colors.white),
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
