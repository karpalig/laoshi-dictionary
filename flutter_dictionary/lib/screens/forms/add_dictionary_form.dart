import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dictionary_provider.dart';
import '../../widgets/glass_card.dart';
import '../../utils/color_helper.dart';

class AddDictionaryForm extends StatefulWidget {
  const AddDictionaryForm({super.key});

  @override
  State<AddDictionaryForm> createState() => _AddDictionaryFormState();
}

class _AddDictionaryFormState extends State<AddDictionaryForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedColor = 'cyan';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Новый словарь',
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
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorHelper.getColor(_selectedColor),
                      ),
                      child: const Icon(Icons.book, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty
                                ? 'Название словаря'
                                : _nameController.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (_descriptionController.text.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _descriptionController.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              GlassTextField(
                hint: 'Название словаря',
                controller: _nameController,
                prefixIcon: Icons.book,
              ),
              const SizedBox(height: 16),
              
              GlassTextField(
                hint: 'Описание',
                controller: _descriptionController,
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Color picker
              const Text(
                'Цвет',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 12,
                children: ColorHelper.availableColors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorHelper.getColor(color),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  label: 'Создать словарь',
                  icon: Icons.add_circle,
                  onPressed: _nameController.text.isEmpty
                      ? () {}
                      : () {
                          final provider = Provider.of<DictionaryProvider>(
                            context,
                            listen: false,
                          );
                          provider.createDictionary(
                            name: _nameController.text,
                            description: _descriptionController.text.isEmpty
                                ? null
                                : _descriptionController.text,
                            color: _selectedColor,
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
