import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Vreview.dart'; // VotePage 用のページ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SelectPage());
}

class SelectPage extends StatelessWidget {
  const SelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'アニメ投票',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const VoteSelectPage(),
    );
  }
}

class VoteSelectPage extends StatefulWidget {
  const VoteSelectPage({super.key});

  @override
  State<VoteSelectPage> createState() => _VoteSelectPageState();
}

class _VoteSelectPageState extends State<VoteSelectPage> {
  // 検索・フィルター
  String searchQuery = '';
  String? selectedGenre;
  String? selectedSeason;
  int? selectedYear;
  final TextEditingController yearController = TextEditingController();

  static const seasons = {
    'spring': '春',
    'summer': '夏',
    'autumn': '秋',
    'winter': '冬',
  };

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

  final genres = genreColors.keys.toList();
  final List<int> years = [for (var y = 2000; y <= 2030; y++) y];

  @override
  void dispose() {
    yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('投票する作品を選択')),
      body: Column(
        children: [
          // 検索バー + フィルター
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // 検索バー
                SizedBox(
                  width: double.infinity,
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
                const SizedBox(height: 8),
                // フィルター行
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'ジャンル'),
                        value: selectedGenre,
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
                            selectedGenre = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: '制作年'),
                        value: selectedYear,
                        items: [null, ...years].map((y) {
                          return DropdownMenuItem(
                            value: y,
                            child: Text(y?.toString() ?? '全て'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedYear = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: '季節'),
                        value: selectedSeason,
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
                            selectedSeason = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                          selectedGenre = null;
                          selectedSeason = null;
                          selectedYear = null;
                          yearController.clear();
                        });
                      },
                      child: const Text('リセット'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // アニメ一覧（AdminPage と同じカード表示）
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('animes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final genresList = (data['genre'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
                  final seasonsList = (data['season'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
                  final year = data['year']?.toString();
                  final title = (data['title'] ?? '').toString().toLowerCase();

                  if (searchQuery.isNotEmpty && !title.contains(searchQuery)) return false;
                  if (selectedGenre != null && !genresList.contains(selectedGenre)) return false;
                  if (selectedSeason != null && !seasonsList.contains(selectedSeason)) return false;
                  if (selectedYear != null && year != selectedYear.toString()) return false;

                  return true;
                }).toList();

                if (filteredDocs.isEmpty) return const Center(child: Text('条件に合う作品がありません'));

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>? ?? {};
                    final docId = filteredDocs[index].id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VotePage(animeId: docId),
                          ),
                        );
                      },
                      child: _animeCard(data),
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

  Widget _animeCard(Map<String, dynamic> data) {
  List<String> animeSeasons = (data['season'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  List<String> animeGenres = (data['genre'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();

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
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('制作年', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${data['year'] ?? '-'}'),
          const SizedBox(height: 4),

          if (animeSeasons.isNotEmpty) ...[
            const Text('季節', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 4,
              children: animeSeasons.map((seasonKey) {
                return Chip(
                  label: Text(
                    _VoteSelectPageState.seasons[seasonKey] ?? seasonKey,
                    style: TextStyle(color: _VoteSelectPageState.seasonColors[seasonKey]),
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: _VoteSelectPageState.seasonColors[seasonKey] ?? Colors.grey,
                    width: 1,
                  ),
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
                  label: Text(g, style: TextStyle(color: _VoteSelectPageState.genreColors[g])),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                      color: _VoteSelectPageState.genreColors[g] ?? Colors.grey,
                      width: 1),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
          ],

          if ((data['synopsis'] ?? '').toString().isNotEmpty) ...[
            const Text('あらすじ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data['synopsis'], style: const TextStyle(height: 1.4)),
          ],
        ],
      ),
    ),
  );
 }
}
