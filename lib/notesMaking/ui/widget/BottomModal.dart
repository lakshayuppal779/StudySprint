import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BottomModal extends StatelessWidget {
  final DateTime createdAt;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  final List<Widget> children;

  const BottomModal({
    super.key,
    required this.createdAt,
    required this.onDelete,
    required this.onEdit,
    this.children = const [],
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd – kk:mm');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.grey),
            title: const Text('Edit', style: TextStyle(color: Colors.grey)),
            onTap: onEdit,
          ),
          const Divider(),
          ...children,
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.grey)),
            onTap: onDelete,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Created At: ${dateFormat.format(createdAt)}',
              style: const TextStyle(fontStyle: FontStyle.italic,color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
