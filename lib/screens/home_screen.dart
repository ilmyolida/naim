// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:naim/screens/details_screen.dart';
import '../models/word_model.dart';
import '../managers/preferences_manager.dart';
import '../app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'group_words_screen.dart';

/// Ilovaning asosiy ekrani.
/// Bu yerda qidiruv, tarix, guruhlar va ma'lumotlar jamlangan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // bool _agreementAccepted = false; // Olib tashlandi, ishlatilmaydi
  // Sevimlilar va saqlanganlar uchun ro'yxatlar
  List<DictionaryWord> _favorites = [];
  List<DictionaryWord> _saved = [];
  // Qidiruv maydonini boshqarish
  final TextEditingController _searchController = TextEditingController();

  // Qidiruv natijalarini saqlaydigan ro'yxat
  List<DictionaryWord> _searchResult = [];

  // Qidiruv tarixi ro'yxati
  List<DictionaryWord> _historyResult = [];

  // Tanlangan qidiruv rejimlari (Xotiradan yuklanadi)
  bool _isExactSearch = false; // Aniq moslik
  bool _isFuzzySearch = true; // O'xshashlik

  // BottomNavigationBar'ning hozirgi index'i
  int _currentNavIndex = 0;

  bool _isLoading = true; // Yuklanish indikatori uchun
  List<DictionaryWord> _allWords = []; // Baza shu yerga yuklanadi

  @override
  void initState() {
    super.initState();
    _loadAllData(); // Ma'lumotlarni yuklashni chaqiramiz
    _checkAgreement();
  }

  Future<void> _checkAgreement() async {
    // SharedPreferences instance direct
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool('agreement_accepted') ?? false;
    if (!accepted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Foydalanish shartlari va maxfiylik siyosati'),
            content: SizedBox(
              width: 400,
              height: 260,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ilovadan foydalanishdan oldin quyidagi shartlar va maxfiylik siyosati bilan tanishib chiqing:',
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Shartnoma va siyosatni ochish'),
                      onPressed: () async {
                        final url = Uri.parse(
                          'https://ilmyolida.github.io/Naim-deployment-/Naim.html',
                        );
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text('Davom etish uchun rozilik bildiring.'),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await prefs.setBool('agreement_accepted', true);
                  if (!mounted) return;
                  setState(() {});
                  // ignore: use_build_context_synchronously
                  Navigator.of(ctx).pop();
                },
                child: const Text('Roziman'),
              ),
            ],
          ),
        );
      });
    } else {
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _loadAllData() async {
    final data = await DataService.loadAllData(); // TXT fayllardan o'qiydi
    setState(() {
      _allWords = data;
      _historyResult = PreferencesManager.loadHistory();
      _favorites = PreferencesManager.loadFavorites();
      _saved = PreferencesManager.loadSaved();
      _isExactSearch = PreferencesManager.loadExactSearch();
      _isFuzzySearch = PreferencesManager.loadFuzzySearch();
      _isLoading = false; // Yuklab bo'lingach, ekranni ochamiz
    });
  }

  /// Tarix, Sevimlilar, Saqlanganlar uchun universal sahifa
  Widget _buildHistoryPage(TextTheme textTheme) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              tabs: const [
                Tab(icon: Icon(Icons.history), text: "Tarix"),
                Tab(icon: Icon(Icons.favorite), text: "Sevimlilar"),
                Tab(icon: Icon(Icons.bookmark), text: "Saqlanganlar"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tarix
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, right: 16),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text("Tozalash"),
                          onPressed: () {
                            PreferencesManager.clearHistory().then((_) {
                              setState(() {
                                _historyResult = [];
                              });
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: _historyResult.isEmpty
                          ? Center(
                              child: Text(
                                "Hozircha tarix bo'sh.",
                                style: textTheme.bodyMedium,
                              ),
                            )
                          : _buildWordList(
                              _historyResult,
                              textTheme,
                              isHistoryPage: true,
                            ),
                    ),
                  ],
                ),
                // Sevimlilar
                _favorites.isEmpty
                    ? Center(
                        child: Text(
                          "Sevimlilar bo'sh.",
                          style: textTheme.bodyMedium,
                        ),
                      )
                    : _buildWordList(_favorites, textTheme, isHistoryPage: false),
                // Saqlanganlar
                _saved.isEmpty
                    ? Center(
                        child: Text(
                          "Saqlanganlar bo'sh.",
                          style: textTheme.bodyMedium,
                        ),
                      )
                    : _buildWordList(_saved, textTheme, isHistoryPage: false),
              ],
            ),
          ),
        ],
      ),
    );
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
    for (var word in _allWords) {
      bool isMatch = false;

      // 1. Aniq moslik rejimi (Exact Match)
      if (_isExactSearch) {
        if (word.word == query ||
            word.translation.toLowerCase() == lowerCaseQuery) {
          isMatch = true;
        }
      }

      // 2. O'xshashlik rejimi (Fuzzy Match)
      // Bu standart rejim bo'lishi kerak.
      if (!isMatch && _isFuzzySearch) {
        // So'z tarkibida bo'lsa (Contains)
        if (word.word.contains(query) ||
            word.translation.toLowerCase().contains(lowerCaseQuery)) {
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
      MaterialPageRoute(builder: (context) => WordDetailsScreen(word: word)),
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
    final theme = PreferencesManager.loadThemeMode() == 0
        ? AppTheme.lightTheme
        : AppTheme.softCreamTheme;
    final textTheme = theme.textTheme;

    return Theme(
      data: theme, // Butun ekranni mavzuga moslash
      child: Scaffold(
        appBar: AppBar(
          title: Text("An-Na’im al-Kubro", style: textTheme.headlineMedium),
          actions: [
            // Rejimni o'zgartirish knopkasi (Yuqorida)
            IconButton(
              icon: Icon(
                PreferencesManager.loadThemeMode() == 0
                    ? Icons.light_mode
                    : Icons.wb_sunny_outlined,
              ),
              onPressed: () {
                int currentMode = PreferencesManager.loadThemeMode();
                int nextMode = currentMode == 0
                    ? 1
                    : 0; // Light (0) -> Cream (1)
                PreferencesManager.saveThemeMode(nextMode).then((_) {
                  setState(() {});
                });
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _currentNavIndex,
                children: [
                  _buildSearchPage(textTheme),
                  _buildGroupsPage(textTheme, context, _allWords),
                  _buildHistoryPage(textTheme),
                  _buildAboutPage(textTheme, context, _isExactSearch, _isFuzzySearch),
                ],
              ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withAlpha(242),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: theme.colorScheme.onSurface.withAlpha(153),
                showUnselectedLabels: true,
                currentIndex: _currentNavIndex,
                onTap: (index) {
                  setState(() {
                    _currentNavIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.search),
                    label: "Qidiruv",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.category_outlined),
                    label: "Guruhlar",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bookmark_border),
                    label: "Tarix",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.info_outline),
                    label: "Ma'lumot",
                  ),
                ],
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                enableFeedback: true,
                landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
              ),
            ),
          ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(
                0xFFF3F3F3,
              ), // Taqdim etgan suratlardagi mayin kulrang
            ),
          ),
        ),

        // 2. Qidiruv rejimlari (image_3.png kabi moslashtirilgan ko'rinish)
        // Qidiruv rejimlari card olib tashlandi (legacy code removed)

        // 3. Qidiruv natijasi
        Expanded(
          child: _searchResult.isEmpty
              ? Center(
                  child: Text(
                    "Hech nima topilmadi.",
                    style: textTheme.bodyMedium,
                  ),
                )
              : _buildWordList(_searchResult, textTheme, isHistoryPage: false),
        ),
      ],
    );
  }
  
  // ...existing code...
}

