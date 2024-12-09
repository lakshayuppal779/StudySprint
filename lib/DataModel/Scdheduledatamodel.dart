class EducationSchedule {
  final String lessonName;
  final String semester;
  final String imagePath;

  EducationSchedule({
    required this.lessonName,
    required this.semester,
    required this.imagePath,
  });

  // Factory constructor to create an instance of EducationSchedule from Firestore data
  factory EducationSchedule.fromFirestore(Map<String, dynamic> data) {
    return EducationSchedule(
      lessonName: data['lessonName'] ?? 'No lesson name',
      semester: data['semester'] ?? 'No semester',
      imagePath: data['imagePath'] ?? 'assets/images/default_image.jpg',
    );
  }

  // Method to convert an EducationSchedule instance to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'lessonName': lessonName,
      'semester': semester,
      'imagePath': imagePath,
    };
  }
}
