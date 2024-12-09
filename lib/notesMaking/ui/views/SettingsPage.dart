import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../cubit/Note.cubit.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white
          ),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();

            // clear cubit data
            context.read<NoteCubit>().clear();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All data cleared'),
              ),
            );
          },
          child: const Text('Clear All Data'),
        ),
      ),
    );
  }
}
