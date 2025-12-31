import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dictionary_provider.dart';
import '../widgets/glass_card.dart';
import '../utils/color_helper.dart';
import 'dictionary_detail_screen.dart';
import 'forms/add_dictionary_form.dart';

class DictionariesScreen extends StatelessWidget {
  const DictionariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DictionaryProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Словари',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 32),
                      color: const Color(0xFF00CCFF),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const AddDictionaryForm(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Dictionary list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.dictionaries.length,
                  itemBuilder: (context, index) {
                    final dictionary = provider.dictionaries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DictionaryCard(dictionary: dictionary),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DictionaryCard extends StatelessWidget {
  final dictionary;

  const _DictionaryCard({required this.dictionary});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DictionaryProvider>(context, listen: false);
    
    return GlassCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DictionaryDetailScreen(dictionary: dictionary),
          ),
        );
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Color circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorHelper.getColor(dictionary.color),
            ),
            child: const Icon(
              Icons.book,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Dictionary info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dictionary.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (dictionary.description != null &&
                    dictionary.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dictionary.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                FutureBuilder<List>(
                  future: provider.getWordsByDictionary(dictionary.id),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Text(
                      '$count слов',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Active toggle
          IconButton(
            icon: Icon(
              dictionary.isActive
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: dictionary.isActive ? Colors.green : Colors.grey,
              size: 24,
            ),
            onPressed: () {
              provider.toggleDictionaryActive(dictionary);
            },
          ),
        ],
      ),
    );
  }
}
