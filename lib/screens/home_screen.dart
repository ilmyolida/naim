import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../data/words_data.dart';
import '../managers/preferences_manager.dart';
import '../app_theme.dart';

/// Ilovaning asosiy ekrani.
/// Bu yerda qidiruv, tarix, guruhlar va ma'lumotlar jamlangan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Qidiruv maydonini boshqarish
  final TextEditingController _searchController = TextEditingController();
  
  // Qidiruv natijalarini saqlaydigan ro'yxat
  List<DictionaryWord> _searchResult = [];
  
  // Qidiruv tarixi ro'yxati
  List<DictionaryWord> _historyResult = [];

  // Tanlangan qidiruv rejimlari (Xotiradan yuklanadi)
  bool _isExactSearch = false; // Aniq moslik
  bool _isFuzzySearch = true;  // O'xshashlik

  // BottomNavigationBar'ning hozirgi index'i
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Boshlang'ich holda qidiruv maydoni bo'sh bo'lsa, hech nima ko'rsatmaymiz
    _searchResult = [];
    _historyResult = PreferencesManager.loadHistory(); // Tarixni yuklash
    _isExactSearch = PreferencesManager.loadExactSearch(); // Sozlamalarni yuklash
    _isFuzzySearch = PreferencesManager.loadFuzzySearch();
  }

  /// Qidiruv logikasi: Kirish matniga ko'ra so'zlarni filtrlaydi.
  /// Matn o'zgargan har gal chaqiriladi.
  void _performSearch(String query) {
    if (query.isEmpty) {
      // Matn bo'sh bo'lsa, qidiruv natijasini bo'shatamiz
      setState(() {
        _searchResult = [];
      });
      return;
    }

    List<DictionaryWord> filteredWords = [];
    final lowerCaseQuery = query.toLowerCase();

    // Barcha so'zlar ro'yxati bo'ylab qidiramiz
    for (var word in WordsRepository.allWords) {
      bool isMatch = false;

      // 1. Aniq moslik rejimi (Exact Match)
      if (_isExactSearch) {
        if (word.word == query || word.translation.toLowerCase() == lowerCaseQuery) {
          isMatch = true;
        }
      } 
      
      // 2. O'xshashlik rejimi (Fuzzy Match)
      // Bu standart rejim bo'lishi kerak.
      if (!isMatch && _isFuzzySearch) {
        // So'z tarkibida bo'lsa (Contains)
        if (word.word.contains(query) || word.translation.toLowerCase().contains(lowerCaseQuery)) {
          isMatch = true;
        }
        // Kelajakda bu yerga murakkab fuzzy search algoritmlarini (masalan, distance) qo'shish mumkin.
      }

      // Agar mos kelsa, natijaga qo'shamiz
      if (isMatch) {
        filteredWords.add(word);
      }
    }

    setState(() {
      _searchResult = filteredWords;
    });
  }

  /// So'z bosilganda uning tafsilotlariga o'tish va tarixga saqlash funksiyasi.
  void _onWordTapped(DictionaryWord word) {
    // 1. Tarixga saqlash (PreferencesManager orqali)
    PreferencesManager.addToHistory(word);
    
    // 2. Tafsilotlar ekraniga o'tish
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordDetailsScreen(word: word),
      ),
    ).then((_) {
      // Ekranga qaytganda tarix ro'yxatini yangilash
      setState(() {
        _historyResult = PreferencesManager.loadHistory();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Light mode yoki Cream mode rejimini Preference'ga qarab tanlaymiz
    final theme = PreferencesManager.loadThemeMode() == 0 ? AppTheme.lightTheme : AppTheme.softCreamTheme;
    final textTheme = theme.textTheme;

    return Theme(
      data: theme, // Butun ekranni mavzuga moslash
      child: Scaffold(
        appBar: AppBar(
          title: Text("An-Na’im al-Kubro", style: textTheme.headlineMedium),
          actions: [
            // Rejimni o'zgartirish knopkasi (Yuqorida)
            IconButton(
              icon: Icon(PreferencesManager.loadThemeMode() == 0 ? Icons.light_mode : Icons.wb_sunny_outlined),
              onPressed: () {
                // Hozirgi rejimni teskarisiga almashtirish va saqlash
                int currentMode = PreferencesManager.loadThemeMode();
                int nextMode = currentMode == 0 ? 1 : 0; // Light (0) -> Cream (1)
                PreferencesManager.saveThemeMode(nextMode).then((_) {
                  setState(() {}); // Ekranni qayta chizish (rejim o'zgarishi uchun)
                });
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentNavIndex, // BottomNavigationBar orqali boshqariladi
          children: [
            // 0. Qidiruv Sahifasi
            _buildSearchPage(textTheme),
            
            // 1. Guruhlar Sahifasi ( image_0.png dagi "To'plamlar" kabi)
            _buildGroupsPage(textTheme),
            
            // 2. Saqlanganlar/Tarix Sahifasi (image_1.png kabi)
            _buildHistoryPage(textTheme),
            
            // 3. Ilova haqida Ma'lumot Sahifasi (Siz yozasiz)
            _buildAboutPage(textTheme),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: "Qidiruv"),
            BottomNavigationBarItem(icon: Icon(Icons.category_outlined), label: "Guruhlar"),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: "Tarix"),
            BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: "Ma'lumot"),
          ],
        ),
      ),
    );
  }

  /// Qidiruv maydoni va natijalarni chizish funksiyasi
  Widget _buildSearchPage(TextTheme textTheme) {
    return Column(
      children: [
        // 1. Qidiruv maydoni
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            controller: _searchController,
            onChanged: _performSearch,
            decoration: InputDecoration(
              hintText: "Lug'atdan izlang...",
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00BFA5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              filled: true,
              fillColor: const Color(0xFFF3F3F3), // Taqdim etgan suratlardagi mayin kulrang
            ),
          ),
        ),
        
        // 2. Qidiruv rejimlari (image_3.png kabi moslashtirilgan ko'rinish)
        _buildSearchModesCard(textTheme),
        
        // 3. Qidiruv natijasi
        Expanded(
          child: _searchResult.isEmpty
              ? Center(child: Text("Hech nima topilmadi.", style: textTheme.bodyMedium))
              : _buildWordList(_searchResult, textTheme),
        ),
      ],
    );
  }

  /// Qidiruv rejimlari ko'rsatilgan chiroyli Card
  Widget _buildSearchModesCard(TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        children: [
          SwitchListTile(
            title: Text("Aniq moslik", style: textTheme.bodyLarge),
            subtitle: Text("So'z aynan qidirilgan matnga teng bo'lsin", style: textTheme.bodyMedium),
            value: _isExactSearch,
            activeColor: const Color(0xFF00BFA5),
            onChanged: (v) {
              PreferencesManager.saveExactSearch(v); // Saqlash
              setState(() => _isExactSearch = v);
              _performSearch(_searchController.text); // Qidiruvni qayta chaqirish
            },
          ),
          const Divider(height: 1, indent: 15, endIndent: 15),
          SwitchListTile(
            title: Text("O'xshashlik rejimi", style: textTheme.bodyLarge),
            subtitle: Text("So'z tarkibida bo'lsa ham topadi", style: textTheme.bodyMedium),
            value: _isFuzzySearch,
            activeColor: const Color(0xFF00BFA5),
            onChanged: (v) {
              PreferencesManager.saveFuzzySearch(v); // Saqlash
              setState(() => _isFuzzySearch = v);
              _performSearch(_searchController.text); // Qidiruvni qayta chaqirish
            },
          ),
        ],
      ),
    );
  }

  /// Guruhlar ro'yxati ko'rsatilgan sahifa (image_0.png kabi)
  Widget _buildGroupsPage(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text("To'plamlar", style: textTheme.headlineMedium),
        ),
        Expanded(
          child: ListView(
            children: [
              _buildGroupCard("Fellar", Icons.book_outlined, WordsRepository.verbs, textTheme),
              _buildGroupCard("Ismlar", Icons.library_books_outlined, WordsRepository.nouns, textTheme),
              _buildGroupCard("Harflar", Icons.local_offer_outlined, WordsRepository.particles, textTheme),
            ],
          ),
        ),
      ],
    );
  }

  /// Bitta guruhni ko'rsatadigan Card
  Widget _buildGroupCard(String title, IconData icon, List<DictionaryWord> wordList, TextTheme textTheme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF00BFA5), size: 30),
        title: Text(title, style: textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text("An-Na’im al-Kubro ${title.toLowerCase()} to'plami", style: textTheme.bodyMedium),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(10)),
          child: Text("${wordList.length} ta", style: const TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold)),
        ),
        onTap: () {
          // Guruhdagi barcha so'zlarni ko'rsatadigan sahifaga o'tish
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Theme(
                data: PreferencesManager.loadThemeMode() == 0 ? AppTheme.lightTheme : AppTheme.softCreamTheme,
                child: Scaffold(
                  appBar: AppBar(title: Text(title)),
                  body: _buildWordList(wordList, textTheme),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Tarix ro'yxati ko'rsatilgan sahifa
  Widget _buildHistoryPage(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Oxirgi qidiruvlar", style: textTheme.headlineMedium),
              if (_historyResult.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Tarixni tozalash funksiyasi
                    PreferencesManager.clearHistory().then((_) {
                      setState(() {
                        _historyResult = [];
                      });
                    });
                  },
                  child: const Text("Tozalash"),
                ),
            ],
          ),
        ),
        Expanded(
          child: _historyResult.isEmpty
              ? Center(child: Text("Hozircha tarix bo'sh.", style: textTheme.bodyMedium))
              : _buildWordList(_historyResult, textTheme, isHistoryPage: true),
        ),
      ],
    );
  }

  /// Barcha matnli ma'lumotlarni siz yozadigan sahifa
  Widget _buildAboutPage(TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 80, color: Color(0xFF00BFA5)),
          const SizedBox(height: 20),
          Text("Ilova haqida ma'lumot", style: textTheme.headlineMedium),
          const SizedBox(height: 15),
          Text(
            // --- MA'LUMOT MATNINI SHU YERGA YOZASIZ ---
            "“An-Na’im al-Kubro” lug’ati arab tilini o'rganuvchilar va tadqiqotchilar uchun mo'ljallangan yirik hajmli manbadur.\n\nSiz bu ilova orqali lug'at tarkibidagi barcha so'zlarni 3ta asosiy guruhga ajratilgan holda ko'rishingiz mumkin: Fellar, Ismlar va Harflar. \n\nIlovadagi Qidiruv bo'limi sizga so'zni arabcha yoki o'zbekcha tarjimasiga ko'ra oson va tez topish imkonini beradi. Shuningdek, murakkab va fuzzy search (o'xshashlik) rejimlari ham mavjud.",
            textAlign: TextAlign.justify,
            style: textTheme.bodyLarge!.copyWith(height: 1.6),
          ),
          const SizedBox(height: 30),
          // Versiya ma'lumotlari (image_2.png kabi)
          Text("Versiya: 1.0.0", style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// So'zlar ro'yxatini Card'lar orqali chizadigan umumiy funksiya
  Widget _buildWordList(List<DictionaryWord> items, TextTheme textTheme, {bool isHistoryPage = false}) {
    return ListView.separated(
      itemCount: items.length,
      padding: const EdgeInsets.all(10.0),
      separatorBuilder: (context, index) => const SizedBox(height: 8), // Kartochkalar orasidagi masofa
      itemBuilder: (context, index) {
        final word = items[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            title: Text(
              word.word, // Arabcha so'z
              textAlign: TextAlign.right, // O'ngdan chapga yozish
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              word.translation, // O'zbekcha tarjima
              style: textTheme.bodyMedium,
            ),
            trailing: Icon(Icons.navigate_next_outlined, color: Colors.grey.shade400),
            onTap: () => _onWordTapped(word), // Tafsilotga o'tish
          ),
        );
      },
    );
  }
}