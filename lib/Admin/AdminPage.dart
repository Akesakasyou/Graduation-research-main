import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  static const seasons = {
    'spring': '春',
    'summer': '夏',
    'autumn': '秋',
    'winter': '冬',
  };

  static const genres = [
    'アクション',
    'コメディ',
    'ドラマ',
    'ファンタジー',
    'SF',
    '恋愛',
    'バトル',
    '戦闘',
    '格闘技',
    'スポーツ',
    '異世界',
    '転生',
    '魔法少女',
    '魔法系',
    '勇者',
    'ロボット',
    'メカ',
    '宇宙',
    'サスペンス',
    'ホラー',
    'ラブコメ',
    '学園',
    '日常系',
    '青春',
    '音楽',
    '料理',
    'ハーレム',
    '歴史',
    'AI',
  ];

  final List<int> years = [for (var y = 2000; y <= 2030; y++) y];

  static const Map<String, Color> seasonColors = {
    'spring': Colors.pink,
    'summer': Colors.green,
    'autumn': Colors.orange,
    'winter': Colors.lightBlue,
  };

  static const Map<String, Color> genreColors = {
    'アクション': Colors.red,
    'コメディ': Colors.orange,
    'ドラマ': Colors.brown,
    'ファンタジー': Colors.purple,
    'SF': Colors.blue,
    '恋愛': Colors.pink,
    'バトル': Colors.deepPurple,
    '戦闘': Colors.indigo,
    '格闘技': Colors.teal,
    'スポーツ': Colors.green,
    '異世界': Colors.deepOrange,
    '転生': Colors.purpleAccent,
    '魔法少女': Colors.pinkAccent,
    '魔法系': Colors.indigoAccent,
    '勇者': Colors.lime,
    'ロボット': Colors.grey,
    'メカ': Colors.blueAccent,
    '宇宙': Colors.indigo,
    'サスペンス': Colors.redAccent,
    'ホラー': Colors.black,
    'ラブコメ': Colors.pink,
    '学園': Colors.lightBlue,
    '日常系': Colors.yellow,
    '青春': Colors.lime,
    '音楽': Colors.orangeAccent,
    '料理': Colors.orange,
    'ハーレム': Colors.pink,
    '歴史': Colors.brown,
    'AI': Colors.cyan,
  };

  String searchQuery = '';
  String? selectedSeasonFilter;
  List<String> selectedGenresFilter = [];
  int? selectedYearFilter;

  @override
  Widget build(BuildContext context) {
    Query animesQuery = FirebaseFirestore.instance
        .collection('animes')
        .orderBy('createdAt', descending: true);

    // 年フィルター
    if (selectedYearFilter != null) {
      animesQuery = animesQuery.where('year', isEqualTo: selectedYearFilter);
    }

    // 季節フィルター（配列対応）
    if (selectedSeasonFilter != null && selectedSeasonFilter!.isNotEmpty) {
      animesQuery = animesQuery.where('season', arrayContains: selectedSeasonFilter);
    }

    // ジャンルフィルター（OR条件）
    if (selectedGenresFilter.isNotEmpty) {
      animesQuery = animesQuery.where('genre', arrayContainsAny: selectedGenresFilter);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者画面'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 検索バー + 追加ボタン
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'タイトル検索',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showAddAnimeDialog(context),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),

          // フィルター
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'ジャンル'),
                    value: selectedGenresFilter.isNotEmpty
                        ? selectedGenresFilter.first
                        : null,
                    items: [null, ...genres].map((g) {
                      return DropdownMenuItem(
                        value: g,
                        child: Text(
                          g ?? '全て',
                          style: g != null ? TextStyle(color: genreColors[g]) : null,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedGenresFilter = val != null ? [val] : [];
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: '制作年'),
                    value: selectedYearFilter,
                    items: [null, ...years].map((y) {
                      return DropdownMenuItem(
                        value: y,
                        child: Text(y?.toString() ?? '全て'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedYearFilter = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: '季節'),
                    value: selectedSeasonFilter,
                    items: [null, ...seasons.keys].map((seasonKey) {
                      return DropdownMenuItem(
                        value: seasonKey,
                        child: Text(
                          seasonKey != null ? seasons[seasonKey]! : '全て',
                          style: seasonKey != null
                              ? TextStyle(color: seasonColors[seasonKey])
                              : null,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedSeasonFilter = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedGenresFilter.clear();
                      selectedSeasonFilter = null;
                      selectedYearFilter = null;
                    });
                  },
                  child: const Text('リセット'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 作品表示
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: animesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('作品がまだありません'));
                }

                // タイトル検索 + ANDジャンル
                final docs = snapshot.data!.docs.where((doc) {
                  final title = (doc['title'] ?? '').toString().toLowerCase();
                  final genresList = doc['genre'] != null
                      ? List<String>.from(doc['genre'])
                      : <String>[];
                  final matchGenres =
                      selectedGenresFilter.every((g) => genresList.contains(g));
                  return title.contains(searchQuery) && matchGenres;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                      child: Text('検索条件に一致する作品はありません'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final anime = docs[index];
                    final data = anime.data() as Map<String, dynamic>;

                    List<String> animeSeasons = [];
                    if (data['season'] != null) {
                      if (data['season'] is List) {
                        animeSeasons = List<String>.from(data['season']);
                      } else {
                        animeSeasons = [data['season'].toString()];
                      }
                    }

                    List<String> animeGenres = [];
                    if (data['genre'] != null) {
                      if (data['genre'] is List) {
                        animeGenres = List<String>.from(data['genre']);
                      } else {
                        animeGenres = [data['genre'].toString()];
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            (data['imageUrl'] ?? '').toString().isNotEmpty
                                ? Image.network(
                                    data['imageUrl'],
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        width: double.infinity,
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: const Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: double.infinity,
                                        height: 150,
                                        color: Colors.grey[300],
                                        child:
                                            const Icon(Icons.broken_image, size: 50),
                                      );
                                    },
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 150,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 50),
                                  ),
                            const SizedBox(height: 8),
                            Text(
                              data['title'] ?? '',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('制作年', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${data['year'] ?? '-'}'),
                            const SizedBox(height: 4),

                            if (animeSeasons.isNotEmpty) ...[
                              const Text('季節', style: TextStyle(fontWeight: FontWeight.bold)),
                              Wrap(
                                spacing: 4,
                                children: animeSeasons.map((s) {
                                  return Chip(
                                    label: Text(seasons[s] ?? s,
                                        style: TextStyle(color: seasonColors[s])),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: seasonColors[s]!, width: 1),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 4),
                            ],

                            if (animeGenres.isNotEmpty) ...[
                              const Text('ジャンル', style: TextStyle(fontWeight: FontWeight.bold)),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: animeGenres.map((g) {
                                  return Chip(
                                    label: Text(g, style: TextStyle(color: genreColors[g])),
                                    backgroundColor: Colors.white,
                                    side: BorderSide(color: genreColors[g]!, width: 1),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 4),
                            ],

                            if ((data['synopsis'] ?? '').toString().isNotEmpty) ...[
                              const Text('あらすじ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(data['synopsis'], style: const TextStyle(height: 1.4)),
                            ],

                            const Spacer(),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showEditAnimeDialog(context, anime),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('animes')
                                        .doc(anime.id)
                                        .delete();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  // 作品追加
  // =============================
  void _showAddAnimeDialog(BuildContext context) {
    final imageUrl = TextEditingController();
    final title = TextEditingController();
    final synopsis = TextEditingController();

    List<String>? selectedSeason;
    List<String> selectedGenres = [];
    int? selectedYear;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('作品追加'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _field(imageUrl, '画像URL'),
                    _field(title, 'タイトル'),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: '制作年'),
                      value: selectedYear,
                      items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                      onChanged: (val) => setDialogState(() => selectedYear = val),
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: const Text('季節')),
                    Wrap(
                      spacing: 4,
                      children: seasons.keys.map((s) {
                        final selected = selectedSeason?.contains(s) ?? false;
                        return FilterChip(
                          label: Text(seasons[s]!, style: TextStyle(color: seasonColors[s])),
                          selected: selected,
                          backgroundColor: Colors.white,
                          selectedColor: Colors.white,
                          side: BorderSide(color: seasonColors[s]!, width: 1),
                          onSelected: (val) {
                            setDialogState(() {
                              if (selectedSeason == null) selectedSeason = [];
                              if (val) selectedSeason!.add(s);
                              else selectedSeason!.remove(s);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: const Text('ジャンル')),
                    Wrap(
                      spacing: 4,
                      children: genres.map((g) {
                        final selected = selectedGenres.contains(g);
                        return FilterChip(
                          label: Text(g, style: TextStyle(color: genreColors[g])),
                          selected: selected,
                          backgroundColor: Colors.white,
                          selectedColor: Colors.white,
                          side: BorderSide(color: genreColors[g]!, width: 1),
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) selectedGenres.add(g);
                              else selectedGenres.remove(g);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    _field(synopsis, 'あらすじ', lines: 4),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                ElevatedButton(
                  child: const Text('追加'),
                  onPressed: () async {
                    if (title.text.trim().isEmpty ||
                        selectedYear == null ||
                        selectedSeason == null ||
                        selectedSeason!.isEmpty ||
                        selectedGenres.isEmpty) return;

                    await FirebaseFirestore.instance.collection('animes').add({
                      'imageUrl': imageUrl.text.trim(),
                      'title': title.text.trim(),
                      'genre': selectedGenres,
                      'season': selectedSeason,
                      'year': selectedYear,
                      'synopsis': synopsis.text.trim(),
                      'averageScore': 0.0,
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =============================
  // 作品編集
  // =============================
  void _showEditAnimeDialog(BuildContext context, QueryDocumentSnapshot anime) {
    final data = anime.data() as Map<String, dynamic>;
    final imageUrl = TextEditingController(text: data['imageUrl'] ?? '');
    final title = TextEditingController(text: data['title'] ?? '');
    final synopsis = TextEditingController(text: data['synopsis'] ?? '');

    int? selectedYear = years.contains(data['year']) ? data['year'] : null;
    List<String>? selectedSeason;
    if (data['season'] != null) {
      selectedSeason = data['season'] is List ? List<String>.from(data['season']) : [data['season'].toString()];
    }

    List<String> selectedGenres = [];
    if (data['genre'] != null) {
      selectedGenres = data['genre'] is List ? List<String>.from(data['genre']) : [data['genre'].toString()];
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('作品編集'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _field(imageUrl, '画像URL'),
                    _field(title, 'タイトル'),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: '制作年'),
                      value: selectedYear,
                      items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                      onChanged: (val) => setDialogState(() => selectedYear = val),
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: const Text('季節')),
                    Wrap(
                      spacing: 4,
                      children: seasons.keys.map((s) {
                        final selected = selectedSeason?.contains(s) ?? false;
                        return FilterChip(
                          label: Text(seasons[s]!, style: TextStyle(color: seasonColors[s])),
                          selected: selected,
                          backgroundColor: Colors.white,
                          selectedColor: Colors.white,
                          side: BorderSide(color: seasonColors[s]!, width: 1),
                          onSelected: (val) {
                            setDialogState(() {
                              if (selectedSeason == null) selectedSeason = [];
                              if (val) selectedSeason!.add(s);
                              else selectedSeason!.remove(s);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: const Text('ジャンル')),
                    Wrap(
                      spacing: 4,
                      children: genres.map((g) {
                        final selected = selectedGenres.contains(g);
                        return FilterChip(
                          label: Text(g, style: TextStyle(color: genreColors[g])),
                          selected: selected,
                          backgroundColor: Colors.white,
                          selectedColor: Colors.white,
                          side: BorderSide(color: genreColors[g]!, width: 1),
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) selectedGenres.add(g);
                              else selectedGenres.remove(g);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    _field(synopsis, 'あらすじ', lines: 4),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                ElevatedButton(
                  child: const Text('保存'),
                  onPressed: () async {
                    if (title.text.trim().isEmpty ||
                        selectedYear == null ||
                        selectedSeason == null ||
                        selectedSeason!.isEmpty ||
                        selectedGenres.isEmpty) return;

                    await FirebaseFirestore.instance.collection('animes').doc(anime.id).update({
                      'imageUrl': imageUrl.text.trim(),
                      'title': title.text.trim(),
                      'genre': selectedGenres,
                      'season': selectedSeason,
                      'year': selectedYear,
                      'synopsis': synopsis.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =============================
  // 入力欄ウィジェット
  // =============================
  Widget _field(TextEditingController c, String label, {int lines = 1, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
