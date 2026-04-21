import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/localization.dart';
import '../../viewmodels/mood_view_model.dart';
import '../../viewmodels/quote_view_model.dart';
import '../widgets/quote_widget.dart';
import 'add_entry_screen.dart';
import 'detail_screen.dart';
import 'mood_history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<MoodViewModel>().loadMoods(),
            context.read<QuoteViewModel>().loadQuote(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
            const SliverToBoxAdapter(child: QuoteWidget()),
            const SliverToBoxAdapter(child: _StatsPanel()),
            const SliverToBoxAdapter(child: _InsightPanel()),
            const SliverToBoxAdapter(child: _QuickActionsPanel()),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
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

class _StatsPanel extends StatelessWidget {
  const _StatsPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodViewModel>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: context.loc('total'),
                    value: provider.totalEntries.toString(),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: context.loc('this_week'),
                    value: provider.entriesThisWeek.toString(),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: context.loc('top_category'),
                    value: provider.topCategory,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel();

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodViewModel>(
      builder: (context, provider, _) {
        final todayText = provider.hasTodayEntry
            ? context.loc('logged_today')
            : context.loc('not_logged_today');

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.55),
                  Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer.withValues(alpha: 0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Text(
                      '${context.loc('streak')}: ${provider.currentStreakDays}',
                    ),
                    Text('${context.loc('today_status')}: $todayText'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('${context.loc('mood_balance')}:')),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: provider.moodBalance,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(provider.moodBalance * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      provider.favoriteEmoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(context.loc('random_entry')),
                    IconButton(
                      onPressed: () {
                        final randomId = provider.randomEntryId;
                        if (randomId == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(entryId: randomId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shuffle),
                      tooltip: context.loc('random_entry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc('quick_actions'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MoodHistoryScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.history),
                  label: Text(context.loc('open_history')),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddEntryScreen()),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(context.loc('add_today_entry')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
