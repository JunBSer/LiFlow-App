import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/mood_view_model.dart';
import '../../core/localization/localization.dart';
import '../../core/architecture/view_state.dart'; 
import '../widgets/mood_card.dart';
import '../widgets/quote_widget.dart'; 
import 'add_entry_screen.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
       
          SliverAppBar.large(
            title: Text(
              context.loc('tracker_feat'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),

         
          const SliverToBoxAdapter(
            child: QuoteWidget(), 
          ),

          
          Consumer<MoodViewModel>(
            builder: (context, provider, child) {
              return switch (provider.moodsState) {
                Initial() || Loading() => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                Error(message: final msg) => SliverFillRemaining(
                    child: Center(child: Text(msg)),
                  ),
                Success(data: final entries) => entries.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bubble_chart_outlined,
                                  size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                context.loc('no_data'),
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      )
                    
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final entry = entries[index];
                              return MoodCard(
                                entry: entry,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetailScreen(entryId: entry.id!),
                                  ),
                                ),
                              );
                            },
                            childCount: entries.length,
                          ),
                        ),
                      ),
              };
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEntryScreen()),
        ),
        icon: const Icon(Icons.add),
        label: Text(context.loc('add_entry')),
      ),
    );
  }
}