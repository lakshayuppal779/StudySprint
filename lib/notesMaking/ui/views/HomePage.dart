import 'package:flutter/material.dart';
import '../../delegates/NoteSearchDelegate.dart';
import '../list/NoteListView.dart';
import '../widget/BottomNoteModal.dart';
import 'NoteCreationPage.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        title: const Text(
          'Notes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NoteSearchDelegate(backgroundColor:Color(0xFF1C1C1E), iconColor: Colors.white,),
              );
            },
          ),
        ],
        backgroundColor: const Color(0xFF1C1C1E),
      ),
      body: Container(
        color: const Color(0xFF1C1C1E),
        child: Stack(
          children: [
            NoteListView(
              onLongPress: (note) {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF2C2C2E),
                  builder: (context) {
                    return BottomNoteModal(note: note);
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const NoteCreationPage()));
        },
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
