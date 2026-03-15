import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/mood_view_model.dart';
import 'add_entry_screen.dart';

class DetailScreen extends StatelessWidget {
  final int entryId;
  const DetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoodViewModel>();
    final entry = provider.getEntryById(entryId);

    if (entry == null) {
     return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddEntryScreen(entryToEdit: entry)));
          }),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
             context.read<MoodViewModel>().deleteMood(entry.id!);
            Navigator.pop(context);
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                ),
                child: Text(entry.emoji, style: const TextStyle(fontSize: 80)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              DateFormat('dd MMMM yyyy, HH:mm').format(entry.dateTime),
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                entry.reason,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}