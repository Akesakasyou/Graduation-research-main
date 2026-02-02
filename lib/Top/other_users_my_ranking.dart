import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Top/other_user_ranking_detail.dart';

class OtherUsersMyRanking extends StatelessWidget {
  const OtherUsersMyRanking({super.key});

  /// =========================
  /// 他ユーザーのランキングを
  /// ユーザー単位でまとめて取得
  /// userId -> ランキング一覧
  /// =========================
  Future<Map<String, List<Map<String, dynamic>>>> _getGroupedRankings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    Map<String, List<Map<String, dynamic>>> results = {};

    for (final userDoc in usersSnapshot.docs) {
      if (userDoc.id == currentUser?.uid) continue;

      final userName = userDoc.data()['name'] ?? '名無し';

      final rankingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('Creatmypage')
          .get();

      if (rankingSnapshot.docs.isEmpty) continue;

      results[userDoc.id] = rankingSnapshot.docs.map((doc) {
        final data = doc.data();
        data['userName'] = userName;
        return data;
      }).toList();
    }

    return results;
  }

  /// =========================
  /// 1ユーザー = 1カード
  /// =========================
  Widget _buildUserCard(
    BuildContext context,
    String userId,
    List<Map<String, dynamic>> rankings,
  ) {
    final first = rankings.first;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherUserRankingDetailPage(userId: userId),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              first['userName'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            /// 代表画像
            first['images'] != null
                ? Image.network(
                    first['images'],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: const Center(child: Text("No Image")),
                  ),

            const SizedBox(height: 8),
            Text('ランキング数：${rankings.length}'),
            const Spacer(),
            const Text(
              'タップして詳細を見る',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "～ 他ユーザーのマイランキング ～",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
            future: _getGroupedRankings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("表示するランキングがありません"));
              }

              final userIds = snapshot.data!.keys.toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: userIds.length,
                itemBuilder: (context, index) {
                  final userId = userIds[index];
                  final rankings = snapshot.data![userId]!;

                  return _buildUserCard(context, userId, rankings);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
//