import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dictionary.dart';
import '../../providers/dictionary_provider.dart';
import '../../widgets/glass_card.dart';
import '../../utils/color_helper.dart';

class EditDictionaryForm extends StatefulWidget {
  final Dictionary dictionary;

  const EditDictionaryForm({super.key, required this.dictionary});

  @override
  State<EditDictionaryForm> createState() => _EditDictionaryFormState();
}

class _EditDictionaryFormState extends State<EditDictionaryForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dictionary.name);
    _descriptionController =
        TextEditingController(text: widget.dictionary.description ?? '');
    _selectedColor = widget.dictionary.color;
  }

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
                    'Редактировать',
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
                  label: 'Сохранить',
                  icon: Icons.check_circle,
                  onPressed: _nameController.text.isEmpty
                      ? () {}
                      : () {
                          final provider = Provider.of<DictionaryProvider>(
                            context,
                            listen: false,
                          );
                          final updated = widget.dictionary.copyWith(
                            name: _nameController.text,
                            description: _descriptionController.text.isEmpty
                                ? null
                                : _descriptionController.text,
                            color: _selectedColor,
                          );
                          provider.updateDictionary(updated);
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
