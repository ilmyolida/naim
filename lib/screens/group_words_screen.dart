import 'package:flutter/material.dart';
import '../models/word_model.dart';

class GroupWordsScreen extends StatefulWidget {
  final String groupTitle;
  final List<DictionaryWord> words;
  const GroupWordsScreen({super.key, required this.groupTitle, required this.words});

  @override
  State<GroupWordsScreen> createState() => _GroupWordsScreenState();
}

class _GroupWordsScreenState extends State<GroupWordsScreen> {
  late List<DictionaryWord> _filteredWords;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredWords = widget.words;
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    setState(() {
      _filteredWords = widget.words.where((w) =>
        w.word.contains(query) || w.translation.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupTitle, style: textTheme.headlineMedium),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Guruhdan izlang...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.08),
              ),
            ),
          ),
          Expanded(
            child: _filteredWords.isEmpty
                ? Center(child: Text("Hech nima topilmadi", style: textTheme.bodyMedium))
                : ListView.separated(
                    itemCount: _filteredWords.length,
                    padding: const EdgeInsets.all(10),
                    separatorBuilder: (c, i) => const SizedBox(height: 8),
                    itemBuilder: (c, i) {
                      final word = _filteredWords[i];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: ListTile(
                          title: Text(word.word, textAlign: TextAlign.right, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text(word.translation, style: textTheme.bodyMedium),
                          onTap: () {
                            // Tafsilot sahifasiga o'tish
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