/// Qidiruv rejimlari ko'rsatilgan chiroyli Card
// _buildSearchModesCard legacy widget and all references removed

// Legacy/broken class and function stubs removed

/// Guruhlar ro'yxati ko'rsatilgan sahifa (image_0.png kabi)
Widget _buildGroupsPage(TextTheme textTheme, BuildContext context, dynamic allWords) {
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
            _buildGroupCard(
              "Fellar",
              Icons.book_outlined,
              allWords.where((w) => w.type == WordType.fel).toList(),
              textTheme,
              context,
            ),
            _buildGroupCard(
              "Ismlar",
              Icons.library_books_outlined,
              allWords.where((w) => w.type == WordType.ism).toList(),
              textTheme,
              context,
            ),
            _buildGroupCard(
              "Harflar",
              Icons.local_offer_outlined,
              allWords.where((w) => w.type == WordType.harf).toList(),
              textTheme,
              context,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildGroupCard(
  String title,
  IconData icon,
  List<DictionaryWord> wordList,
  TextTheme textTheme,
  BuildContext context,
) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF00BFA5), size: 30),
      title: Text(
        title,
        style: textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "An-Na'im al-Kubro ${title.toLowerCase()} to'plami",
        style: textTheme.bodyMedium,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          "${wordList.length} ta",
          style: const TextStyle(
            color: Color(0xFF00BFA5),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GroupWordsScreen(groupTitle: title, words: wordList),
          ),
        );
      },
    ),
  );
}

