import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/word_card.dart';
import 'word_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        final words = _searchController.text.isEmpty
            ? provider.allWords.take(10).toList()
            : provider.searchResults;

        return SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Поиск',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassTextField(
                      hint: '汉字, pinyin, русский...',
                      controller: _searchController,
                      prefixIcon: Icons.search,
                      keyboardType: TextInputType.text,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _searchController.text.isEmpty
                    ? _buildRecentWords(provider, words)
                    : _buildSearchResults(provider, words),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentWords(DictionaryProvider provider, List words) {
    if (words.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book_outlined,
              size: 60,
              color: Color(0xFF00CCFF),
            ),
            const SizedBox(height: 16),
            const Text(
              'Словарь пуст',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Добавьте слова в словарь',
              style: TextStyle(fontSize: 16, color: Colors.white60),
            ),
            const SizedBox(height: 24),
            GlassButton(
              label: 'Загрузить примеры',
              onPressed: () => provider.createSampleData(),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Недавние слова',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        ...words.map((word) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: WordCard(
                word: word,
                dictionary: provider.dictionaries
                    .where((d) => d.id == word.dictionaryId)
                    .firstOrNull,
                onTap: () {
                  provider.updateLastAccessed(word);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WordDetailScreen(word: word),
                    ),
                  );
                },
                onFavorite: () => provider.toggleFavorite(word),
              ),
            )),
      ],
    );
  }

  Widget _buildSearchResults(DictionaryProvider provider, List words) {
    // Trigger search on every text change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.setSearchQuery(_searchController.text);
    });

    if (words.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 50,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Ничего не найдено',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте другой запрос',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Результаты поиска (${words.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
        ...words.map((word) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: WordCard(
                word: word,
                dictionary: provider.dictionaries
                    .where((d) => d.id == word.dictionaryId)
                    .firstOrNull,
                onTap: () {
                  provider.updateLastAccessed(word);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WordDetailScreen(word: word),
                    ),
                  );
                },
                onFavorite: () => provider.toggleFavorite(word),
              ),
            )),
      ],
    );
  }
}
