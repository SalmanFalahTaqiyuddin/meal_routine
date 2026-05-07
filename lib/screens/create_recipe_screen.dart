import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _nameCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final List<TextEditingController> _ingredientCtrls = [
    TextEditingController(),
  ];
  final List<TextEditingController> _stepCtrls = [TextEditingController()];

  File? _imageFile;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _save() async {
    if (_nameCtrl.text.isEmpty || _durationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan estimasi waktu wajib diisi')),
      );
      return;
    }
    setState(() => _loading = true);

    final recipe = Recipe(
      id: 0,
      name: _nameCtrl.text.trim(),
      image: _imageFile?.path ?? '',
      duration: _durationCtrl.text.trim(),
      ingredients: _ingredientCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      steps: _stepCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      isCustom: true,
    );

    final ok = await RecipeService.createRecipe(recipe);
    setState(() => _loading = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resep berhasil disimpan!')));
      Navigator.pop(context);
    }
  }

  Widget _buildDynamicFields(
    List<TextEditingController> ctrls,
    String hint,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...ctrls.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: e.value,
                    decoration: InputDecoration(hintText: '$hint ${e.key + 1}'),
                  ),
                ),
                if (ctrls.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => setState(() => ctrls.removeAt(e.key)),
                  ),
              ],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => ctrls.add(TextEditingController())),
          icon: const Icon(Icons.add, color: AppTheme.primaryGreen, size: 18),
          label: Text(
            'Tambah $label',
            style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Buat Resep Sendiri')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Image Picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.borderColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 36,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tambah foto makanan',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(hintText: 'Nama makanan'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationCtrl,
            decoration: const InputDecoration(
              hintText: 'Estimasi waktu (cth: 30 Menit)',
            ),
          ),
          const SizedBox(height: 24),
          _buildDynamicFields(_ingredientCtrls, 'Bahan', 'Alat & Bahan'),
          const SizedBox(height: 24),
          _buildDynamicFields(_stepCtrls, 'Langkah', 'Langkah-langkah'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan Resep'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
