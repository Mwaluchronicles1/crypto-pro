import 'package:flutter/material.dart';

class HistoryList extends StatelessWidget {
  final List<Map<String, String>> history;

  const HistoryList({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              history[index]['title'] ?? '',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              history[index]['status'] ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Icon(
              history[index]['status'] == 'Verified'
                  ? Icons.check_circle
                  : Icons.error,
              color: history[index]['status'] == 'Verified'
                  ? Colors.green
                  : Colors.red,
            ),
          ),
        );
      },
    );
  }
}