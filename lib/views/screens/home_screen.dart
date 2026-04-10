import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/architecture/view_state.dart';
import '../../core/localization/localization.dart';
import '../../viewmodels/mood_view_model.dart';
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
          const SliverToBoxAdapter(child: QuoteWidget()),
          const SliverToBoxAdapter(child: _SearchAndFilterPanel()),
          const SliverToBoxAdapter(child: _StatsPanel()),
          Consumer<MoodViewModel>(
            builder: (context, provider, child) {
              return switch (provider.moodsState) {
                Initial() || Loading() => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                Error(message: final msg) => SliverFillRemaining(
                  child: Center(child: Text(msg)),
                ),
                Success() => _buildContent(context, provider),
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

  Widget _buildContent(BuildContext context, MoodViewModel provider) {
    final entries = provider.visibleMoods;

    if (entries.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bubble_chart_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                context.loc('no_data'),
                style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final entry = entries[index];
          return MoodCard(
            entry: entry,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailScreen(entryId: entry.id!),
              ),
            ),
          );
        }, childCount: entries.length),
      ),
    );
  }
}

class _SearchAndFilterPanel extends StatefulWidget {
  const _SearchAndFilterPanel();

  @override
  State<_SearchAndFilterPanel> createState() => _SearchAndFilterPanelState();
}

class _SearchAndFilterPanelState extends State<_SearchAndFilterPanel> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodViewModel>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: provider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: context.loc('search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      key: ValueKey<String?>(
                        provider.selectedCategory,
                      ),
                      initialValue: provider.selectedCategory,
                      decoration: InputDecoration(
                        labelText: context.loc('category'),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.25),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(context.loc('all_categories')),
                        ),
                        ...provider.availableCategories.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c,
                            child: Text(c),
                          ),
                        ),
                      ],
                      onChanged: provider.setSelectedCategory,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<MoodSortOption>(
                      key: ValueKey<MoodSortOption>(
                        provider.sortOption,
                      ),
                      initialValue: provider.sortOption,
                      decoration: InputDecoration(
                        labelText: context.loc('sort'),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.25),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: MoodSortOption.newestFirst,
                          child: Text(context.loc('newest_first')),
                        ),
                        DropdownMenuItem(
                          value: MoodSortOption.oldestFirst,
                          child: Text(context.loc('oldest_first')),
                        ),
                        DropdownMenuItem(
                          value: MoodSortOption.reasonAsc,
                          child: Text(context.loc('reason_az')),
                        ),
                        DropdownMenuItem(
                          value: MoodSortOption.reasonDesc,
                          child: Text(context.loc('reason_za')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) provider.setSortOption(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(now.year - 5),
                          lastDate: DateTime(now.year + 1),
                          initialDateRange: provider.selectedDateRange,
                        );
                        provider.setDateRange(range);
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        provider.selectedDateRange == null
                            ? context.loc('date_range')
                            : '${provider.selectedDateRange!.start.day}.${provider.selectedDateRange!.start.month} - ${provider.selectedDateRange!.end.day}.${provider.selectedDateRange!.end.month}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    onPressed: () {
                      _searchController.clear();
                      provider.clearFilters();
                    },
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    tooltip: context.loc('clear_filters'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
