import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:studyscheduler/screens/Analytics.dart';
import 'package:studyscheduler/screens/EditProfileScreen.dart';
import 'package:studyscheduler/screens/FeedbackScreen.dart';
import 'package:studyscheduler/screens/Termsofservice.dart';
import 'package:studyscheduler/screens/onboding_screen.dart'; // Import the Onboarding screen
import 'PromodoroTimer.dart';
import 'ExamCalendar.dart';
import 'RevisionScheduler.dart';


class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Set the system navigation bar color to black
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFF1C1C1E), // Set bottom bar color
        statusBarColor: Color(0xFF1C1C1E), // Set transparent status bar
      ),
    );
  }

  // Google Sign-Out function
  Future<void> _signOut() async {
    try {
      // Sign out from Google Sign-In
      await GoogleSignIn().signOut();
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to OnboardingScreen after sign-out
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    } catch (e) {
      // Handle sign-out errors if necessary
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E),
        title: Text('Setting',
            style: TextStyle(fontSize: 22, color: Colors.white,fontWeight: FontWeight.bold)),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Navigate to EditProfileScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditProfileScreen()),
                      );
                    },
                    child: _buildSettingsItem('Edit Profile'),
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AnalyticsScreen()),
                        );
                      },
                      child: _buildSettingsItem('Analytics')),
                  _buildSettingsItem('Notification'),
                  _buildSettingsItem('Language'),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PomodoroTimer()),
                        );
                      },
                      child: _buildSettingsItem('Pomodoro Timer')),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ExamCalendarScreen()),
                        );
                      },
                      child: _buildSettingsItem('Exam Calendar')),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RevisionSchedulerScreen()),
                        );
                      },
                      child: _buildSettingsItem('Revision Scheduler')
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TermsOfServiceScreen()),
                        );
                      },
                      child: _buildSettingsItem('Terms of Service')
                  ),
                  GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FeedbackScreen()),
                        );
                      },
                      child: _buildSettingsItem('Feedback')
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.0),
            _buildLogoutButton(), // Logout button implementation
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(String title) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.0),
      padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 16.0,
          ),
        ],
      ),
    );
  }

  // Logout button widget
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _signOut, // Call Google Sign-Out when tapped
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8.0),
              Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
