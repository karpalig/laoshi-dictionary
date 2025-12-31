import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../widgets/word_card.dart';
import 'word_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        final favoriteWords = provider.favoriteWords;

        return SafeArea(
          child: Column(
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Избранное',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: favoriteWords.isEmpty
                    ? _buildEmptyState()
                    : _buildFavoritesList(provider, favoriteWords),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star_border,
            size: 60,
            color: Colors.yellow,
          ),
          const SizedBox(height: 16),
          const Text(
            'Нет избранных слов',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте слова в избранное',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(DictionaryProvider provider, List favoriteWords) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: favoriteWords.length,
      itemBuilder: (context, index) {
        final word = favoriteWords[index];
        return Padding(
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
        );
      },
    );
  }
}
