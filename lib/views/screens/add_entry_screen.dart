import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/mood_entry.dart';
import '../../viewmodels/mood_view_model.dart';
import '../../core/localization/localization.dart';

class AddEntryScreen extends StatefulWidget {
  final MoodEntry? entryToEdit; 
  const AddEntryScreen({super.key, this.entryToEdit});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {

  final List<String> _emojis = [
    '🤩', '😊', '🥳', '🥰', '😎', 
    '😐', '🤔', '😴', '🫠', '🧘', 
    '😢', '😡', '😱', '😰', '🤢'  
  ];

  late String _selectedEmoji;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
   
    _selectedEmoji = widget.entryToEdit?.emoji ?? _emojis[1];
    _reasonController.text = widget.entryToEdit?.reason ?? '';
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
                spacing: 15, 
                runSpacing: 15, 
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
                            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              
              TextField(
                controller: _reasonController,
                maxLength: 500, 
                maxLines: 5,   
                decoration: InputDecoration(
                  labelText: context.loc('reason'),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(context.loc('save'), style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_reasonController.text.trim().isEmpty) return;

    final entry = MoodEntry(
      id: widget.entryToEdit?.id,
      emoji: _selectedEmoji,
      reason: _reasonController.text.trim(),
      dateTime: widget.entryToEdit?.dateTime ?? DateTime.now(),
    );

    if (widget.entryToEdit == null) {
      context.read<MoodViewModel>().addMood(entry);
    } else {
      context.read<MoodViewModel>().updateMood(entry);
    }
    Navigator.pop(context);
  }
}