/// Barcha matnli ma'lumotlarni siz yozadigan sahifa
Widget _buildAboutPage(TextTheme textTheme, BuildContext context, bool isExactSearch, bool isFuzzySearch) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Qidiruv rejimlari va theme haqida card
        Card(
          margin: const EdgeInsets.only(bottom: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Qidiruv sozlamalari",
                      style: textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      isExactSearch
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isExactSearch ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text("Aniq moslik: ", style: textTheme.bodyMedium),
                    Text(
                      isExactSearch ? "yoqilgan" : "o'chirilgan",
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isFuzzySearch
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isFuzzySearch ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text("O'xshashlik rejimi: ", style: textTheme.bodyMedium),
                    Text(
                      isFuzzySearch ? "yoqilgan" : "o'chirilgan",
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.color_lens,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text("Mavzu: ", style: textTheme.bodyMedium),
                    Text(
                      PreferencesManager.loadThemeMode() == 0
                          ? "Oq (Light)"
                          : PreferencesManager.loadThemeMode() == 1
                          ? "Sariq (Cream)"
                          : "Qora (Dark)",
                      style: textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Maxfiylik siyosati va shartlar card
        Card(
          margin: const EdgeInsets.only(bottom: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.privacy_tip,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Mahfiylik siyosati va shartlar",
                      style: textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Ilovadan foydalanish uchun quyidagi siyosat va shartlar bilan tanishib chiqing:",
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.link, color: Colors.blue),
                    const SizedBox(width: 6),
                    Flexible(
                      child: GestureDetector(
                        onTap: () async {
                          // ignore: deprecated_member_use
                          await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text(
                                "Mahfiylik siyosati va shartlar",
                              ),
                              content: SizedBox(
                                width: 400,
                                height: 400,
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        Text(
                                          "To'liq siyosat va shartlar quyidagi havolada:",
                                          style: textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 10),
                                        TextButton.icon(
                                          icon: const Icon(
                                            Icons.open_in_browser,
                                          ),
                                          label: const Text("Brauzerda ochish"),
                                          onPressed: () async {
                                            final url = Uri.parse(
                                              "https://ilmyolida.github.io/Naim-deployment-/Naim.html",
                                            );
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(
                                                url,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Yopish"),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          "https://ilmyolida.github.io/Naim-deployment-/Naim.html",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

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
Widget _buildWordList(
  List<DictionaryWord> items,
  TextTheme textTheme, {
  bool isHistoryPage = false,
}) {
  return ListView.separated(
    itemCount: items.length,
    padding: const EdgeInsets.all(10.0),
    separatorBuilder: (context, index) => const SizedBox(height: 10),
    itemBuilder: (context, index) {
      final word = items[index];
      return AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _onWordTapped(word),
          splashColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  word.word.isNotEmpty ? word.word[0] : '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                word.word, // Arabcha so'z
                textAlign: TextAlign.right,
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                word.translation,
                style: textTheme.bodyMedium?.copyWith(fontSize: 16),
              ),
              trailing: Icon(
                Icons.navigate_next_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    },
  );
}

void _onWordTapped(DictionaryWord word) {}
