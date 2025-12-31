import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dictionary_provider.dart';
import '../../widgets/glass_card.dart';

class AddWordForm extends StatefulWidget {
  final String dictionaryId;

  const AddWordForm({super.key, required this.dictionaryId});

  @override
  State<AddWordForm> createState() => _AddWordFormState();
}

class _AddWordFormState extends State<AddWordForm> {
  final _chineseController = TextEditingController();
  final _pinyinController = TextEditingController();
  final _russianController = TextEditingController();
  int _hskLevel = 0;

  @override
  void dispose() {
    _chineseController.dispose();
    _pinyinController.dispose();
    _russianController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D0D1A),
            const Color(0xFF1A0D1A),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Новое слово',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Preview
              if (_chineseController.text.isNotEmpty ||
                  _pinyinController.text.isNotEmpty ||
                  _russianController.text.isNotEmpty)
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _chineseController.text.isEmpty
                            ? '汉字'
                            : _chineseController.text,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pinyinController.text.isEmpty
                            ? 'pinyin'
                            : _pinyinController.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF00CCFF).withOpacity(0.9),
                        ),
                      ),
                      if (_russianController.text.isNotEmpty) ...[
                        const Divider(height: 24, color: Colors.white24),
                        Text(
                          _russianController.text,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ],
                      if (_hskLevel > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'HSK $_hskLevel',
                            style: const TextStyle(
                              fontSize: 12,
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
              
              GlassTextField(
                hint: '汉字 (китайские иероглифы)',
                controller: _chineseController,
                prefixIcon: Icons.translate,
              ),
              const SizedBox(height: 16),
              
              GlassTextField(
                hint: 'Pinyin (пиньинь, используйте ni3 для nǐ)',
                controller: _pinyinController,
                prefixIcon: Icons.text_fields,
              ),
              const SizedBox(height: 16),
              
              GlassTextField(
                hint: 'Перевод на русский',
                controller: _russianController,
                prefixIcon: Icons.language,
              ),
              const SizedBox(height: 16),
              
              // HSK Level
              const Text(
                'Уровень HSK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: List.generate(7, (index) {
                  final level = index;
                  final isSelected = level == _hskLevel;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _hskLevel = level;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.purple.withOpacity(0.6)
                              : Colors.transparent,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            level == 0 ? '—' : '$level',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  label: 'Добавить слово',
                  icon: Icons.add_circle,
                  onPressed: _chineseController.text.isEmpty ||
                          _pinyinController.text.isEmpty ||
                          _russianController.text.isEmpty
                      ? () {}
                      : () {
                          final provider = Provider.of<DictionaryProvider>(
                            context,
                            listen: false,
                          );
                          provider.createWord(
                            chinese: _chineseController.text,
                            pinyin: _pinyinController.text,
                            russian: _russianController.text,
                            dictionaryId: widget.dictionaryId,
                            hskLevel: _hskLevel,
                          );
                          Navigator.pop(context);
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
