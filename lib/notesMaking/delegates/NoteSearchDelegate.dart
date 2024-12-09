import 'package:flutter/material.dart';
import '../ui/list/NoteListView.dart';

class NoteSearchDelegate extends SearchDelegate<String> {
  final Color backgroundColor;
  final Color iconColor;

  NoteSearchDelegate({
    this.backgroundColor = Colors.white, // Default background color
    this.iconColor = Colors.black,      // Default icon color
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: iconColor),
        toolbarTextStyle: TextStyle(color: iconColor, fontSize: 18),
        titleTextStyle: TextStyle(color: iconColor, fontSize: 18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: iconColor.withOpacity(0.7)),
      ),
      textTheme: TextTheme(
        titleSmall:TextStyle(color: Colors.grey),
      ),
    );
  }


  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: iconColor),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: iconColor),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: NoteListView(
          query: query,
        ),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Text(
          'No Suggestions',
          style: TextStyle(color: iconColor.withOpacity(0.7),fontSize: 18),
        ),
      ),
    );
  }
}
