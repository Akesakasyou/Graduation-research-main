import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ⭐ スター表示（0〜100 → 5段階）
Widget buildStarRating(double score) {
  final star = (score / 100) * 5;

  return Row(
    children: List.generate(5, (index) {
      if (star >= index + 1) {
        return const Icon(Icons.star, color: Colors.amber, size: 18);
      } else if (star > index) {
        return const Icon(Icons.star_half, color: Colors.amber, size: 18);
      } else {
        return const Icon(Icons.star_border, color: Colors.amber, size: 18);
      }
    }),
  );
}

enum RankSortType {
  average,
  votes,
}

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  String? selectedGenre;
  String? selectedSeason;
  final TextEditingController yearController = TextEditingController();

  RankSortType sortType = RankSortType.average;

  final genres = ['バトル', '恋愛', '日常', 'ファンタジー', 'SF', 'ホラー'];

  final seasons = {
    'spring': '春',
    'summer': '夏',
    'autumn': '秋',
    'winter': '冬',
  };

  /// =============================
  /// ランキング取得
  /// =============================
  Future<List<Map<String, dynamic>>> loadRanking() async {
    Query query = FirebaseFirestore.instance.collection('animes');

    if (selectedGenre != null) {
      query = query.where('genre', isEqualTo: selectedGenre);
    }
    if (selectedSeason != null) {
      query = query.where('season', isEqualTo: selectedSeason);
    }
    if (yearController.text.isNotEmpty) {
      final year = int.tryParse(yearController.text);
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
    }

    final animeSnap = await query.get();
    final futures = animeSnap.docs.map(_loadAnimeStats).toList();
    final results = await Future.wait(futures);

    final list = results.whereType<Map<String, dynamic>>().toList();

    /// 並び替え
    if (sortType == RankSortType.average) {
      list.sort((a, b) => b['average'].compareTo(a['average']));
    } else {
      list.sort((a, b) => b['votes'].compareTo(a['votes']));
    }

    return list;
  }

  /// =============================
  /// 1作品の平均点 & 投票数
  /// =============================
  Future<Map<String, dynamic>?> _loadAnimeStats(
      QueryDocumentSnapshot anime) async {
    final animeId = anime.id;

    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .doc(animeId)
        .collection('users')
        .where('includeGlobal', isEqualTo: true)
        .get();

    if (snap.docs.isEmpty) return null;

    final scores = snap.docs.map((e) => e['score'] as int).toList();
    final average = scores.reduce((a, b) => a + b) / scores.length;

    return {
      'animeId': animeId,
      'title': anime['title'],
      'imageUrl': anime['imageUrl'] ?? '',
      'average': average,
      'votes': scores.length,
    };
  }

  /// =============================
  /// UI
  /// =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('総合ランキング'),
        actions: [
          PopupMenuButton<RankSortType>(
            onSelected: (v) => setState(() => sortType = v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: RankSortType.average,
                child: Text('平均点順'),
              ),
              PopupMenuItem(
                value: RankSortType.votes,
                child: Text('投票数順'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          /// フィルター
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                DropdownButton<String>(
                  hint: const Text('ジャンル'),
                  value: selectedGenre,
                  items: genres
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedGenre = v),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '年'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                DropdownButton<String>(
                  hint: const Text('季節'),
                  value: selectedSeason,
                  items: seasons.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => selectedSeason = v),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedGenre = null;
                      selectedSeason = null;
                      yearController.clear();
                    });
                  },
                  child: const Text('リセット'),
                ),
              ],
            ),
          ),

          const Divider(),

          /// ランキング
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: loadRanking(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('該当データがありません'));
                }

                final list = snapshot.data!;

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];

                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: item['imageUrl'] != ''
                            ? Image.network(item['imageUrl'],
                                width: 60, fit: BoxFit.cover)
                            : const Icon(Icons.image_not_supported),
                        title: Text('${index + 1}位：${item['title']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '平均 ${item['average'].toStringAsFixed(1)} 点'
                              '（${item['votes']} 票）',
                            ),
                            buildStarRating(item['average']),
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
}
