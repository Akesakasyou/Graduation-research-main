import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRankingDetailPage extends StatelessWidget {
  final String animeId;

  const MyRankingDetailPage({
    super.key,
    required this.animeId,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("マイ評価詳細")),
      body: FutureBuilder(
        future: _loadData(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final myVote = data['myVote'];
          final globalAvg = data['globalAvg'];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  myVote['animeTitle'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle("あなたの評価"),
                Text("スコア：${myVote['score']} 点"),
                _buildStars(myVote['score']),
                const SizedBox(height: 8),
                Text("コメント："),
                Text(
                    myVote['comment'].isEmpty ? "（コメントなし）" : myVote['comment']),
                const SizedBox(height: 8),
                Text(
                  "総合ランキング反映：${myVote['includeGlobal'] ? "あり" : "なし"}",
                ),
                const Divider(height: 32),
                _sectionTitle("総合ランキングとの比較"),
                Text(
                  globalAvg == null
                      ? "まだ総合評価がありません"
                      : "総合平均：${globalAvg.toStringAsFixed(1)} 点",
                ),
                if (globalAvg != null) _buildStars(globalAvg),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("再評価する"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          await _deleteVote(uid);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("評価を削除しました")),
                          );
                        },
                        child: const Text("評価を削除"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =============================
  // データ取得
  // =============================
  Future<Map<String, dynamic>> _loadData(String uid) async {
    final myVoteDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('myVotes')
        .doc(animeId)
        .get();

    double? globalAvg;

    final globalSnap = await FirebaseFirestore.instance
        .collection('reviews')
        .doc(animeId)
        .collection('users')
        .where('includeGlobal', isEqualTo: true)
        .get();

    if (globalSnap.docs.isNotEmpty) {
      final scores = globalSnap.docs.map((e) => e['score'] as int).toList();
      globalAvg = scores.reduce((a, b) => a + b) / scores.length;
    }

    return {
      'myVote': myVoteDoc.data()!,
      'globalAvg': globalAvg,
    };
  }

  // =============================
  // 削除処理
  // =============================
  Future<void> _deleteVote(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('myVotes')
        .doc(animeId)
        .delete();

    await FirebaseFirestore.instance
        .collection('reviews')
        .doc(animeId)
        .collection('users')
        .doc(uid)
        .delete();
  }

  // =============================
  // UI パーツ
  // =============================
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStars(double score) {
    final star = (score / 100) * 5;

    return Row(
      children: List.generate(5, (i) {
        if (star >= i + 1) {
          return const Icon(Icons.star, color: Colors.amber);
        } else if (star > i) {
          return const Icon(Icons.star_half, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber);
        }
      }),
    );
  }
}
