import 'package:flutter/material.dart';
import '../models/word.dart';
import '../models/dictionary.dart';
import 'glass_card.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final Dictionary? dictionary;
  final int exampleCount;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const WordCard({
    super.key,
    required this.word,
    this.dictionary,
    this.exampleCount = 0,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.chinese,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      word.pinyin,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF00CCFF).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  word.isFavorite ? Icons.star : Icons.star_border,
                  color: word.isFavorite ? Colors.yellow : Colors.grey,
                  size: 24,
                ),
                onPressed: onFavorite,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Russian translation
          Text(
            word.russian,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          
          // Footer row with metadata
          Row(
            children: [
              if (word.hskLevel > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'HSK ${word.hskLevel}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              if (exampleCount > 0) ...[
                Row(
                  children: [
                    const Icon(Icons.format_quote, size: 14, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      '$exampleCount',
                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              
              const Spacer(),
              
              if (dictionary != null)
                Text(
                  dictionary!.name,
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
