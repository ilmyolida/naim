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
  int _themeMode = 0; // 0: Light, 1: Cream, 2: Dark

  // BottomNavigationBar'ning hozirgi index'i
  int _currentNavIndex = 0;

  bool _isLoading = true; // Yuklanish indikatori uchun
  List<DictionaryWord> _allWords = []; // Baza shu yerga yuklanadi

  @override
  void initState() {
    super.initState();
    _loadAllData(); // Ma'lumotlarni yuklashni chaqiramiz
    _checkAgreement();
    _themeMode = PreferencesManager.loadThemeMode();
    _isExactSearch = PreferencesManager.loadExactSearch();
    _isFuzzySearch = PreferencesManager.loadFuzzySearch();
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
                      label: const Text('Foydalanish shartlari'),
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
      _themeMode = PreferencesManager.loadThemeMode();
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
              tabs: [
                Tab(text: "Tarix"),
                Tab(text: "Sevimlilar"),
                Tab(text: "Saqlanganlar"),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).hintColor,
              indicatorColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          // Tarix
          Expanded(
            child: TabBarView(
              children: [
                // Tarix
                _historyResult.isEmpty
                    ? Center(
                        child: Text(
                          "Tarix bo'sh.",
                          style: textTheme.bodyMedium,
                        ),
                      )
                    : _buildWordList(_historyResult, textTheme, _onWordTapped),
                // Sevimlilar
                _favorites.isEmpty
                    ? Center(
                        child: Text(
                          "Sevimlilar bo'sh.",
                          style: textTheme.bodyMedium,
                        ),
                      )
                    : _buildWordList(_favorites, textTheme, _onWordTapped),
                // Saqlanganlar
                _saved.isEmpty
                    ? Center(
                        child: Text(
                          "Saqlanganlar bo'sh.",
                          style: textTheme.bodyMedium,
                        ),
                      )
                    : _buildWordList(_saved, textTheme, _onWordTapped),
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
    if (query.trim().isEmpty) {
      setState(() {
        _searchResult = [];
      });
      return;
    }

    final normalizedQuery = query.trim().toLowerCase();
    List<DictionaryWord> filteredWords = [];

    for (var word in _allWords) {
      bool isMatch = false;
      // Normalize both word and translation for robust matching
      final wordText = (word.word ?? '').toLowerCase();
      final translationText = (word.translation ?? '').toLowerCase();

      // 1. Exact match (handles all scripts)
      if (_isExactSearch) {
        if (wordText == normalizedQuery || translationText == normalizedQuery) {
          isMatch = true;
        }
      }

      // 2. Fuzzy match (contains, Unicode-aware)
      if (!isMatch && _isFuzzySearch) {
        if (wordText.contains(normalizedQuery) ||
            translationText.contains(normalizedQuery)) {
          isMatch = true;
        }
        // Also match if query is a number and appears anywhere
        if (!isMatch &&
            normalizedQuery.runes.every((r) => r >= 0x30 && r <= 0x39)) {
          if (wordText.contains(normalizedQuery) ||
              translationText.contains(normalizedQuery)) {
            isMatch = true;
          }
        }
      }

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
    final theme = _themeMode == 0
        ? AppTheme.lightTheme
        : _themeMode == 1
        ? AppTheme.softCreamTheme
        : ThemeData.dark();
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
                  _buildAboutPage(
                    textTheme,
                    context,
                    _isExactSearch,
                    _isFuzzySearch,
                  ),
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
              : _buildWordList(_searchResult, textTheme, _onWordTapped),
        ),
      ],
    );
  }

  // ignore: strict_top_level_inference
  _buildWordList(
    List<DictionaryWord> historyResult,
    TextTheme textTheme,
    void Function(DictionaryWord word) onWordTapped,
  ) {}

  /// Guruhlar ro'yxati ko'rsatilgan sahifa (image_0.png kabi)
  Widget _buildGroupsPage(
    TextTheme textTheme,
    BuildContext context,
    dynamic allWords,
  ) {
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

  Widget _buildAboutPage(
    TextTheme textTheme,
    BuildContext context,
    bool isExactSearch,
    bool isFuzzySearch,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Removed unused variable isSmall
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Safe Media company/news card
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.public, color: Colors.green),
                title: const Text('Safe Media'),
                subtitle: Text(
                  "Yangiliklar, kompaniya haqida ma'lumot va rasmiy e'lonlar bilan tanishing.",
                  style: textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.open_in_new, color: Colors.green),
                onTap: () async {
                  final url = Uri.parse("https://safemediaofficial-d25fa.web.app");
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
            ),
            // Theme and search settings
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
                        const Text('⚙️', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          "Qidiruv va Tema",
                          style: textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Search mode toggles
                    Row(
                      children: [
                        const Icon(Icons.search, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text("Aniq moslik:", style: textTheme.bodyMedium),
                        const SizedBox(width: 8),
                        Switch(
                          value: _isExactSearch,
                          activeThumbColor: Colors.green,
                          onChanged: (val) async {
                            await PreferencesManager.saveExactSearch(val);
                            setState(() {
                              _isExactSearch = val;
                            });
                          },
                        ),
                        const SizedBox(width: 18),
                        const Icon(Icons.blur_on, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text("O'xshashlik:", style: textTheme.bodyMedium),
                        const SizedBox(width: 8),
                        Switch(
                          value: _isFuzzySearch,
                          activeThumbColor: Colors.deepPurple,
                          onChanged: (val) async {
                            await PreferencesManager.saveFuzzySearch(val);
                            setState(() {
                              _isFuzzySearch = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Theme toggle
                    Row(
                      children: [
                        const Text('📖', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text("Mavzu:", style: textTheme.bodyMedium),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text("Light"),
                          selected: _themeMode == 0,
                          onSelected: (selected) async {
                            if (selected) {
                              await PreferencesManager.saveThemeMode(0);
                              setState(() {
                                _themeMode = 0;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text("Read"),
                          selected: _themeMode == 1,
                          onSelected: (selected) async {
                            if (selected) {
                              await PreferencesManager.saveThemeMode(1);
                              setState(() {
                                _themeMode = 1;
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text("Dark"),
                          selected: _themeMode == 2,
                          onSelected: (selected) async {
                            if (selected) {
                              await PreferencesManager.saveThemeMode(2);
                              setState(() {
                                _themeMode = 2;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Foydalanish shartlari card
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.verified_user, color: Colors.blue),
                title: const Text('Foydalanish shartlari'),
                subtitle: Text(
                  "Ilovadan foydalanish uchun shartlar bilan tanishing.",
                  style: textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.open_in_new, color: Colors.blue),
                onTap: () async {
                  final url = Uri.parse(
                    "https://ilmyolida.github.io/Naim-deployment-/Naim.html",
                  );
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
            ),
            // Maxfiylik siyosati card
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.teal),
                title: const Text('Maxfiylik siyosati'),
                subtitle: Text(
                  "Ma'lumotlaringiz xavfsizligi haqida.",
                  style: textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.open_in_new, color: Colors.teal),
                onTap: () async {
                  final url = Uri.parse(
                    "https://ilmyolida.github.io/privaciyn/naimp.html",
                  );
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
            ),
            // GitHub card
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.code, color: Colors.black),
                title: const Text('GitHub manbasi'),
                subtitle: Text(
                  "Loyiha kodlari va yangiliklar.",
                  style: textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.open_in_new, color: Colors.black),
                onTap: () async {
                  final url = Uri.parse("https://ilmyolida.github.io/");
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
            ),
            // Kirish card
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.login, color: Colors.deepPurple),
                title: const Text('Kirish sahifasi'),
                subtitle: Text(
                  "Lug'atga kirish uchun sahifa.",
                  style: textTheme.bodyMedium,
                ),
                trailing: const Icon(
                  Icons.open_in_new,
                  color: Colors.deepPurple,
                ),
                onTap: () async {
                  final url = Uri.parse(
                    "https://ilmyolida.github.io/Naim-deployment-/Naim.html",
                  );
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
            ),
            // Support card
            Card(
              margin: const EdgeInsets.only(bottom: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.support_agent, color: Colors.orange),
                title: const Text('Fikr-mulohaza va yordam'),
                subtitle: Text(
                  "Taklif va muammolar uchun bog'laning.",
                  style: textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.email, color: Colors.orange),
                onTap: () async {
                  final email = Uri(
                    scheme: 'mailto',
                    path: 'safemediaosupport@gmail.com',
                    query:
                        'subject=Naim%20Lugat%20Support%20%2F%20Fikr%20mulohaza',
                  );
                  await launchUrl(email, mode: LaunchMode.externalApplication);
                },
              ),
            ),
            // App info
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 80,
                    color: Color(0xFF00BFA5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Ilova haqida ma'lumot",
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "“An-Na’im al-Kubro” lug’ati arab tilini o'rganuvchilar va tadqiqotchilar uchun mo'ljallangan yirik hajmli manbadur.\n\nSiz bu ilova orqali lug'at tarkibidagi barcha so'zlarni 3ta asosiy guruhga ajratilgan holda ko'rishingiz mumkin: Fellar, Ismlar va Harflar. \n\nIlovadagi Qidiruv bo'limi sizga so'zni arabcha yoki o'zbekcha tarjimasiga ko'ra oson va tez topish imkonini beradi. Shuningdek, murakkab va fuzzy search (o'xshashlik) rejimlari ham mavjud.",
                    textAlign: TextAlign.justify,
                    style: textTheme.bodyLarge!.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 30),
                  Text("Versiya: 1.0.0", style: textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
