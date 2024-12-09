import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class CompletedPlannersScreen extends StatefulWidget {
  @override
  State<CompletedPlannersScreen> createState() => _CompletedPlannersScreenState();
}

class _CompletedPlannersScreenState extends State<CompletedPlannersScreen> {
  bool isSelectionMode = false;
  final ValueNotifier<Set<String>> selectedPlannerIds = ValueNotifier({});

  void toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      selectedPlannerIds.value.clear();
    });
  }

  void togglePlannerSelection(String plannerId) {
    final updatedSet = Set<String>.from(selectedPlannerIds.value); // Create a new set
    if (updatedSet.contains(plannerId)) {
      updatedSet.remove(plannerId);
    } else {
      updatedSet.add(plannerId);
    }
    selectedPlannerIds.value = updatedSet; // Assign the new set to notify listeners
    if (updatedSet.isEmpty) {
      setState(() => isSelectionMode = false); // Exit selection mode if none selected
    }
  }

  void deleteSelectedPlanners() async {
    final batch = FirebaseFirestore.instance.batch();
    for (String plannerId in selectedPlannerIds.value) {
      batch.delete(FirebaseFirestore.instance.collection('planners').doc(plannerId));
    }
    await batch.commit();
    toggleSelectionMode();
  }

  Future<void> deleteAllCompletedPlanners() async {
    final completedPlanners = await FirebaseFirestore.instance
        .collection('planners')
        .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .where('status', isEqualTo: 'completed')
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in completedPlanners.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    Fluttertoast.showToast(
      msg: "Planners deleted successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Icon and color helper functions based on status
  IconData _getStatusIcon(String status) => status == 'completed' ? Icons.check_circle : Icons.schedule;
  Color _getStatusColor(String status) => status == 'completed' ? Colors.green : Colors.blueAccent;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return Center(child: Text('User not logged in'));

    return Scaffold(
      backgroundColor: Color(0xFF1C1C1E),
      appBar: AppBar(
        title: ValueListenableBuilder<Set<String>>(
          valueListenable: selectedPlannerIds,
          builder: (context, selectedIds, child) {
            return Text(
              isSelectionMode
                  ? '${selectedIds.length} selected'
                  : 'Completed Planners',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1C1C1E),
        leading: IconButton(
          icon: Icon(isSelectionMode ? Icons.close : Icons.arrow_back, color: Colors.white),
          onPressed: isSelectionMode ? toggleSelectionMode : () => Navigator.pop(context),
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: deleteSelectedPlanners,
            ),
          if(!isSelectionMode)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            color: Color(0xFF2C2C2E),
            onSelected: (value) {
              if (value == 'clear_all') {
                deleteAllCompletedPlanners();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear All',style: TextStyle(color: Colors.white),),
              ),
            ],
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('planners')
            .where('uid', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .orderBy('calendar', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No completed planners yet',style: TextStyle(fontSize: 18,
              color: Colors.grey,fontWeight: FontWeight.w500),));
          }

          final plannerDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: plannerDocs.length,
            itemBuilder: (context, index) {
              var plannerData = plannerDocs[index].data() as Map<String, dynamic>;
              String plannerId = plannerDocs[index].id;
              DateTime? dueDateTime = (plannerData['calendar'] as Timestamp?)?.toDate();
              String formattedDueDateTime = dueDateTime != null
                  ? DateFormat('dd/MM/yyyy hh:mm a').format(dueDateTime)
                  : 'No due date';

              return ValueListenableBuilder<Set<String>>(
                valueListenable: selectedPlannerIds,
                builder: (context, selectedIds, _) {
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
                    },
                    child: Card(
                      color: isSelected ? Colors.blueGrey : Color(0xFF2C2C2E),
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(
                          plannerData['lessonName'],
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "Type: ${plannerData['type']}\nDue Date: $formattedDueDateTime",
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: Icon(
                          _getStatusIcon(plannerData['status']),
                          color: _getStatusColor(plannerData['status']),
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
