import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../managers/preferences_manager.dart';
import '../app_theme.dart';
import 'package:flutter/services.dart';
/// Bitta so'z haqida to'liq tafsilotlarni ko'rsatadigan sahifa.

class WordDetailsScreen extends StatefulWidget {
  final DictionaryWord word;
  const WordDetailsScreen({super.key, required this.word});

  @override
  State<WordDetailsScreen> createState() => _WordDetailsScreenState();
}

class _WordDetailsScreenState extends State<WordDetailsScreen> {
  late bool isFavorite;
  late bool isSaved;

  @override
  void initState() {
    super.initState();
    isFavorite = PreferencesManager.loadFavorites().any((w) => w.id == widget.word.id);
    isSaved = PreferencesManager.loadSaved().any((w) => w.id == widget.word.id);
  }

  void _toggleFavorite() async {
    if (isFavorite) {
      await PreferencesManager.removeFromFavorites(widget.word);
    } else {
      await PreferencesManager.addToFavorites(widget.word);
    }
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  void _toggleSaved() async {
    if (isSaved) {
      await PreferencesManager.removeFromSaved(widget.word);
    } else {
      await PreferencesManager.addToSaved(widget.word);
    }
    setState(() {
      isSaved = !isSaved;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = PreferencesManager.loadThemeMode() == 0 ? AppTheme.lightTheme : AppTheme.softCreamTheme;
    final textTheme = theme.textTheme;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5E9),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(34), bottom: Radius.circular(0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFF00C2B7), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Handle (tutqich)
                      Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      // So'z pill ichida
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C2B7),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Text(
                          widget.word.word,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'NotoNaskhArabic',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Guruh
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.word.type == WordType.fel
                              ? "Guruh: Fellar"
                              : (widget.word.type == WordType.ism ? "Guruh: Ismlar" : "Guruh: Harflar"),
                          style: textTheme.bodyMedium!.copyWith(color: Colors.grey[700]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Ma'nolar bloki
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF00C2B7), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "O'zbekcha tarjimasi:",
                              style: textTheme.headlineMedium!.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.word.translation,
                              textAlign: TextAlign.justify,
                              style: textTheme.bodyLarge!.copyWith(height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _JewelActionButton(icon: Icons.volume_up, onTap: () {
                            // Ovoz chiqarish funksiyasi (kelajakda)
                          }),
                          _JewelActionButton(icon: isSaved ? Icons.bookmark : Icons.bookmark_border, onTap: _toggleSaved),
                          _JewelActionButton(icon: isFavorite ? Icons.star : Icons.star_border, onTap: _toggleFavorite),
                          _JewelActionButton(icon: Icons.copy, onTap: () {
                            // Matnni nusxalash funksiyasi
                            final data = ClipboardData(text: '${widget.word.word}\n${widget.word.translation}');
                            Clipboard.setData(data);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Matn nusxalandi!')),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JewelActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _JewelActionButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF00C2B7), size: 28),
      ),
    );
  }
}
// End of file