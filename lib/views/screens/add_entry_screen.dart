import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/localization/localization.dart';
import '../../data/models/mood_entry.dart';
import '../../viewmodels/mood_view_model.dart';

class AddEntryScreen extends StatefulWidget {
  final MoodEntry? entryToEdit;

  const AddEntryScreen({super.key, this.entryToEdit});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final List<String> _emojis = [
    '\u{1F929}',
    '\u{1F60A}',
    '\u{1F973}',
    '\u{1F970}',
    '\u{1F60E}',
    '\u{1F610}',
    '\u{1F914}',
    '\u{1F634}',
    '\u{1FAE0}',
    '\u{1F9D8}',
    '\u{1F622}',
    '\u{1F621}',
    '\u{1F631}',
    '\u{1F630}',
    '\u{1F922}',
  ];

  final List<String> _categories = [
    'Work',
    'Study',
    'Health',
    'Family',
    'Friends',
    'Hobby',
    'Travel',
    'Other',
  ];

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late String _selectedEmoji;
  late String _selectedCategory;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.entryToEdit?.emoji ?? _emojis[1];
    _selectedCategory = widget.entryToEdit?.category ?? _categories.first;
    _reasonController.text = widget.entryToEdit?.reason ?? '';
    _keywordsController.text = widget.entryToEdit?.keywords.join(', ') ?? '';
    _imagePath = widget.entryToEdit?.imageUrl;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.loc('add_entry')),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: _emojis.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return InkWell(
                    onTap: () => setState(() => _selectedEmoji = emoji),
                    borderRadius: BorderRadius.circular(50),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: context.loc('category'),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keywordsController,
                decoration: InputDecoration(
                  labelText: context.loc('keywords_hint'),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(context.loc('select_image')),
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 180,
                    child: _imagePath!.startsWith('http')
                        ? Image.network(_imagePath!, fit: BoxFit.cover)
                        : Image.file(File(_imagePath!), fit: BoxFit.cover),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLength: 500,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: context.loc('reason'),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(
                  context.loc('save'),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null || !mounted) return;

    setState(() {
      _imagePath = image.path;
    });
  }

  Future<void> _save() async {
    if (_reasonController.text.trim().isEmpty) return;

    final keywords = _keywordsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final entry = MoodEntry(
      id: widget.entryToEdit?.id,
      remoteId: widget.entryToEdit?.remoteId,
      emoji: _selectedEmoji,
      reason: _reasonController.text.trim(),
      category: _selectedCategory,
      keywords: keywords,
      imageUrl: _imagePath,
      dateTime: widget.entryToEdit?.dateTime ?? DateTime.now(),
    );

    if (widget.entryToEdit == null) {
      await context.read<MoodViewModel>().addMood(entry);
    } else {
      await context.read<MoodViewModel>().updateMood(entry);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }
}
