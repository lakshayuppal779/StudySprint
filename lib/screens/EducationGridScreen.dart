import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:studyscheduler/DataModel/Scdheduledatamodel.dart';
import 'package:studyscheduler/screens/CreatePlannarScreen.dart';

class EducationGridScreen extends StatefulWidget {
  final List<EducationSchedule> schedules;

  // Constructor to accept the schedules list
  EducationGridScreen({required this.schedules});

  @override
  _EducationGridScreenState createState() => _EducationGridScreenState();
}

class _EducationGridScreenState extends State<EducationGridScreen> {
  bool _isLoading = true; // To simulate loading for the shimmer effect

  @override
  void initState() {
    super.initState();
    // Simulate a delay to show shimmer effect for 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false; // Stop loading after delay
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Schedules',
          style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1C1C1E),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFF1C1C1E),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _isLoading
            ? _buildShimmerGrid() // Show shimmer effect while loading
            : _buildEducationGrid(), // Show actual grid when loading is done
      ),
    );
  }

  // Method to build the grid of education schedules
  // Method to build the grid of education schedules
  Widget _buildEducationGrid() {
    // Filter out the placeholder schedule
    final filteredSchedules = widget.schedules
        .where((schedule) => schedule.lessonName != "Add your education needs here.")
        .toList();

    if (filteredSchedules.isEmpty) {
      return Center(
        child: Text(
          'No schedules available.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cards per row
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredSchedules.length,
      itemBuilder: (context, index) {
        return _buildEducationCard(filteredSchedules[index]);
      },
    );
  }


  // Method to build shimmer loading effect
  Widget _buildShimmerGrid() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cards per row
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: 8, // Show 4 shimmer cards as a placeholder
      itemBuilder: (context, index) {
        return _buildShimmerEducationCard();
      },
    );
  }

  // Method to build shimmer education card
  Widget _buildShimmerEducationCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[700]!,
      highlightColor: Colors.grey[500]!,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          color: Colors.white24,
        ),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 125,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white12,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 16,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 14,
                    color: Colors.white24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build actual education card
  Widget _buildEducationCard(EducationSchedule schedule) {
    return GestureDetector(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreatePlannerScreen(schedule: schedule),
          ),
        );
      },
      child: Container(
        width: 150,
        height: 200,
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              Colors.purpleAccent,
              Colors.blueAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Color(0xFF2C2C2E),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    width: 150,
                    height: 125,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      image: DecorationImage(
                        image: AssetImage(schedule.imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 150,
                  height: 50,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize
                            .min, // Use min to take only necessary space
                        children: [
                          Text(
                            schedule.lessonName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            schedule.semester,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

