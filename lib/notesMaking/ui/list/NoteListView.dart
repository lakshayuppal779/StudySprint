import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/Note.cubit.dart';
import '../../models/Group.model.dart';
import '../../models/Note.model.dart';
import '../cards/NoteCard.dart';
import '../views/NoteCreationPage.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

// ignore: must_be_immutable
class NoteListView extends StatefulWidget {
  String query = '';
  Group? groupQuery;

  final Function(Note)? onLongPress;

  NoteListView({
    Key? key,
    this.query = '',
    this.groupQuery,
    this.onLongPress,
  }) : super(key: key);

  @override
  _NoteListViewState createState() => _NoteListViewState();
}

class _NoteListViewState extends State<NoteListView> {

  @override
  Widget build(BuildContext context) {
    
    return BlocBuilder<NoteCubit, List<Note>>(
      builder: (context, notes) {
        notes = notes.reversed.toList();

        if (widget.query.isNotEmpty) {
          notes = notes.where((note) {
            return note.title.toLowerCase().contains(widget.query.toLowerCase()) ||
                note.description.toLowerCase().contains(widget.query.toLowerCase()) ||
                note.content.toLowerCase().contains(widget.query.toLowerCase());
          }).toList();
        }

        // look at id of group in the list of groups
        if (widget.groupQuery != null) {
          // ignore: unnecessary_null_comparison
          List<String> groupIds = widget.groupQuery!.id != null ? [widget.groupQuery!.id] : [];
          notes = notes.where((note) {
            List<String> noteGroupIds = note.groups.map((group) => group.id).toList();
            return noteGroupIds.any((noteGroupId) => groupIds.contains(noteGroupId));
          }).toList();
        }
        

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: notes.isEmpty
              ? const Center(child: Text('No notes available!',style: TextStyle(fontSize: 20,color: Colors.grey,fontWeight: FontWeight.w500),))
              : MasonryGridView.count(
                  crossAxisCount: 2,
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return NoteCard(
                      note: note,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => NoteCreationPage(note: note)));
                      },
                      onLongPress: widget.onLongPress != null ? () {
                        widget.onLongPress!(note);
                      } : null,
                      color: note.color,
                    );
                  },
            
                ),
        );
      },
    );
  }
}
