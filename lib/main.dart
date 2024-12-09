import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studyscheduler/firebase_options.dart';
import 'package:studyscheduler/screens/Homescreen.dart';
import 'package:studyscheduler/screens/notification.dart';
import 'package:studyscheduler/screens/onboding_screen.dart';

import 'notesMaking/cubit/Note.cubit.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> _checkAndSendNotifications() async {
  try {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) return;

    String uid = user.uid;
    DateTime now = DateTime.now();

    // Query relevant planners within a 15-minute window
    QuerySnapshot planners = await FirebaseFirestore.instance
        .collection('planners')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'upcoming')
        .where('calendar', isGreaterThanOrEqualTo: now)
        .where('calendar', isLessThanOrEqualTo: now.add(Duration(minutes: 15)))
        .get();

    for (var doc in planners.docs) {
      Map<String, dynamic> planner = doc.data() as Map<String, dynamic>;

      if (planner['isNotified'] == false && planner['isAlarmSet'] == true) {
        Timestamp calendarTimestamp = planner['calendar'];
        DateTime dueDateTime = calendarTimestamp.toDate();

        // Check if the planner is due within 5 minutes
        if (dueDateTime.isAfter(now) &&
            dueDateTime.isBefore(now.add(Duration(minutes: 5)))) {
          String title = "Upcoming Planner Reminder";
          String body = "Your planner '${planner['lessonName']}' is due soon!";

          // Send the notification
          await NotificationService.sendNotification(planner['token'], title, body);

          // Mark as notified
          await FirebaseFirestore.instance
              .collection('planners')
              .doc(doc.id)
              .update({'isNotified': true});
        }
      }
    }
  } catch (e) {
    print("Error checking notifications: $e");
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Start the timer for periodic task execution
  Timer.periodic(Duration(minutes: 15), (timer) async {
    await _checkAndSendNotifications();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NoteCubit>(
          create: (context) => NoteCubit(),
        ),
        // Add other providers if needed
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Study Sprint',
        theme: ThemeData(
          scaffoldBackgroundColor: Color(0xFFEEF1F8),
          primarySwatch: Colors.blue,
          fontFamily: "Intel",
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            errorStyle: TextStyle(height: 0),
            border: defaultInputBorder,
            enabledBorder: defaultInputBorder,
            focusedBorder: defaultInputBorder,
            errorBorder: defaultInputBorder,
          ),
        ),
        home: SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFF1C1C1E),
      statusBarColor: Color(0xFF1C1C1E),
    ));

    // Simulate loading time and check authentication status
    Timer(const Duration(seconds: 3), () {
      _checkLoginStatus(); // Call the function to check login status
    });
  }

  // Function to check if the user is logged in or not
  void _checkLoginStatus() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // If the user is logged in, navigate to the home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StudySprintHomeScreen()),
      );
    } else {
      // If the user is not logged in, navigate to the onboarding screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E), // Set background to black
      body: Center(
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Study',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Bright text color for dark mode
                ),
              ),
              TextSpan(
                text: 'Sprint',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.normal,
                  color: Colors.green.shade200, // Lighter text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(
    color: Color(0xFFDEE3F2),
    width: 1,
  ),
);
