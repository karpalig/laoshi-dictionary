import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/dictionary_provider.dart';
import '../widgets/glass_card.dart';
import 'forms/add_example_form.dart';
import 'forms/edit_word_form.dart';

class WordDetailScreen extends StatelessWidget {
  final Word word;

  const WordDetailScreen({super.key, required this.word});

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
                                builder: (context) => EditWordForm(word: word),
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
                            provider.deleteWord(word.id);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Word main card
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  word.chinese,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  word.isFavorite ? Icons.star : Icons.star_border,
                                  color: word.isFavorite ? Colors.yellow : Colors.grey,
                                  size: 28,
                                ),
                                onPressed: () => provider.toggleFavorite(word),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            word.pinyin,
                            style: TextStyle(
                              fontSize: 20,
                              color: const Color(0xFF00CCFF).withOpacity(0.9),
                            ),
                          ),
                          const Divider(height: 24, color: Colors.white24),
                          Text(
                            word.russian,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                          if (word.hskLevel > 0) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'HSK ${word.hskLevel}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Examples section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Примеры использования',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF00CCFF)),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => AddExampleForm(wordId: word.id),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    FutureBuilder(
                      future: provider.getExamplesByWord(word.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return GlassCard(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.format_quote,
                                  size: 30,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Нет примеров',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final examples = snapshot.data!;
                        return Column(
                          children: examples
                              .map((example) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.format_quote,
                                                size: 14,
                                                color: const Color(0xFF00CCFF)
                                                    .withOpacity(0.7),
                                              ),
                                              const Spacer(),
                                              PopupMenuButton(
                                                icon: Icon(
                                                  Icons.more_horiz,
                                                  color: Colors.white.withOpacity(0.6),
                                                  size: 20,
                                                ),
                                                itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    child: const Text('Удалить'),
                                                    onTap: () {
                                                      provider.deleteExample(example.id);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            example.chineseSentence,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            example.pinyinSentence,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: const Color(0xFF00CCFF)
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            example.russianTranslation,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white.withOpacity(0.85),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
