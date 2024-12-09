import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studyscheduler/helper/dialogs.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers for each field
  TextEditingController nameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  TextEditingController instagramController = TextEditingController();
  TextEditingController facebookController = TextEditingController();
  TextEditingController twitterController = TextEditingController();

  // Boolean flags for toggling edit mode
  bool isEditingName = false;
  bool isEditingUsername = false;
  bool isEditingBio = false;
  bool isEditingInstagram = false;
  bool isEditingFacebook = false;
  bool isEditingTwitter = false;

  // Image Picker Variables
  File? _selectedImage;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final User? user = FirebaseAuth.instance.currentUser; // Get current user
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFF1C1C1E), // Set bottom bar color
        statusBarColor: Color(0xFF1C1C1E), // Set transparent status bar
      ),
    );
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        setState(() {
          nameController.text = data?['name'] ?? '';
          usernameController.text = data?['username'] ?? '';
          bioController.text = data?['bio'] ?? '';
          instagramController.text = data?['instagram'] ?? '';
          facebookController.text = data?['facebook'] ?? '';
          twitterController.text = data?['twitter'] ?? '';
          _imageUrl =
              data?['profileImageUrl'] ?? ''; // Fetch image URL from Firestore
          _isLoading = false; // Stop loading when data is fetched
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (user != null) {
      await _firestore.collection('users').doc(user!.uid).set({
        'name': nameController.text,
        'username': usernameController.text,
        'bio': bioController.text,
        'instagram': instagramController.text,
        'facebook': facebookController.text,
        'twitter': twitterController.text,
        'profileImageUrl': _imageUrl,
      }, SetOptions(merge: true));

      // Optionally show a confirmation dialog/snackbar
      Dialogs.showSnackbar(context, "Profile updated successfully");
    }
  }

  // Upload selected image to Firebase Storage
  Future<void> _uploadImage(File image) async {
    try {
      String filePath = 'profile_images/${user!.uid}.png';
      TaskSnapshot snapshot =
          await _storage.ref().child(filePath).putFile(image);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        _imageUrl = downloadUrl; // Update image URL after upload
      });

      // Save the image URL to Firestore
      await _firestore
          .collection('users')
          .doc(user!.uid)
          .update({'profileImageUrl': _imageUrl});
      Dialogs.showSnackbar(context, "Profile picture updated successfully");
    } catch (e) {
      Dialogs.showSnackbar(context, "Failed to upload image");
    }
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      backgroundColor: Color(0xFF1C1C1E), // Dark theme background
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 5, bottom: 40),
          children: [
            Text(
              "Profile Photo",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _pickImage(ImageSource.camera);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    fixedSize: Size(130, 130),
                    backgroundColor: Color(0xFF2C2C2E), // Dark theme button
                  ),
                  child: Image.asset("assets/images/camera.png"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    fixedSize: Size(130, 130),
                    backgroundColor: Color(0xFF2C2C2E), // Dark theme button
                  ),
                  child: Image.asset("assets/images/picture.png"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
    await _uploadImage(_selectedImage!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E),
        title: Text('Edit Profile',
            style: TextStyle(fontSize: 20, color: Colors.white,fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(color: Colors.blue, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Color(0xFF1C1C1E),
      resizeToAvoidBottomInset: false,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImage(
                                  imageFile: _selectedImage,
                                  imageUrl: _imageUrl,
                                ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 70,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : _imageUrl != null && _imageUrl!.isNotEmpty
                                    ? NetworkImage(_imageUrl!)
                                    : AssetImage('assets/images/WhatsApp Image 2024-09-25 at 12.45.14_fad55fa1.jpg')
                                        as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: -6,
                          right: -20,
                          child: MaterialButton(
                            onPressed: _showBottomSheet,
                            height: 33,
                            child:
                                Icon(Icons.edit, color: Colors.white, size: 22),
                            shape: CircleBorder(),
                            color: Colors.blueAccent,
                            elevation: 1,
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 20),
                    // Separate TextField for 'Name'
                    buildTextField(
                      label: 'Name',
                      hintText: 'Add name',
                      controller: nameController,
                      isEditing: isEditingName,
                      onEditToggle: () {
                        setState(() {
                          isEditingName = !isEditingName;
                        });
                      },
                    ),
                    // Separate TextField for 'Username'
                    buildTextField(
                      label: 'Username',
                      hintText: 'Add username',
                      controller: usernameController,
                      isEditing: isEditingUsername,
                      onEditToggle: () {
                        setState(() {
                          isEditingUsername = !isEditingUsername;
                        });
                      },
                    ),
                    // Separate TextField for 'Bio'
                    buildTextField(
                      label: 'Bio',
                      hintText: 'Add a short bio',
                      controller: bioController,
                      isEditing: isEditingBio,
                      onEditToggle: () {
                        setState(() {
                          isEditingBio = !isEditingBio;
                        });
                      },
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Links',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    // Separate TextField for 'Instagram'
                    buildTextField(
                      label: 'Instagram',
                      hintText: 'Add profile URL',
                      controller: instagramController,
                      isEditing: isEditingInstagram,
                      onEditToggle: () {
                        setState(() {
                          isEditingInstagram = !isEditingInstagram;
                        });
                      },
                    ),
                    // Separate TextField for 'Facebook'
                    buildTextField(
                      label: 'Facebook',
                      hintText: 'Add profile URL',
                      controller: facebookController,
                      isEditing: isEditingFacebook,
                      onEditToggle: () {
                        setState(() {
                          isEditingFacebook = !isEditingFacebook;
                        });
                      },
                    ),
                    // Separate TextField for 'Twitter'
                    buildTextField(
                      label: 'Twitter',
                      hintText: 'Add profile URL',
                      controller: twitterController,
                      isEditing: isEditingTwitter,
                      onEditToggle: () {
                        setState(() {
                          isEditingTwitter = !isEditingTwitter;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Custom method for building the TextFields for each profile field
  Widget buildTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditToggle,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.0),
      padding: EdgeInsets.symmetric(horizontal: 14.0),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 16.0),
          ),
          Row(
            children: [
              isEditing
                  ? Container(
                      width: 150,
                      child: TextField(
                        controller: controller,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16.0,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          fillColor: Color(0xFF1C1C1E),
                        ),
                        cursorColor: Colors.white54,
                        textAlignVertical: TextAlignVertical.center,
                        textInputAction: TextInputAction.done,
                      ),
                    )
                  : Container(
                      width: 150,
                      child: Text(
                        controller.text.isNotEmpty ? controller.text : hintText,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
              SizedBox(width: 5),
              IconButton(
                icon: Icon(isEditing ? Icons.check : FontAwesomeIcons.edit,
                    color: Colors.blue, size: 18),
                onPressed: onEditToggle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// Full screen image view screen
class FullScreenImage extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;

  const FullScreenImage({super.key, this.imageUrl, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: imageFile != null
              ? Image.file(imageFile!)
              : imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(imageUrl!)
              : Text(
            'No image available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
