import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:studyscheduler/notesMaking/ui/views/HomePage.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:file_picker/file_picker.dart';

class PlannerDetailScreen extends StatefulWidget {
  final String plannerId;
  const PlannerDetailScreen({super.key, required this.plannerId});
  @override
  State<PlannerDetailScreen> createState() => _PlannerDetailScreenState();
}

class _PlannerDetailScreenState extends State<PlannerDetailScreen> {
  Map<String, PreviewData> _previewDataCache = {};
  List<Map<String, dynamic>> _resources = [];
  Map<String, dynamic> _plannerData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlannerData();
  }

  Future<void> _fetchPlannerData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('planners')
          .doc(widget.plannerId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final resources = (data['resources'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();

        for (var resource in resources) {
          if (resource['type'] == 'link' && _isURL(resource['data'])) {
            final previewData = await getPreviewData(resource['data']);
            _previewDataCache[resource['data']] = previewData;
          }
        }
        setState(() {
          _plannerData = data;
          _resources = resources;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching planner data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openPDF(String pdfUrl) async {
    try {
      if (await canLaunchUrlString(pdfUrl)) {
        await launchUrlString(pdfUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $pdfUrl';
      }
    } catch (e) {
      print("Error launching URL: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch URL: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF1C1C1E),
        title: Text(
          'Planner Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFF1C1C1E),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _plannerData.isEmpty
              ? Center(
                  child: Text(
                    'Planner not found',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Container(
                  color: Color(0xFF1C1C1E),
                  child: Column(
                    children: [
                      Card(
                        color: Color(0xFF2C2C2E),
                        margin: EdgeInsets.all(16),
                        child: ListTile(
                          title: Text(
                            _plannerData['lessonName'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Resources',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _resources.length,
                          itemBuilder: (context, index) {
                            Map<String, dynamic> resource = _resources[index];
                            String type = resource['type'];
                            String data = resource['data'];

                            return Dismissible(
                              key: Key(data),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerLeft,
                                padding: EdgeInsets.only(left: 16),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.only(right: 16),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (direction) async {
                                await FirebaseFirestore.instance
                                    .collection('planners')
                                    .doc(widget.plannerId)
                                    .update({
                                  'resources':
                                      FieldValue.arrayRemove([resource]),
                                });
                                Fluttertoast.showToast(
                                  msg: "Resource deleted",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.SNACKBAR,
                                  backgroundColor:
                                      Colors.redAccent.withOpacity(0.7),
                                  textColor: Colors.white,
                                  fontSize: 16.0,
                                );

                                setState(() {
                                  _resources.removeAt(index);
                                });
                              },
                              child: Card(
                                color: Color(0xFF2C2C2E),
                                margin: EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 16),
                                child: ListTile(
                                  onTap: () async {
                                    if (type == 'image') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FullScreenImage(imageUrl: data),
                                        ),
                                      );
                                    } else if (type == 'pdf') {
                                      await _openPDF(data);
                                    } else if (type == 'link' && _isURL(data)) {
                                      await _launchURL(data);
                                    }
                                  },
                                  title: type == 'image'
                                      ? Text(
                                    resource['name'] ?? 'Unnamed Resource',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                      : type == 'pdf'
                                          ? Text(
                                              'View PDF',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : type == 'link' && _isURL(data)
                                              ? LinkPreview(
                                                  text: data,
                                                  onPreviewDataFetched:
                                                      (previewData) {
                                                    setState(() {
                                                      _previewDataCache[data] =
                                                          previewData;
                                                    });
                                                  },
                                                  previewData:
                                                      _previewDataCache[data],
                                                  textStyle: TextStyle(
                                                    color: Colors.orangeAccent,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  metadataTextStyle: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                  metadataTitleStyle: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  padding: EdgeInsets.all(8),
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.8,
                                                )
                                              : Text(
                                                  data,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                  leading: Icon(
                                    _getResourceIcon(type),
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'uniqueHeroTag1', // Unique hero tag for the first FAB
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(),
                ),
              );
            },
            backgroundColor: Colors.green,
            shape: CircleBorder(),
            child: Icon(Icons.edit_note, color: Colors.white,size: 28,),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'uniqueHeroTag2', // Unique hero tag for the second FAB
            onPressed: () => _addResource(context, widget.plannerId),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: CircleBorder(),
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  bool _isURL(String resource) {
    final urlPattern =
        r'^(https?:\/\/)?([a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,})(\/\S*)?$';
    return RegExp(urlPattern).hasMatch(resource);
  }
  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      case 'text':
        return Icons.text_snippet;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }


  Future<void> _launchURL(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print("Error launching URL: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch URL: $e')),
      );
    }
  }

  void _addResource(BuildContext context, String plannerId) {
    String selectedType = '';
    final List<String> resourceTypes = ['PDF', 'Link', 'Image'];
    final TextEditingController nameController = TextEditingController();
    final TextEditingController linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF2C2C2E),
              title: Text('Add Resource', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType.isEmpty ? null : selectedType,
                      items: resourceTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type, style: TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value ?? '';
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Resource Type',
                        labelStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Color(0xFF2C2C2E),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orangeAccent),
                        ),
                      ),
                      dropdownColor: Color(0xFF2C2C2E),
                    ),
                    if (selectedType == 'Link')
                      TextField(
                        controller: linkController,
                        decoration: InputDecoration(
                          labelText: 'Enter Link',
                          labelStyle: TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Color(0xFF2C2C2E),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.orangeAccent),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.orangeAccent),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    if (selectedType == 'Image' || selectedType == 'PDF')
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Enter File Name',
                          labelStyle: TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Color(0xFF2C2C2E),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.orangeAccent),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.orangeAccent),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    if (selectedType == 'Image' || selectedType == 'PDF')
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              allowMultiple: true,
                              type: selectedType == 'Image'
                                  ? FileType.image
                                  : FileType.custom,
                              allowedExtensions:
                              selectedType == 'PDF' ? ['pdf'] : null,
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              String filePath = result.files.single.path!;
                              String fileType = selectedType.toLowerCase();
                              String fileName = nameController.text.trim();
                              if (fileName.isEmpty) {
                                Fluttertoast.showToast(
                                  msg: "File name cannot be empty!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                                return;
                              }
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: Color(0xFF2C2C2E),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text(
                                          "Uploading...",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );

                              try {
                                // Upload file to Firebase Storage
                                final storageRef = FirebaseStorage.instance
                                    .ref()
                                    .child('resources/$plannerId/$fileName');
                                await storageRef.putFile(File(filePath));

                                // Get the download URL
                                String downloadUrl =
                                await storageRef.getDownloadURL();

                                // Save resource details to Firestore
                                final newResource = {
                                  'type': fileType,
                                  'data': downloadUrl,
                                  'name': fileName,
                                };
                                await FirebaseFirestore.instance
                                    .collection('planners')
                                    .doc(plannerId)
                                    .update({
                                  'resources':
                                  FieldValue.arrayUnion([newResource]),
                                });
                                Fluttertoast.showToast(
                                  msg: "$selectedType uploaded successfully!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.SNACKBAR,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                );
                                Navigator.pop(context); // Close circular progress dialog
                                Navigator.pop(context); // Close add resource dialog
                                _fetchPlannerData();
                              } catch (e) {
                                print('File upload error: $e');
                                Fluttertoast.showToast(
                                  msg: "Failed to upload $selectedType",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                                Navigator.pop(context); // Close circular progress dialog
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                          ),
                          child: Text(
                            'Upload $selectedType',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedType == 'Link' && linkController.text.isNotEmpty) {
                      final resource = {
                        'type': 'link',
                        'data': linkController.text,
                      };
                      await FirebaseFirestore.instance
                          .collection('planners')
                          .doc(plannerId)
                          .update({
                        'resources': FieldValue.arrayUnion([resource]),
                      });
                      Fluttertoast.showToast(
                        msg: "Link added successfully",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.SNACKBAR,
                        backgroundColor: Colors.green.withOpacity(0.7),
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                      setState(() {
                        _resources.add(resource);
                        _fetchPlannerData();
                      });
                    } else {
                      Fluttertoast.showToast(
                        msg: "Please enter valid details",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.SNACKBAR,
                        backgroundColor: Colors.redAccent.withOpacity(0.7),
                        textColor: Colors.white,
                        fontSize: 16.0,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Add', style: TextStyle(color: Colors.orangeAccent)),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Hero(
            tag: imageUrl,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
