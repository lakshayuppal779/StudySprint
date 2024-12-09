import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:studyscheduler/DataModel/Scdheduledatamodel.dart';
import 'Streak.dart';
import 'package:lottie/lottie.dart';
import 'PlannerDetailScreen.dart';
import 'AllResourcesScreen.dart';

class CreatePlannerScreen extends StatefulWidget {
  final EducationSchedule
      schedule; // Receive the schedule passed from the previous screen

  const CreatePlannerScreen({super.key, required this.schedule});

  @override
  State<CreatePlannerScreen> createState() => _CreatePlannerScreenState();
}

class _CreatePlannerScreenState extends State<CreatePlannerScreen> {
  bool isSelectionMode = false;
  bool isLoading = false; // To track loading state
  final ValueNotifier<Set<String>> selectedPlannerIds = ValueNotifier({});
  final ImagePicker _picker = ImagePicker();
  DateTime? startDate;
  DateTime? endDate;
  final StreakService _streakService = StreakService();

  @override
  void initState() {
    super.initState();
    _startPlannerStatusChecker();
  }

// Function to start a periodic check for overdue planners
  void _startPlannerStatusChecker() {
    User? user = FirebaseAuth.instance.currentUser;
    String? uid = user?.uid;
    Timer.periodic(Duration(minutes: 1), (timer) async {
      final now = DateTime.now();
      // Query planners with status 'upcoming' and a due date in the past
      final querySnapshot = await FirebaseFirestore.instance
          .collection('planners')
          .where('uid', isEqualTo: uid)
          .where('status', isEqualTo: 'upcoming')
          .where('calendar', isLessThan: now)
          .get();

      // Update each overdue planner's status to 'skipped'
      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'status': 'skipped'});
      }
    });
  }

  // Function to show the first dialog (Manually or Automatically)
  void _showPlannerDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E), // Dark background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Row(
            children: [
              Icon(
                Icons.add_task,
                color: Colors.blueAccent,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                'Create Planner',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  text: 'How would you like to create a planner for ',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(
                      text: widget.schedule.lessonName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: ' ?',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.blueAccent),
                    title: const Text(
                      'Create Manually',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return ManualPlannerDialog(
                              lessonName: '${widget.schedule.lessonName}');
                        },
                      );
                    },
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading:
                        const Icon(Icons.camera_alt, color: Colors.blueAccent),
                    title: const Text(
                      'Automatically by Image',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showImagePickerModal();
                    },
                  ),
                  const Divider(color: Colors.grey),
                  ListTile(
                    leading:
                        const Icon(Icons.text_fields, color: Colors.blueAccent),
                    title: const Text(
                      'Automatically by Words',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showWordsModal();
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to show words input modal
  void _showWordsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows full height control
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        final TextEditingController _wordsController = TextEditingController();

        return FractionallySizedBox(
          heightFactor:
              0.8, // Adjust the modal height as 70% of the screen height
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Column(
              children: [
                Text(
                  "Enter Topics",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.white),
                  title: Text('Set Timeframe',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    _showTimeframeDialog(); // Show the timeframe picker dialog
                  },
                ),
                ListTile(
                  leading: Icon(Icons.schedule, color: Colors.white),
                  title: Text('Set Timeslots',
                      style: TextStyle(color: Colors.white)),
                  onTap: _showTimeslotDialog, // Show the timeslot picker dialog
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _wordsController,
                  maxLines: 3,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter topics separated by commas...",
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF2C2C2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the modal
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_wordsController.text.trim().isEmpty) {
                          Fluttertoast.showToast(
                            msg: "Please enter some topics.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.redAccent,
                            textColor: Colors.white,
                          );
                          return;
                        }

                        // Process the topics
                        List<String> topics =
                            _extractTopics(_wordsController.text);
                        if (topics.isNotEmpty &&
                            startDate != null &&
                            endDate != null) {
                          Navigator.pop(context); // Close the modal
                          await _distributeTopicsAcrossDays(topics);
                          Fluttertoast.showToast(
                            msg: "Planner created successfully!",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.greenAccent,
                            textColor: Colors.white,
                          );
                        } else {
                          Fluttertoast.showToast(
                            msg:
                                "Ensure valid topics and a selected timeframe.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Colors.redAccent,
                            textColor: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Submit",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  Future<void> pickAndProcessImageCamera() async {
    Navigator.pop(context);
    _toggleLoading(true);
    try {
      // Step 1: Pick an image
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        print("No image selected.");
        return;
      }

      // Step 2: Upload image to Firebase Storage
      File imageFile = File(pickedFile.path);
      String storagePath =
          "user_images/${DateTime.now().millisecondsSinceEpoch}.jpg";
      UploadTask uploadTask =
          FirebaseStorage.instance.ref(storagePath).putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Step 3: Download the image locally
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final Directory tempDir = await getTemporaryDirectory();
        final File localFile = File('${tempDir.path}/downloaded_image.jpg');
        await localFile.writeAsBytes(response.bodyBytes);
        await _processImageForPlanner(localFile.path);
      } else {
        print("Failed to download the image.");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      _toggleLoading(false); // Stop loading
    }
  }

  /// Image picker and processing handler
  Future<void> pickAndProcessImage() async {
    Navigator.pop(context);
    _toggleLoading(true);
    try {
      // Step 1: Pick an image
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        print("No image selected.");
        return;
      }

      // Step 2: Upload image to Firebase Storage
      File imageFile = File(pickedFile.path);
      String storagePath =
          "user_images/${DateTime.now().millisecondsSinceEpoch}.jpg";
      UploadTask uploadTask =
          FirebaseStorage.instance.ref(storagePath).putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Step 3: Download the image locally
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final Directory tempDir = await getTemporaryDirectory();
        final File localFile = File('${tempDir.path}/downloaded_image.jpg');
        await localFile.writeAsBytes(response.bodyBytes);
        await _processImageForPlanner(localFile.path);
      } else {
        print("Failed to download the image.");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      _toggleLoading(false); // Stop loading
    }
  }

  /// Process the image and generate the planner
  Future<void> _processImageForPlanner(String imagePath) async {
    try {
      if (startDate == null || endDate == null) {
        _showSnackbar('Please select a timeframe first.', Colors.red);
        return;
      }

      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      textRecognizer.close();

      String extractedText = recognizedText.text.trim();
      if (extractedText.isEmpty) {
        _showSnackbar(
            'No text was detected. Please try a different image.', Colors.red);
        return;
      }

      List<String> topics = _extractTopics(extractedText);
      if (topics.isEmpty) {
        _showSnackbar(
            'No valid topics detected. Try a different image.', Colors.red);
        return;
      }

      // Generate planner
      await _distributeTopicsAcrossDays(topics);

      Fluttertoast.showToast(
        msg: "Planner created successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.greenAccent,
        textColor: Colors.white,
      );
    } catch (e) {
      print("Error processing image: $e");
      _showSnackbar(
          'Failed to process the image. Please try again.', Colors.red);
    }
  }

  /// Extract topics from the recognized text
  List<String> _extractTopics(String text) {
    return text
        .split(RegExp(r'[.,]')) // Split by commas and periods only
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Distribute topics across the selected date range
  /// Distribute topics across the selected date range with user-defined or default time slots
  Future<void> _distributeTopicsAcrossDays(List<String> topics) async {
    int totalDays = endDate!.difference(startDate!).inDays + 1;
    int topicsPerDay = (topics.length / totalDays).ceil();
    DateTime currentDate = startDate!;
    List<String> timeSlots = userDefinedTimeslots.isNotEmpty
        ? userDefinedTimeslots
        : ['09:00 AM', '12:00 PM', '03:00 PM', '06:00 PM'];
    int slotIndex = 0;

    List<Map<String, dynamic>> plannerEntries = [];

    for (int i = 0; i < topics.length; i++) {
      // Move to the next day if all slots are used
      if (slotIndex >= timeSlots.length) {
        slotIndex = 0;
        currentDate = currentDate.add(Duration(days: 1));
      }

      List<String> timeParts = timeSlots[slotIndex].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1].split(' ')[0]);

      plannerEntries.add({
        'lessonName': topics[i],
        'type': 'Topic',
        'calendar': DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          hour,
          minute,
        ),
        'isAlarmSet': true,
        'uid': FirebaseAuth.instance.currentUser!.uid,
        'scheduleId': widget.schedule.lessonName,
        'status': 'upcoming',
        'isNotified': false,
      });

      slotIndex++;
    }

    for (var entry in plannerEntries) {
      await FirebaseFirestore.instance.collection('planners').add(entry);
    }
  }

  /// Show a snackbar with the given message and color
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }

  // Function to show image picker modal
  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pick Image",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.white),
                title: Text('Set Timeframe',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  _showTimeframeDialog(); // Show the timeframe picker dialog
                },
              ),
              ListTile(
                leading: Icon(Icons.schedule, color: Colors.white),
                title: Text('Set Timeslots',
                    style: TextStyle(color: Colors.white)),
                onTap: _showTimeslotDialog, // Show the timeslot picker dialog
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.white),
                title: Text('Camera', style: TextStyle(color: Colors.white)),
                onTap: pickAndProcessImageCamera,
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.white),
                title: Text('Gallery', style: TextStyle(color: Colors.white)),
                onTap: pickAndProcessImage,
              ),
            ],
          ),
        );
      },
    );
  }
  List<String> userDefinedTimeslots = [];
  void _showTimeslotDialog() {
    List<String> tempTimeslots =
        List.from(userDefinedTimeslots); // Temporary list for editing
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1C1C1E), // Matching background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Text(
            "Set Timeslots",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...tempTimeslots.map((slot) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            slot,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              tempTimeslots.remove(slot);
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      TimeOfDay? selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData
                                .dark(), // Ensure dark mode for TimePicker
                            child: child!,
                          );
                        },
                      );
                      if (selectedTime != null) {
                        setState(() {
                          tempTimeslots.add(
                              "${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}");
                        });
                      }
                    },
                    icon: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Add Timeslot",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 2,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  userDefinedTimeslots = tempTimeslots;
                });
                Navigator.pop(context);
              },
              child: Text("Save", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _showTimeframeDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1C1C1E),
          title: Text(
            'Select Timeframe',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Start Date Picker
                  ListTile(
                    leading: Icon(Icons.date_range, color: Colors.white),
                    title: Text(
                      startDate != null
                          ? "Start Date: ${startDate?.toLocal().toString().split(' ')[0]}"
                          : "Select Start Date",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark(), // Adjust for dark mode
                            child: child!,
                          );
                        },
                      );
                      if (selectedDate != null) {
                        setState(() {
                          startDate = selectedDate;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  // End Date Picker
                  ListTile(
                    leading:
                        Icon(Icons.date_range_outlined, color: Colors.white),
                    title: Text(
                      endDate != null
                          ? "End Date: ${endDate?.toLocal().toString().split(' ')[0]}"
                          : "Select End Date",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark(), // Adjust for dark mode
                            child: child!,
                          );
                        },
                      );
                      if (selectedDate != null) {
                        setState(() {
                          endDate = selectedDate;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                if (startDate != null && endDate != null) {
                  if (startDate!.isAfter(endDate!)) {
                    // Validation for date range
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        'Start date must be before the end date.',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ));
                    return;
                  }
                  // Use the selected timeframe (startDate and endDate)
                  print('Selected Timeframe: $startDate to $endDate');
                  Navigator.pop(context); // Close the dialog
                }
              },
              child: Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      selectedPlannerIds.value.clear();
    });
  }

  void togglePlannerSelection(String plannerId) {
    selectedPlannerIds.value =
        Set.from(selectedPlannerIds.value..toggle(plannerId));
    if (selectedPlannerIds.value.isEmpty) {
      setState(() =>
          isSelectionMode = false); // Exit selection mode if none selected
    }
  }

  void deleteSelectedPlanners() async {
    final batch = FirebaseFirestore.instance.batch();
    for (String plannerId in selectedPlannerIds.value) {
      batch.delete(
          FirebaseFirestore.instance.collection('planners').doc(plannerId));
    }
    await batch.commit();
    toggleSelectionMode();
  }

  // Icon and color helper functions based on status
  IconData _getStatusIcon(String status) =>
      status == 'completed' ? Icons.check_circle : Icons.schedule;
  Color _getStatusColor(String status) =>
      status == 'completed' ? Colors.green : Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('User not logged in.'));
    }
    String uid = user.uid;
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<Set<String>>(
          valueListenable: selectedPlannerIds,
          builder: (context, selectedIds, child) {
            return Text(
              isSelectionMode
                  ? '${selectedIds.length} selected'
                  : 'Create Planners',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1C1C1E),
        leading: IconButton(
          icon: Icon(isSelectionMode ? Icons.close : Icons.arrow_back,
              color: Colors.white),
          onPressed: isSelectionMode
              ? toggleSelectionMode
              : () => Navigator.pop(context),
        ),
        actions: isSelectionMode
            ? [
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: deleteSelectedPlanners,
                ),
              ]
            : [],
      ),
      body: isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/Animation - 1732443879883.json',
                height: 200,
                width: 200,
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('planners')
                  .where('uid', isEqualTo: uid)
                  .where('scheduleId', isEqualTo: widget.schedule.lessonName)
                  .where('status', isEqualTo: 'upcoming')
                  .orderBy('calendar', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No planners created yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey,fontWeight: FontWeight.w500),
                    ),
                  );
                }
                final plannerDocs = snapshot.data!.docs;

                return ValueListenableBuilder<Set<String>>(
                  valueListenable: selectedPlannerIds,
                  builder: (context, selectedIds, _) {
                    return ListView.builder(
                      itemCount: plannerDocs.length,
                      itemBuilder: (context, index) {
                        var planner =
                            plannerDocs[index].data() as Map<String, dynamic>;
                        var plannerId = plannerDocs[index].id;

                        // Convert Firestore Timestamp to DateTime and format it
                        DateTime? dueDateTime =
                            (planner['calendar'] as Timestamp?)?.toDate();
                        String formattedDueDateTime = dueDateTime != null
                            ? DateFormat('dd/MM/yyyy hh:mm a')
                                .format(dueDateTime)
                            : 'No due date';

                        bool isSelected = selectedIds.contains(plannerId);
                        return GestureDetector(
                          onLongPress: () {
                            if (!isSelectionMode) toggleSelectionMode();
                            togglePlannerSelection(plannerId);
                          },
                          onTap: () {
                            if (isSelectionMode) {
                              togglePlannerSelection(plannerId);
                            }
                            else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlannerDetailScreen(plannerId: plannerId),
                                ),
                              );
                            }
                          },
                          child: Dismissible(
                            key: Key(plannerId),
                            direction: DismissDirection.horizontal,
                            background: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.centerLeft,
                              color: Colors.green,
                              child: Row(
                                children: [
                                  Icon(Icons.check, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Mark as Complete',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            secondaryBackground: Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.centerRight,
                              color: Colors.red,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('Delete',
                                      style: TextStyle(color: Colors.white)),
                                  SizedBox(width: 8),
                                  Icon(Icons.delete, color: Colors.white),
                                ],
                              ),
                            ),
                            onDismissed: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                await FirebaseFirestore.instance
                                    .collection('planners')
                                    .doc(plannerId)
                                    .update({'status': 'completed'});
                                await _streakService.updateStreak();
                                Fluttertoast.showToast(
                                  msg: "Planner completed",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.SNACKBAR,
                                  backgroundColor:
                                      Colors.greenAccent.withOpacity(0.7),
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                              } else if (direction ==
                                  DismissDirection.endToStart) {
                                await FirebaseFirestore.instance
                                    .collection('planners')
                                    .doc(plannerId)
                                    .delete();
                                Fluttertoast.showToast(
                                  msg: "Planner deleted successfully",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.SNACKBAR,
                                  backgroundColor:
                                      Colors.redAccent.withOpacity(0.7),
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );
                              }
                            },
                            child: Card(
                              color: isSelected
                                  ? Colors.blueGrey
                                  : Color(0xFF2C2C2E),
                              margin: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                title: Text(
                                  planner['lessonName'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "Type: ${planner['type']}\nDue Date: $formattedDueDateTime",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                trailing: Icon(
                                  planner['isAlarmSet']
                                      ? Icons.alarm_on
                                      : Icons.alarm_off,
                                  color: planner['isAlarmSet']
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
      resizeToAvoidBottomInset: false,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'uniqueHeroTag1', // Unique hero tag for the first FAB
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AllResourcesScreen(schedule: widget.schedule),
                ),
              );
            },
            backgroundColor: Colors.green,
            shape: CircleBorder(),
            child: Icon(Icons.library_books, color: Colors.white),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'uniqueHeroTag2', // Unique hero tag for the second FAB
            onPressed: _showPlannerDialog,
            backgroundColor: Colors.blueAccent,
            shape: CircleBorder(),
            child: Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: Color(0xFF1C1C1E), // Dark theme background
    );
  }
}

