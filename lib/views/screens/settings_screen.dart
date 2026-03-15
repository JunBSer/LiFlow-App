import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../core/localization/localization.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc('settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(context.loc('dark_mode'), style: const TextStyle(fontSize: 18)),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: settings.isDarkMode,
                  onChanged: (val) => settings.toggleTheme(val),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const Icon(Icons.language),
                  title: Text(context.loc('language'), style: const TextStyle(fontSize: 18)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: settings.langCode,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: const [
                        DropdownMenuItem(value: 'ru', child: Text('Русский', style: TextStyle(fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      onChanged: (val) {
                        if (val != null) settings.setLanguage(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}