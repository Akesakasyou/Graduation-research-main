import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ⭐ スター表示
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

class MyRankingPage extends StatefulWidget {
  final String animeId;
  final String title;

  const MyRankingPage({
    super.key,
    required this.animeId,
    required this.title,
  });

  @override
  State<MyRankingPage> createState() => _MyRankingPageState();
}

class _MyRankingPageState extends State<MyRankingPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  String? selectedGenre;
  String? selectedSeason;
  final TextEditingController yearController = TextEditingController();

  final genres = ['バトル', '恋愛', '日常', 'ファンタジー', 'SF', 'ホラー'];

  final seasons = {
    'spring': '春',
    'summer': '夏',
    'autumn': '秋',
    'winter': '冬',
  };

  Future<List<Map<String, dynamic>>> loadMyRanking() async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('Creatmypage')
      .doc(widget.animeId)
      .collection('votes')
      .get();

  return snap.docs.map((doc) {
    final data = doc.data();

    return {
      'score': (data['score'] as num).toDouble(),
      'title': widget.title,
      'imageUrl': '',
    };
  }).toList();
}




  /// =============================
  /// UI
  /// =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text(widget.title),
      ),
      body: Column(
        children: [
          /// 🔹 フィルターUI
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

                // 今期
                TextButton(
                  onPressed: () {
                    setState(() {
                      final now = DateTime.now();
                      yearController.text = now.year.toString();
                      final m = now.month;
                      if (m <= 3)
                        selectedSeason = 'winter';
                      else if (m <= 6)
                        selectedSeason = 'spring';
                      else if (m <= 9)
                        selectedSeason = 'summer';
                      else
                        selectedSeason = 'autumn';
                    });
                  },
                  child: const Text('今期'),
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

          /// 🔹 ランキング表示
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: loadMyRanking(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'この条件で評価した作品はありません',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
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
                            ? Image.network(
                                item['imageUrl'],
                                width: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported),
                        title: Text('${index + 1}位：${item['title']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('あなたの評価：${item['score']} 点'),
                            buildStarRating(item['score'].toDouble()),
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
