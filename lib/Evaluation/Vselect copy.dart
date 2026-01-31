import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Vreview.dart';

class VoteSelectPage1 extends StatefulWidget {
  const VoteSelectPage1({super.key});

  @override
  State<VoteSelectPage1> createState() => _VoteSelectPage1State();
}

class _VoteSelectPage1State extends State<VoteSelectPage1> {
  /// フィルター用
  String? selectedGenre;
  String? selectedSeason;
  final TextEditingController yearController = TextEditingController();

  static const seasons = {
    'spring': '春',
    'summer': '夏',
    'autumn': '秋',
    'winter': '冬',
  };

  final genres = ['アクション', 'ファンタジー', 'SF', '恋愛']; // サンプル

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

          /// アニメ一覧（4列グリッド）
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('animes')
                  .orderBy('title')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                /// フィルター適用
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final genre = data['genre'] as String?;
                  final year = data['year']?.toString();
                  final season = data['season'] as String?;

                  if (selectedGenre != null && genre != selectedGenre) return false;
                  if (selectedSeason != null && season != selectedSeason) return false;
                  if (yearController.text.isNotEmpty && year != yearController.text) return false;

                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('条件に合う作品がありません'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,      // 4列
                    crossAxisSpacing: 8,    // 列間のスペース
                    mainAxisSpacing: 8,     // 行間のスペース
                    childAspectRatio: 0.7,  // 高さ調整（画像＋タイトルの比率）
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

  /// アニメカードウィジェット
  Widget _animeCard(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Expanded(
            child: (data['image'] ?? '').toString().isNotEmpty
                ? Image.network(
                    data['image'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _noImage(),
                  )
                : _noImage(),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              data['title'] ?? '',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// 画像なし時
  Widget _noImage() {
    return Container(
      color: Colors.grey,
      child: const Center(child: Text('No Image')),
    );
  }
}
