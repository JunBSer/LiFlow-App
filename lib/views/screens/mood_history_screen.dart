import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/architecture/view_state.dart';
import '../../core/localization/localization.dart';
import '../../viewmodels/mood_view_model.dart';
import '../widgets/mood_card.dart';
import 'add_entry_screen.dart';
import 'detail_screen.dart';

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.loc('history'))),
      body: RefreshIndicator(
        onRefresh: () => context.read<MoodViewModel>().loadMoods(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: _SearchAndFilterPanel()),
            Consumer<MoodViewModel>(
              builder: (context, provider, _) {
                return switch (provider.moodsState) {
                  Initial() || Loading() => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  Error(message: final msg) => SliverFillRemaining(
                    child: Center(child: Text(msg)),
                  ),
                  Success() => _buildList(context, provider),
                };
              },
            ),
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

  Widget _buildList(BuildContext context, MoodViewModel provider) {
    final entries = provider.visibleMoods;
    if (entries.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            context.loc('no_data'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
  bool _didSyncInitialQuery = false;

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
        if (!_didSyncInitialQuery && provider.searchQuery.isNotEmpty) {
          _searchController.text = provider.searchQuery;
          _didSyncInitialQuery = true;
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                      key: ValueKey<String?>(provider.selectedCategory),
                      initialValue: provider.selectedCategory,
                      isExpanded: true, 
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
                          child: Text(context.loc('all_categories'), 
                          overflow: TextOverflow.ellipsis),
                        ),
                        ...provider.availableCategories.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c,
                            child: Text(
                              c,
                              overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: provider.setSelectedCategory,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<MoodSortOption>(
                      key: ValueKey<MoodSortOption>(provider.sortOption),
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
                          child: Text(context.loc('newest_first'), overflow: TextOverflow.ellipsis,),
                        ),
                        DropdownMenuItem(
                          value: MoodSortOption.oldestFirst,
                          child: Text(context.loc('oldest_first'), overflow: TextOverflow.ellipsis,),
                        ),
                        DropdownMenuItem(
                          value: MoodSortOption.reasonAsc,
                          child: Text(context.loc('reason_az'), overflow: TextOverflow.ellipsis,),
                        ),
                        DropdownMenuItem(
                          value: MoodSortOption.reasonDesc,
                          child: Text(context.loc('reason_za'), overflow: TextOverflow.ellipsis,),
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

                            overflow: TextOverflow.ellipsis, 
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
