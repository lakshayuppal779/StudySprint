import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Assuming Firebase Auth
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shimmer/shimmer.dart';
import 'package:studyscheduler/DataModel/Scdheduledatamodel.dart';
import 'package:studyscheduler/flutter_gemini/splash.dart';
import 'package:studyscheduler/screens/Addschedulescreen.dart';
import 'package:studyscheduler/screens/AllPlannarsScreen.dart';
import 'package:studyscheduler/screens/CompletedPlannarsScreen.dart';
import 'package:studyscheduler/screens/CreatePlannarScreen.dart';
import 'package:studyscheduler/screens/EducationGridScreen.dart';
import 'package:studyscheduler/screens/SettingsScreen.dart';
import 'NotificationScreen.dart';
import 'Streak.dart';
import 'PlannerDetailScreen.dart';

class StudySprintHomeScreen extends StatefulWidget {
  @override
  State<StudySprintHomeScreen> createState() => _StudySprintHomeScreenState();
}

class _StudySprintHomeScreenState extends State<StudySprintHomeScreen> {
  FlutterLocalNotificationsPlugin localNotifications =
  FlutterLocalNotificationsPlugin();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String userName = "User";
  String currentDate = DateFormat('dd MMMM, yyyy').format(DateTime.now());
  String _selectedOption = "Day"; // For displaying the selected option
  List<EducationSchedule> schedules =
  []; // List to hold the created education schedules
  bool isLoading = false; // To show loading indicator
  DateTime? lastPressedTime;
  int totalSchedulesCount = 0;
  int totalPlannersCount = 0;
  int completedPlannersCount = 0;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    _fetchSchedulesFromFirestore();
    _fetchCounts();
    _initializeFirebaseMessaging();
    // Set the system navigation bar color
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor:
        Colors.black.withOpacity(.9), // Set bottom bar color
        statusBarColor: Color(0xFF1C1C1E), // Set transparent status bar
      ),
    );
  }


  Future<void> _initializeFirebaseMessaging() async {
    setupFirebaseMessaging();
    firebaseInit(context);
    setupInteractMessage(context);
  }

  // Set up Firebase Messaging
  Future<void> setupFirebaseMessaging() async {
    // Request permissions
    await messaging.requestPermission();

    // Retrieve token and save it to Firestore
    String? token = await messaging.getToken();
    if (token != null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'token': token}, SetOptions(merge: true));
      }
    }
  }

  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? androidNotification = message.notification!.android;

      if (kDebugMode) {
        print("Foreground Notification: ${notification!.title}, ${notification
            .body}");
      }

      if (Platform.isAndroid) {
        initLocalNotification(context, message);
        showNotification(message);
      }
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
        message.notification!.android!.channelId.toString(),
        message.notification!.android!.channelId.toString(),
        importance: Importance.high,
        showBadge: true,
        playSound: true);
        AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        channel.toString(), channel.toString(),
        channelDescription: "channel descripption",
        importance: Importance.high,
        playSound: true,
        priority: Priority.high,
        sound: channel.sound);

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    //show notification
    Future.delayed(Duration.zero, () {
      localNotifications.show(0, message.notification!.title.toString(),
          message.notification!.body.toString(), notificationDetails,
          payload: "my_data");
    });
  }

  void initLocalNotification(BuildContext context, RemoteMessage message) {
    var androidInitSettings = const AndroidInitializationSettings(
        "@mipmap/launcher_icon");
    var iosInitSettings = const DarwinInitializationSettings();
    var initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    localNotifications.initialize(
        initSettings, onDidReceiveNotificationResponse: (payload) {
      handleMessage(context, message);
    });
  }

  Future<void> setupInteractMessage(BuildContext context) async {
    // background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(context, message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((
        RemoteMessage? message) {
      if (message != null && message.data.isNotEmpty) {
        handleMessage(context, message);
      }
    });
  }

  Future<void> handleMessage(BuildContext context,
      RemoteMessage message) async {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => StudySprintHomeScreen(),));
  }

  Future<void> _fetchCounts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;

    try {
      // Perform all queries concurrently
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('schedules')
            .get(),
        FirebaseFirestore.instance
            .collection('planners')
            .where('uid', isEqualTo: userId)
            .get(),
        FirebaseFirestore.instance
            .collection('planners')
            .where('uid', isEqualTo: userId)
            .where('status', isEqualTo: 'completed')
            .get(),
      ]);

      // Extract the counts
      final int schedulesCount = results[0].size;
      final int plannersCount = results[1].size;
      final int completedPlannersCount = results[2].size;

      // Update the state only once
      setState(() {
        totalSchedulesCount = schedulesCount;
        totalPlannersCount = plannersCount;
        this.completedPlannersCount = completedPlannersCount;
      });
    } catch (e) {
      // Handle any errors here
      print('Error fetching counts: $e');
    }
  }


  // Fetching user info
  void _getUserInfo() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName ?? "User";
      });
    }
  }

  // Function to handle selection from the popup menu
  // Function to handle selection from the popup menu
  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
    });
  }


  // Fetching schedules from Firestore
  Future<void> _fetchSchedulesFromFirestore() async {
    setState(() {
      isLoading = true; // Start showing shimmer
    });
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;

      // Fetch schedules from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .get();

      setState(() {
        // Clear current schedules and add the default schedule first
        schedules.clear();
        schedules.add(EducationSchedule(
          lessonName: "Add your education needs here.",
          semester: "",
          imagePath:
          'assets/images/pikaso_texttoimage_i-want-an-image-of-boy-who-is-studying-under-a-lam (1).jpeg',
        ));
        // Map Firestore data to local schedule list and add them after the default schedule
        schedules.addAll(snapshot.docs
            .map((doc) => EducationSchedule.fromFirestore(doc.data()))
            .toList());

        isLoading = false; // Stop showing shimmer
      });
    }
  }

  // Adding a new schedule to Firestore
  Future<void> _addScheduleToFirestore(EducationSchedule newSchedule) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('schedules')
          .add(newSchedule.toFirestore());
    }
    _fetchSchedulesFromFirestore();
  }

  // Function to handle adding new schedules
  void _addSchedule(EducationSchedule newSchedule) {
    _addScheduleToFirestore(newSchedule);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Check if back button is pressed within the last 2 seconds
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrToastHasExpired =
            lastPressedTime == null ||
                now.difference(lastPressedTime!) > Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrToastHasExpired) {
          lastPressedTime = now;
          Fluttertoast.showToast(
            msg: "Press again to exit",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Color(0xFF1C1C1E),
            textColor: Colors.white,
            fontSize: 16.0,
          );
          return false; // Don't exit the app
        }
        return true; // Exit the app if pressed again within 2 seconds
      },
      child: Scaffold(
        backgroundColor: Color(0xFF1C1C1E), // Dark background color
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEducationScheduleScreen(),
              ),
            );
            // If a new schedule was created, add it to the list
            if (result != null && result is EducationSchedule) {
              _addSchedule(result);
            }
          },
          backgroundColor: Colors.blueAccent,
          shape: CircleBorder(),
          child: Icon(Icons.add, color: Colors.white, size: 32),
        ),

        body: RefreshIndicator(
          onRefresh: _fetchCounts,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 25),
                  // Date and Notification Row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.blueAccent,
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            Text(
                              currentDate, // Display the current date
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                      DailyStreakTracker()),
                                );
                              },
                              icon: Icon(
                                Icons.local_fire_department,
                                color: Colors.orangeAccent,
                                size: 30,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Navigate to the Notification Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificationScreen(),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.notifications_active,
                                color: Colors.orangeAccent,
                                size: 30,
                              ),
                            ),
                          ],
                        ),


                      ],
                    ),
                  ),
                  // Greeting and User Status
                  Text(
                    "Hey, $userName 👋", // Dynamically display the user's name
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Pursuing a Bachelor's degree",
                        // Can also make this dynamic
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          FontAwesomeIcons.edit,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 5),
                      // Add the circular popup menu button here
                      CircularPopupMenuButton(
                        selectedOption: _selectedOption,
                        onSelected: _selectOption,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EducationGridScreen(
                                            schedules: schedules),
                                  ),
                                );
                              },
                              child: _buildStatCard(
                                  totalSchedulesCount.toString(), "Lesson")),
                          DottedLine(),
                          GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AllPlannersScreen(),
                                  ),
                                );
                              },
                              child: _buildStatCard(
                                  totalPlannersCount.toString(), "Task")),
                          DottedLine(),
                          GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CompletedPlannersScreen(),
                                  ),
                                );
                              },
                              child: _buildStatCard(
                                  completedPlannersCount.toString(), "Finish")),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildSectionHeader("Education Schedule"),
                  SizedBox(height: 10),
                  _buildEducationScheduleList(),
                  SizedBox(height: 10),
                  // Upcoming Schedule Section
                  _buildSectionHeader2("Upcoming Planner"),
                  _buildUpcomingScheduleCard(),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.black12,
          // Set transparent to make gradient visible
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white70,
          onTap: (index) async {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SplashScreen(),
                ),
              );
            }

            if (index == 2) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(),
                  ));
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.robot,),
              label: 'Gemini AI',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  // Function to build the stat cards
  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 90,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white70, // Light shade border color
          width: 2.0, // Border width
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.zero, // Set margin to 0
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EducationGridScreen(schedules: schedules),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero, // Set padding to 0
            ),
            child: Text(
              'View All',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 15,
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSectionHeader2(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.zero, // Set margin to 0
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AllPlannersScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero, // Set padding to 0
            ),
            child: Text(
              'View All',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 15,
              ),
            ),
          ),
        )
      ],
    );
  }

  // Build the horizontal list of education schedules
  Widget _buildEducationScheduleList() {
    if (isLoading) {
      return _buildShimmerEffect(); // Display shimmer while loading
    } else {
      return Container(
        height: 205, // Adjust height as needed
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            return _buildEducationCard(schedules[index]);
          },
        ),
      );
    }
  }

  // Shimmer effect for the education cards
  Widget _buildShimmerEffect() {
    return Container(
      height: 205, // Adjust height as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3, // Show 3 shimmer cards as a placeholder
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[700]!,
            highlightColor: Colors.grey[500]!,
            child: Container(
              width: 150,
              height: 200,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[700], // Background color of shimmer card
              ),
            ),
          );
        },
      ),
    );
  }

  // Modified _buildEducationCard function to take a schedule parameter
  Widget _buildEducationCard(EducationSchedule schedule) {
    return GestureDetector(
      onTap: () {
        // Navigate to the planner screen if it's not the default schedule
        if (schedule.lessonName != "Add your education needs here.") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePlannerScreen(schedule: schedule),
            ),
          );
        }
      },
      onLongPress: () {
        // Show deletion confirmation dialog only for non-default schedules
        if (schedule.lessonName != "Add your education needs here.") {
          showDialog(
            context: context,
            builder: (context) =>
                AlertDialog(
                  backgroundColor: Color(0xFF2C2C2E),
                  title: Text(
                    'Delete Schedule',
                    style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Are you sure you want to delete this schedule?',
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                          'Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        User? user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          String userId = user.uid;
                          final scheduleRef = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('schedules')
                              .where(
                              'lessonName', isEqualTo: schedule.lessonName)
                              .where('semester', isEqualTo: schedule.semester)
                              .get();

                          for (var doc in scheduleRef.docs) {
                            await doc.reference.delete();
                          }

                          setState(() {
                            schedules.remove(schedule);
                          });

                          Fluttertoast.showToast(
                            msg: "Schedule deleted successfully",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.SNACKBAR,
                            backgroundColor: Colors.redAccent.withOpacity(0.7),
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      },
                      child:
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
          );
        }
      },
      child: Container(
        width: 150,
        height: 200,
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Padding(
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
                          borderRadius: BorderRadius.circular(12),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schedule.lessonName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                schedule.semester,
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
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
            // Add "+" icon button in the center if this is the default schedule
            if (schedule.lessonName == "Add your education needs here.")
              Center(
                child: MaterialButton(
                  color: Colors.white.withOpacity(0.7),
                  height: 45,
                  shape: CircleBorder(),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEducationScheduleScreen(),
                      ),
                    );
                    // If a new schedule was created, add it to the list
                    if (result != null && result is EducationSchedule) {
                      _addSchedule(result);
                    }
                  },
                  child: Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingScheduleCard() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('User not logged in.'));
    }
    String uid = user.uid;
    // Define the date range based on the selected option
    DateTime now = DateTime.now();
    DateTime startDate = now;
    DateTime endDate;

    switch (_selectedOption) {
      case "Day":
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case "Week":
        endDate = now.add(Duration(days: 7));
        break;
      case "Month":
        endDate = DateTime(now.year, now.month + 1, now.day);
        break;
      default:
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('planners')
          .where('uid', isEqualTo: uid) // Fetch planners for the current user
          .where(
          'calendar', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('calendar', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'upcoming')
          .orderBy('calendar')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            height: 80,
            child: Center(
              child: Text(
                'No upcoming planners',
                style: TextStyle(fontSize: 18, color: Colors.grey,fontWeight: FontWeight.w500),
              ),
            ),
          );
        }
        final plannerDocs = snapshot.data!.docs;
        return ListView.builder(
          padding: EdgeInsets.zero,
          physics: BouncingScrollPhysics(),
          shrinkWrap: true,
          itemCount: plannerDocs.length,
          itemBuilder: (context, index) {
            var planner = plannerDocs[index].data() as Map<String, dynamic>;
            var plannerId = plannerDocs[index].id;
            DateTime dueDate = (planner['calendar'] as Timestamp).toDate();
            String formattedDate =
            DateFormat('dd MMM yyyy, hh:mm a').format(dueDate);
            return Card(
              color: Color(0xFF2C2C2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  planner['lessonName'],
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  "Due: $formattedDate",
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlannerDetailScreen(plannerId: plannerId),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
// Custom widget to draw a vertical dotted line
class DottedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, // Width of the dotted line
      height: 95, // Height of the dotted line
      child: CustomPaint(
        painter: DottedLinePainter(),
      ),
    );
  }
}

// Custom painter class to draw a dotted line
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white54 // Dotted line color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double dashHeight = 5, dashSpace = 5, startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// Custom Widget for circular button with popup menu
class CircularPopupMenuButton extends StatelessWidget {
  final String selectedOption;
  final Function(String) onSelected;

  CircularPopupMenuButton({
    required this.selectedOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => onSelected(value),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      icon: Container(
        width: 66.0, // Smaller button width
        height: 30.0, // Smaller button height
        decoration: BoxDecoration(
          color: Color(0xFF1C1C1E), // Button background color
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white30, // Light shade border color
            width: 2.0, // Border width
          ), // Rounded rectangular shape
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              selectedOption,
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12), // Display selected option inside button
            ),
            Icon(
              Icons.arrow_drop_down, // Upside-down arrow to indicate a dropdown
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'Day',
          child: ListTile(
            leading: Icon(Icons.calendar_view_day, color: Colors.blue),
            title:
                Text('Day', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Week',
          child: ListTile(
            leading: Icon(Icons.calendar_today, color: Colors.green),
            title: Text('Week',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
        PopupMenuItem<String>(
          value: 'Month',
          child: ListTile(
            leading: Icon(Icons.calendar_month, color: Colors.orange),
            title: Text('Month',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
      ],
      color: Color(0xFF1C1C1E),
    );
  }
}
