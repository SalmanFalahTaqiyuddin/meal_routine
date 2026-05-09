import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_theme.dart';
import '../models/recipe_model.dart';
import '../models/meal_model.dart';
import '../services/recipe_service.dart';
import '../services/storage_service.dart';
import 'meal_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Recipe> _myRecipes = [];
  bool _loading = true;

  String _name = 'User';
  String _email = ''; // ← bukan hardcoded lagi, diisi dari storage
  File? _avatarFile;

  int get _variasi => _myRecipes.length;
  int _streak = 0;
  int _terjadwal = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final recipes = await RecipeService.getMyRecipes();
    final profile = await StorageService.loadProfile();
    final meals = await StorageService.loadMeals();

    // Hitung _terjadwal: hari unik yang punya minimal 1 meal terjadwal
    final scheduledDates = meals.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key.split('|')[0])
        .toSet();

    // Hitung _streak: hari berturut-turut mundur dari hari ini
    final today = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final day = today.subtract(Duration(days: i));
      final key = _formatDate(day);
      final hasMeal = meals.entries.any(
        (e) => e.key.startsWith(key) && e.value.isNotEmpty,
      );
      if (hasMeal) {
        streak++;
      } else {
        if (i > 0) break;
      }
    }

    setState(() {
      _myRecipes = recipes;
      _name = profile['name'] ?? 'User';
      _email = profile['email'] ?? '';
      // ✅ Baca avatarPath dari storage agar sinkron lintas screen
      final avatarPath = profile['avatarPath'] as String?;
      if (avatarPath != null && avatarPath.isNotEmpty) {
        final f = File(avatarPath);
        _avatarFile = f.existsSync() ? f : null;
      } else {
        _avatarFile = null;
      }
      _terjadwal = scheduledDates.length;
      _streak = streak;
      _loading = false;
    });
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _editName() {
    final ctrl = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nama',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Masukkan nama'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                _email,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '* Email tidak dapat diubah',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                // ✅ Merge — hanya update name, email & avatarPath tetap
                await StorageService.saveProfile({'name': newName});
                setState(() => _name = newName);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _editAvatar() {
    final bool supportCamera =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppTheme.primaryGreen,
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (picked != null && mounted) {
                  // ✅ Persist path ke storage agar sinkron dengan HomeScreen
                  await StorageService.saveAvatarPath(picked.path);
                  setState(() => _avatarFile = File(picked.path));
                }
              },
            ),
            if (supportCamera)
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppTheme.primaryGreen,
                ),
                title: const Text('Ambil Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (picked != null && mounted) {
                    // ✅ Persist path ke storage
                    await StorageService.saveAvatarPath(picked.path);
                    setState(() => _avatarFile = File(picked.path));
                  }
                },
              ),
            if (_avatarFile != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Hapus Foto',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // ✅ Hapus path dari storage juga
                  StorageService.saveAvatarPath(null);
                  setState(() => _avatarFile = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// ✅ FIX: Hapus guard `if (recipe.id == null) return` yang memblokir delete.
  /// Pakai ID jika ada, fallback ke delete-by-name untuk resep lama
  /// yang disimpan sebelum fix auto-generate ID diterapkan.
  void _deleteRecipe(Recipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Resep?'),
        content: Text('"${recipe.name}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (recipe.id != null) {
      // Resep baru — punya ID, hapus by ID
      await RecipeService.deleteRecipe(recipe.id!);
    } else {
      // Resep lama (disimpan sebelum fix) — fallback hapus by name
      await StorageService.removeCustomRecipeByName(recipe.name);
    }

    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  children: [
                    const Center(
                      child: Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileHeader(),
                    const SizedBox(height: 28),
                    _buildStats(),
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        'My Recipes',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _myRecipes.isEmpty
                        ? _buildEmptyRecipes()
                        : _buildRecipeList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _editAvatar,
          child: Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEEEEEE),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _avatarFile != null
                      ? Image.file(
                          _avatarFile!,
                          fit: BoxFit.cover,
                          width: 90,
                          height: 90,
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: AppTheme.textSecondary,
                        ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _editName,
              child: const Icon(
                Icons.edit,
                size: 16,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _email,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('🍳', '$_variasi Jenis', 'Variasi'),
        _buildStatItem('🔥', '$_streak Hari', 'Streak'),
        _buildStatItem('🗓️', '$_terjadwal Hari', 'Terjadwal'),
      ],
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmptyRecipes() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Image.asset(
          'assets/images/empty_plate.png',
          height: 160,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.restaurant,
            size: 80,
            color: AppTheme.borderColor,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No Recipes Yet!',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          'Start creating your own recipes here.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildRecipeList() {
    return Column(
      children: _myRecipes.map((r) => _buildRecipeCard(r)).toList(),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        final meal = Meal(
          id: recipe.id ?? 0,
          name: recipe.name,
          image: recipe.image,
          duration: recipe.duration,
          mealType: '',
          ingredients: recipe.ingredients,
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildRecipeImage(recipe.image),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Estimasi Waktu: ${recipe.duration}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () => _deleteRecipe(recipe),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImage(String image) {
    if (image.isEmpty) return _placeholder();
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return Image.file(
      File(image),
      width: 54,
      height: 54,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: 54,
    height: 54,
    color: AppTheme.borderColor,
    child: const Icon(Icons.fastfood, color: AppTheme.textSecondary),
  );
}