class ManualPlannerDialog extends StatefulWidget {
  final String lessonName;

  const ManualPlannerDialog({super.key, required this.lessonName});

  @override
  _ManualPlannerDialogState createState() => _ManualPlannerDialogState();
}

class _ManualPlannerDialogState extends State<ManualPlannerDialog> {
  String? selectedType = 'Theory';
  String selectedCalendar = "Calendar";
  String selectedTime = "Select Time";
  bool isAlarmSet = false;
  bool isnotify = false;
  var textController = TextEditingController();

  DateTime? pickedDate;
  TimeOfDay? pickedTime;

  // Date picker function
  void _selectDate() async {
    pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF2C2C2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedCalendar = DateFormat('dd/MM/yyyy').format(pickedDate!);
      });
    }
  }

  // Time picker function
  void _selectTime() async {
    pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF2C2C2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime!.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Title
                Text(
                  'Create Planner for ${widget.lessonName}',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                SizedBox(height: 20),
                // Name Field
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TextField(
                    controller: textController,
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
                SizedBox(height: 15),
                // Type Dropdown
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: DropdownButtonFormField<String>(
                    dropdownColor: Color(0xFF2C2C2E),
                    value: selectedType,
                    items: <String>['Theory', 'Practical', 'Assignment']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedType = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF2C2C2E),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                // Calendar Field
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedCalendar,
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                // Time Picker
                GestureDetector(
                  onTap: _selectTime,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedTime,
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                        Icon(
                          Icons.access_time,
                          color: Colors.grey,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                // Alarm Toggle Switch
                // Alarm with Toggle Switch
                Container(
                  padding: EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Alarm",
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                              fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Switch(
                          value: isAlarmSet,
                          onChanged: (value) {
                            setState(() {
                              isAlarmSet = value;
                            });
                          },
                          activeColor: Colors.blueAccent,
                          activeTrackColor: Colors.black26,
                          inactiveTrackColor: Colors.black12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        return;
                      }

                      // Combine date and time into DateTime for Firestore
                      DateTime? combinedDateTime;
                      if (pickedDate != null && pickedTime != null) {
                        combinedDateTime = DateTime(
                          pickedDate!.year,
                          pickedDate!.month,
                          pickedDate!.day,
                          pickedTime!.hour,
                          pickedTime!.minute,
                        );
                      }

                      // Prepare the planner data with the user's uid and combined DateTime
                      Map<String, dynamic> plannerData = {
                        'lessonName': textController.text,
                        'type': selectedType,
                        'calendar': combinedDateTime,
                        'isAlarmSet': isAlarmSet,
                        'uid': user.uid,
                        'scheduleId': widget.lessonName,
                        'status': 'upcoming',
                        'isNotified': isnotify,
                      };

                      await FirebaseFirestore.instance
                          .collection('planners')
                          .add(plannerData);

                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Create',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension on Set<String> {
  void toggle(String value) {
    if (contains(value)) {
      remove(value);
    } else {
      add(value);
    }
  }
}
