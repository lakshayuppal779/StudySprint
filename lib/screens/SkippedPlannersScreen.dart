import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SkippedPlannersScreen extends StatefulWidget {
  @override
  State<SkippedPlannersScreen> createState() => _SkippedPlannersScreenState();
}

class _SkippedPlannersScreenState extends State<SkippedPlannersScreen> {
  bool isSelectionMode = false;
  final ValueNotifier<Set<String>> selectedPlannerIds = ValueNotifier({});

  void toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      selectedPlannerIds.value.clear();
    });
  }

  void togglePlannerSelection(String plannerId) {
    final updatedSet = Set<String>.from(selectedPlannerIds.value);
    if (updatedSet.contains(plannerId)) {
      updatedSet.remove(plannerId);
    } else {
      updatedSet.add(plannerId);
    }
    selectedPlannerIds.value = updatedSet;
    if (updatedSet.isEmpty) {
      setState(() => isSelectionMode = false);
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

  IconData _getStatusIcon(String status) => status == 'skipped' ? Icons.cancel : Icons.schedule;
  Color _getStatusColor(String status) => status == 'skipped' ? Colors.red : Colors.blueAccent;

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
                  : 'Skipped Planners',
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
        actions: isSelectionMode
            ? [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: deleteSelectedPlanners,
          ),
        ]
            : [],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('planners')
            .where('uid', isEqualTo: user.uid)
            .where('status', isEqualTo: 'skipped')
            .orderBy('calendar', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No skipped planners yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,fontWeight: FontWeight.w500
                ),
              ),
            );
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
