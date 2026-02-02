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

    if (selectedYearFilter != null) {
      animesQuery = animesQuery.where('year', isEqualTo: selectedYearFilter);
    }

    if (selectedSeasonFilter != null && selectedSeasonFilter!.isNotEmpty) {
      animesQuery =
          animesQuery.where('season', arrayContains: selectedSeasonFilter);
    }

    if (selectedGenresFilter.isNotEmpty) {
      animesQuery =
          animesQuery.where('genre', arrayContainsAny: selectedGenresFilter);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者画面'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: animesQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final title = (doc['title'] ?? '').toString().toLowerCase();
                  return title.contains(searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('検索条件に一致する作品はありません'));
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

<<<<<<< HEAD
    List<String> animeSeasons = [];
    if (data['season'] != null) {
      animeSeasons = data['season'] is List
          ? List<String>.from(data['season'])
          : [data['season'].toString()];
    }

    List<String> animeGenres = [];
    if (data['genre'] != null) {
      animeGenres = data['genre'] is List
          ? List<String>.from(data['genre'])
          : [data['genre'].toString()];
    }

    return Card(
  margin: const EdgeInsets.all(8),
  child: Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 画像
        if ((data['imageUrl'] ?? '').toString().isNotEmpty)
          Image.network(
            data['imageUrl'],
            width: double.infinity,
            height: 150,
            fit: BoxFit.cover,
          )
        else
          Container(
            width: double.infinity,
            height: 150,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 50),
          ),
        const SizedBox(height: 8),

        // タイトル
        Text(
          data['title'] ?? '',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Divider(), // タイトルの下に区切り線

        // シーズン
        if (animeSeasons.isNotEmpty)
          Wrap(
            spacing: 4,
            children: animeSeasons.map((s) => Chip(
              label: Text(seasons[s] ?? s, style: TextStyle(color: seasonColors[s])),
              backgroundColor: Colors.white,
              side: BorderSide(color: seasonColors[s]!, width: 1),
            )).toList(),
          ),
        if (animeSeasons.isNotEmpty) const Divider(), // シーズンの下に区切り線

        // ジャンル
        if (animeGenres.isNotEmpty)
          Wrap(
            spacing: 4,
            children: animeGenres.map((g) => Chip(
              label: Text(g, style: TextStyle(color: genreColors[g])),
              backgroundColor: Colors.white,
              side: BorderSide(color: genreColors[g]!, width: 1),
            )).toList(),
          ),
        if (animeGenres.isNotEmpty) const Divider(), // ジャンルの下に区切り線

        const SizedBox(height: 4),

        // あらすじ（スクロール可能）
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              data['synopsis']?.toString() ?? 'あらすじなし',
              style: const TextStyle(height: 1.4),
            ),
          ),
        ),
        const Divider(), // あらすじの下に区切り線

        // 編集・削除ボタン
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




=======
                    return Card(
                      child: Column(
                        children: [
                          Text(
                            data['title'] ?? '',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showEditAnimeDialog(context, anime),
                              ),
                              const Spacer(),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
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
                    );
                  },
                );
>>>>>>> b477b305d79ed3f39089b084b64e6eb8e93d90b2
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAnimeDialog(BuildContext context) {}
  void _showEditAnimeDialog(
      BuildContext context, QueryDocumentSnapshot anime) {}

  Widget _field(TextEditingController c, String label, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: c,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
