import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/localization/localization.dart';
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
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            context.loc('no_data'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final text =
                  '''
${entry.emoji} ${context.loc('mood_entry_share_title')}
${DateFormat('dd.MM.yyyy HH:mm').format(entry.dateTime)}
${context.loc('category')}: ${entry.category}
${context.loc('reason')}: ${entry.reason}
''';
              await SharePlus.instance.share(ShareParams(text: text.trim()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEntryScreen(entryToEdit: entry),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final moodViewModel = context.read<MoodViewModel>();
              final navigator = Navigator.of(context);
              final deleteTitle = context.loc('delete_entry_title');
              final deleteMessage = context.loc('delete_entry_message');
              final cancelText = context.loc('cancel');
              final deleteText = context.loc('delete');

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(deleteTitle),
                  content: Text(deleteMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(cancelText),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(deleteText),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              await moodViewModel.deleteMood(entry.id!);
              if (context.mounted) {
                navigator.pop();
              }
            },
          ),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                ),
                child: Text(entry.emoji, style: const TextStyle(fontSize: 80)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              DateFormat('dd MMMM yyyy, HH:mm').format(entry.dateTime),
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.category,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (entry.keywords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.keywords
                    .map(
                      (k) => Chip(
                        label: Text(k),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: entry.imageUrl!.startsWith('http')
                      ? Image.network(
                          entry.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Colors.black12,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        )
                      : Image.file(
                          File(entry.imageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Colors.black12,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                ),
              ),
            ],
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
