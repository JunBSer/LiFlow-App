import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
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
  String? _locationTag;
  bool _isPickingImage = false;
  bool _isResolvingLocation = false;
  bool _isSaving = false;

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isPickingImage ? null : _pickImageFromGallery,
                    icon: _isPickingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_library_outlined),
                    label: Text(context.loc('select_image')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isPickingImage ? null : _pickImageFromCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(context.loc('take_photo')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isResolvingLocation ? null : _attachCurrentLocation,
                icon: _isResolvingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: Text(
                  _locationTag == null
                      ? context.loc('attach_location')
                      : '${context.loc('location')}: $_locationTag',
                ),
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 180,
                    child: _imagePath!.startsWith('http')
                        ? Image.network(
                            _imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: Colors.black12,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          )
                        : Image.file(
                            File(_imagePath!),
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
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
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

  Future<void> _pickImageFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImageFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() {
      _isPickingImage = true;
    });

    try {
      final image = await _picker.pickImage(source: source, imageQuality: 80);
      if (image == null || !mounted) return;

      setState(() {
        _imagePath = image.path;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code != 'already_active') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image pick failed: ${e.message ?? e.code}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  Future<void> _attachCurrentLocation() async {
    if (_isResolvingLocation) return;
    final locationServicesDisabled = context.loc('location_services_disabled');
    final locationPermissionDenied = context.loc('location_permission_denied');
    setState(() {
      _isResolvingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(locationServicesDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(locationPermissionDenied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      if (!mounted) return;
      setState(() {
        _locationTag =
            '${position.latitude.toStringAsFixed(4)} ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving || _reasonController.text.trim().isEmpty) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final keywords = _keywordsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (_locationTag != null) {
        keywords.add(_locationTag!);
      }

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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
