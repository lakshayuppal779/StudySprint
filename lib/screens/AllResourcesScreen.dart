import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show PreviewData;
import 'package:studyscheduler/screens/PlannerDetailScreen.dart';
import '../DataModel/Scdheduledatamodel.dart';

class AllResourcesScreen extends StatefulWidget {
  final EducationSchedule schedule;
  const AllResourcesScreen({super.key, required this.schedule});

  @override
  State<AllResourcesScreen> createState() => _AllResourcesScreenState();
}

class _AllResourcesScreenState extends State<AllResourcesScreen> {
  final Map<String, PreviewData> _previewDataCache = {};
  List<Map<String, dynamic>> _resources = [];
  bool _isLoading = true;

  /// Fetches all resources across all planners associated with the provided schedule.
  Future<void> _fetchPlannerData() async {
    try {
      final plannersSnapshot = await FirebaseFirestore.instance
          .collection('planners')
          .where('scheduleId', isEqualTo: widget.schedule.lessonName)
          .get();

      final resourcesList = <Map<String, dynamic>>[];
      for (var plannerDoc in plannersSnapshot.docs) {
        final data = plannerDoc.data();
        final resources = (data['resources'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();

        resourcesList.addAll(resources);
      }

      // Filter valid link previews
      for (var resource in resourcesList) {
        if (resource['type'] == 'link' && _isURL(resource['data'])) {
          final previewData = await getPreviewData(resource['data']);
          _previewDataCache[resource['data']] = previewData;
        }
      }

      setState(() {
        _resources = resourcesList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching planner data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Helper method to check if the given string is a valid URL.
  bool _isURL(String url) {
    final urlPattern =
        r'^(http(s)?://)?([\w-]+(\.[\w-]+)+)([/\w-]*)?(\?[^\s]*)?$';
    final regex = RegExp(urlPattern);
    return regex.hasMatch(url);
  }

  /// Deletes a specific resource from Firestore
  Future<void> deleteResource(String resource) async {
    final planners = await FirebaseFirestore.instance
        .collection('planners')
        .where('scheduleId', isEqualTo: widget.schedule.lessonName)
        .get();

    for (final doc in planners.docs) {
      final resources = List<String>.from(doc['resources'] ?? []);
      if (resources.contains(resource)) {
        await FirebaseFirestore.instance
            .collection('planners')
            .doc(doc.id)
            .update({
          'resources': FieldValue.arrayRemove([resource]),
        });
        break;
      }
    }
    setState(() {
      _resources.removeWhere((r) => r['data'] == resource);
    });
  }

  /// Determines the appropriate icon for displaying the resource type.
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
  @override
  void initState() {
    super.initState();
    _fetchPlannerData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(
          widget.schedule.lessonName,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _resources.isEmpty
              ? Center(
                  child: Text(
                    'No resources found',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Container(
                  color: Color(0xFF1C1C1E),
                  child: Column(
                    children: [
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
                                await deleteResource(resource['data']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Resource deleted')),
                                );
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
                                      // await _openPDF(data);
                                    } else if (type == 'link' && _isURL(data)) {
                                      // await _launchURL(data);
                                    }
                                  },
                                  title: type == 'image'
                                      ? Text(
                                          resource['name'] ??
                                              'Unnamed Resource',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
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
      backgroundColor: const Color(0xFF1C1C1E),
    );
  }
}
