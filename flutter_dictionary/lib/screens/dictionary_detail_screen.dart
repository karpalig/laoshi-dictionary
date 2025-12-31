import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dictionary.dart';
import '../providers/dictionary_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/word_card.dart';
import '../utils/color_helper.dart';
import 'forms/add_word_form.dart';
import 'forms/edit_dictionary_form.dart';
import 'word_detail_screen.dart';

class DictionaryDetailScreen extends StatelessWidget {
  final Dictionary dictionary;

  const DictionaryDetailScreen({super.key, required this.dictionary});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DictionaryProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0D0D1A),
              const Color(0xFF1A0D1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF00CCFF)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF00CCFF)),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              AddWordForm(dictionaryId: dictionary.id),
                        );
                      },
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_horiz, color: Color(0xFF00CCFF)),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 12),
                              Text('Редактировать'),
                            ],
                          ),
                          onTap: () {
                            Future.delayed(Duration.zero, () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    EditDictionaryForm(dictionary: dictionary),
                              );
                            });
                          },
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Удалить', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          onTap: () {
                            provider.deleteDictionary(dictionary.id);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dictionary header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorHelper.getColor(dictionary.color),
                        ),
                        child: const Icon(
                          Icons.book,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dictionary.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (dictionary.description != null &&
                                dictionary.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                dictionary.description!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Words list
              Expanded(
                child: FutureBuilder(
                  future: provider.getWordsByDictionary(dictionary.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final words = snapshot.data!;

                    if (words.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 60,
                              color: Colors.white.withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет слов',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: words.length,
                      itemBuilder: (context, index) {
                        final word = words[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: WordCard(
                            word: word,
                            dictionary: dictionary,
                            onTap: () {
                              provider.updateLastAccessed(word);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WordDetailScreen(word: word),
                                ),
                              );
                            },
                            onFavorite: () => provider.toggleFavorite(word),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
