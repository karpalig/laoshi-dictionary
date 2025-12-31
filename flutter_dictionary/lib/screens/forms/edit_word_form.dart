import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/word.dart';
import '../../providers/dictionary_provider.dart';
import '../../widgets/glass_card.dart';

class EditWordForm extends StatefulWidget {
  final Word word;

  const EditWordForm({super.key, required this.word});

  @override
  State<EditWordForm> createState() => _EditWordFormState();
}

class _EditWordFormState extends State<EditWordForm> {
  late final TextEditingController _chineseController;
  late final TextEditingController _pinyinController;
  late final TextEditingController _russianController;
  late int _hskLevel;

  @override
  void initState() {
    super.initState();
    _chineseController = TextEditingController(text: widget.word.chinese);
    _pinyinController = TextEditingController(text: widget.word.pinyin);
    _russianController = TextEditingController(text: widget.word.russian);
    _hskLevel = widget.word.hskLevel;
  }

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
                    'Редактировать слово',
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
              
              GlassTextField(
                hint: '汉字 (китайские иероглифы)',
                controller: _chineseController,
                prefixIcon: Icons.translate,
              ),
              const SizedBox(height: 16),
              
              GlassTextField(
                hint: 'Pinyin (пиньинь)',
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
                  label: 'Сохранить',
                  icon: Icons.check_circle,
                  onPressed: _chineseController.text.isEmpty ||
                          _pinyinController.text.isEmpty ||
                          _russianController.text.isEmpty
                      ? () {}
                      : () {
                          final provider = Provider.of<DictionaryProvider>(
                            context,
                            listen: false,
                          );
                          final updated = widget.word.copyWith(
                            chinese: _chineseController.text,
                            pinyin: _pinyinController.text,
                            russian: _russianController.text,
                            hskLevel: _hskLevel,
                          );
                          provider.updateWord(updated);
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
