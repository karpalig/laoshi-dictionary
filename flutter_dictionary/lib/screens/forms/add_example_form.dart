import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dictionary_provider.dart';
import '../../widgets/glass_card.dart';

class AddExampleForm extends StatefulWidget {
  final String wordId;

  const AddExampleForm({super.key, required this.wordId});

  @override
  State<AddExampleForm> createState() => _AddExampleFormState();
}

class _AddExampleFormState extends State<AddExampleForm> {
  final _chineseController = TextEditingController();
  final _pinyinController = TextEditingController();
  final _russianController = TextEditingController();

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
                    'Новый пример',
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
                      Icon(
                        Icons.format_quote,
                        size: 14,
                        color: const Color(0xFF00CCFF).withOpacity(0.7),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _chineseController.text.isEmpty
                            ? 'Предложение на китайском...'
                            : _chineseController.text,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pinyinController.text.isEmpty
                            ? 'Pinyin предложения...'
                            : _pinyinController.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF00CCFF).withOpacity(0.8),
                        ),
                      ),
                      if (_russianController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _russianController.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Предложение на китайском',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              
              GlassTextField(
                hint: 'Например: 你好，我是学生。',
                controller: _chineseController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              GlassTextField(
                hint: 'Pinyin предложения',
                controller: _pinyinController,
                prefixIcon: Icons.text_fields,
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Перевод на русский',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              
              GlassTextField(
                hint: 'Например: Привет, я студент.',
                controller: _russianController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  label: 'Добавить пример',
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
                          provider.createExample(
                            wordId: widget.wordId,
                            chineseSentence: _chineseController.text,
                            pinyinSentence: _pinyinController.text,
                            russianTranslation: _russianController.text,
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
