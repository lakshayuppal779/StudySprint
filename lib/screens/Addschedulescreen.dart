import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studyscheduler/DataModel/Scdheduledatamodel.dart';

class AddEducationScheduleScreen extends StatefulWidget {
  @override
  State<AddEducationScheduleScreen> createState() =>
      _AddEducationScheduleScreenState();
}

class _AddEducationScheduleScreenState
    extends State<AddEducationScheduleScreen> {
  // List of image paths
  final List<String> images = [
    'assets/images/img.png',
    'assets/images/pikaso_texttoimage_i-want-an-image-of-boy-who-is-studying-under-a-lam (1).jpeg',
    'assets/images/img_2.png',
    'assets/images/img_3.png',
    'assets/images/img_4.png',
    'assets/images/img_5.png',
    'assets/images/img_6.png',
    'assets/images/img_7.png',
  ];

  // Initially selected image (you can replace with your default image)
  String selectedImage =
      'assets/images/pikaso_texttoimage_i-want-an-image-of-boy-who-is-studying-under-a-lam (1).jpeg';

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

  @override
  Widget build(BuildContext context) {
    var _lessonNameController=TextEditingController();
    var _semesterController=TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Education Schedule",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1C1C1E), // Dark app bar background
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
      backgroundColor: Color(0xFF1C1C1E), // Dark background
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The top image section
              Center(
                child: Container(
                  height: 150,
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(selectedImage), // Display selected image
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25),
              // Grid of small images
              GridView.builder(
                shrinkWrap: true, // Makes sure grid takes only required space
                physics: NeverScrollableScrollPhysics(), // Disable grid scroll
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 images per row
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImage = images[index]; // Update the top image
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(images[index]), // Load image
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20), // Adjust spacing as needed
              // Lessons Name inputs
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  "Lessons Name",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              TextField(
                style: TextStyle(color: Colors.white),
                controller: _lessonNameController,
                decoration: InputDecoration(
                  hintText: "UI/UX Design, Science, Mathematics, etc.",
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  "Semesters or Activity",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Semesters or Activity input
              TextField(
                style: TextStyle(color: Colors.white),
                controller: _semesterController,
                decoration: InputDecoration(
                  hintText: "Semester 1 or Bootcamp, etc.",
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 25),
              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle the create button press
                    // Create a new schedule based on user input
                    final newSchedule = EducationSchedule(
                      lessonName: _lessonNameController.text,
                      semester: _semesterController.text,
                      imagePath: selectedImage,
                    );

                    // Pass the new schedule back to the home screen
                    Navigator.pop(context, newSchedule);
                  },
                  child: Text(
                    "Create",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                    backgroundColor: Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
