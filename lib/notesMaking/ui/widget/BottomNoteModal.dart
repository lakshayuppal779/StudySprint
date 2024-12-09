import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/Note.cubit.dart';
import '../../models/Note.model.dart';
import '../views/NoteCreationPage.dart';
import 'BottomModal.dart';
class BottomNoteModal extends StatelessWidget {
  final Note note;

  final List<Widget> children;

  const BottomNoteModal({
    super.key,
    required this.note,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {

    return BottomModal(
      createdAt: note.createdAt!,
      onDelete: () {
        Navigator.of(context).pop();
        // cubit delete note
        context.read<NoteCubit>().delete(note);
      },
      onEdit: () {
        Navigator.of(context).pop();
        // Go to the edit note page
        Navigator.push(context, MaterialPageRoute(builder: (context) => NoteCreationPage(note: note),));

      },
      children: children,
    );
  }
}

