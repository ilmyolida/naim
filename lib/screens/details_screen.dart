import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../managers/preferences_manager.dart';
import '../app_theme.dart';

/// Bitta so'z haqida to'liq tafsilotlarni ko'rsatadigan sahifa.
class WordDetailsScreen extends StatelessWidget {
  final DictionaryWord word;

  const WordDetailsScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    // Light mode yoki Cream mode rejiminiPreference'ga qarab tanlaymiz
    final theme = PreferencesManager.loadThemeMode() == 0 ? AppTheme.lightTheme : AppTheme.softCreamTheme;
    final textTheme = theme.textTheme;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(title: const Text("So'z tafsiloti")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. Arabcha so'z (Katta va qalin)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    word.word,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              
              // 2. So'z turi (Guruh nomi)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  // Enumni chiroyli matnga o'tkazamiz
                  word.type == WordType.fel ? "Guruh: Fellar" : (word.type == WordType.ism ? "Guruh: Ismlar" : "Guruh: Harflar"),
                  style: textTheme.bodyMedium!.copyWith(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 15),

              const Divider(),
              const SizedBox(height: 15),

              // 3. Tarjima matni
              Text(
                "O'zbekcha tarjimasi:",
                style: textTheme.headlineMedium!.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                word.translation,
                textAlign: TextAlign.justify,
                style: textTheme.bodyLarge!.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}