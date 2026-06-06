import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/portfolio_card.dart';
import '../utils/app_colors.dart';
import 'portfolio_detail_screen.dart';

class PortfolioListScreen extends ConsumerStatefulWidget {
  const PortfolioListScreen({super.key});

  @override
  ConsumerState<PortfolioListScreen> createState() => _PortfolioListScreenState();
}

class _PortfolioListScreenState extends ConsumerState<PortfolioListScreen> {
  String _searchQuery = '';
  String _selectedTag = '';
  String? _selectedRank;

  final List<String> _availableTags = [
    'Cyberpunk', 'Chibi', 'Fantasy', 'Cute', 'Action', 'Romance', 'Background', 'Character',
  ];

  final List<String> _availableRanks = ['S', 'A', 'B', 'C'];

  @override
  Widget build(BuildContext context) {
    final portfoliosAsync = ref.watch(portfolioListProvider);
    final authState = ref.watch(authProvider);
    final currentUserId = authState.userId;

    return portfoliosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (portfolios) {
        final filteredPortfolios = portfolios.where((portfolio) {
          final matchesSearch = _searchQuery.isEmpty ||
              portfolio.title.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesTag = _selectedTag.isEmpty ||
              portfolio.tags.contains(_selectedTag);
          final matchesRank = _selectedRank == null ||
              portfolio.rank == _selectedRank;
          return matchesSearch && matchesTag && matchesRank;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(portfolioListProvider.notifier).loadPortfolios();
          },
          child: CustomScrollView(
            slivers: [
              // Search & Filter
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari portofolio...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 45,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            const Text('Tag: ', style: TextStyle(fontSize: 11)),
                            FilterChip(
                              label: const Text('Semua', style: TextStyle(fontSize: 11)),
                              selected: _selectedTag.isEmpty,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedTag = '';
                                });
                              },
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            const SizedBox(width: 4),
                            ..._availableTags.map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: FilterChip(
                                  label: Text(tag, style: const TextStyle(fontSize: 11)),
                                  selected: _selectedTag == tag,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedTag = selected ? tag : '';
                                    });
                                  },
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                ),
                              );
                            }),
                            const SizedBox(width: 12),
                            const Text('Rank: ', style: TextStyle(fontSize: 11)),
                            ..._availableRanks.map((rank) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: FilterChip(
                                  label: Text(rank, style: const TextStyle(fontSize: 11)),
                                  selected: _selectedRank == rank,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedRank = selected ? rank : null;
                                    });
                                  },
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Grid Portfolio
              if (filteredPortfolios.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('Belum ada portofolio'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.55,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final portfolio = filteredPortfolios[index];
                        final isOwner = portfolio.userId == currentUserId;
                        
                        return PortfolioCard(
                          portfolio: portfolio,
                          isOwner: isOwner,
                          onTap: () async {
                            // Navigasi ke detail
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PortfolioDetailScreen(
                                  portfolio: portfolio,
                                ),
                              ),
                            );
                            // Refresh data setelah kembali dari detail
                            await ref.read(portfolioListProvider.notifier).loadPortfolios();
                          },
                          onEdit: null,
                          onDelete: null,
                        );
                      },
                      childCount: filteredPortfolios.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}