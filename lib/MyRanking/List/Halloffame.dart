import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ===============================
/// スター評価
/// ===============================
Widget buildStarRating(double score) {
  final star = (score / 100) * 5;

  return Row(
    children: List.generate(5, (index) {
      if (star >= index + 1) {
        return const Icon(Icons.star, color: Colors.amber, size: 14);
      } else if (star > index) {
        return const Icon(Icons.star_half, color: Colors.amber, size: 14);
      } else {
        return const Icon(Icons.star_border, color: Colors.amber, size: 14);
      }
    }),
  );
}

/// ===============================
/// 殿堂入りページ
/// ===============================
class Halloffame extends StatefulWidget {
  const Halloffame({super.key});

  @override
  State<Halloffame> createState() => _HalloffameState();
}

class _HalloffameState extends State<Halloffame> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> loadHallOfFame() async {
    final hall = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Halloffame')
        .get();

    final futures = hall.docs.map((doc) async {
      final animeDoc = await FirebaseFirestore.instance
          .collection('animes')
          .doc(doc.id)
          .get();

      if (!animeDoc.exists) return null;

      final anime = animeDoc.data()!;
      return {
        ...anime,
        'score': doc['score'] ?? 0,
      };
    });

    final result = await Future.wait(futures);

    return result.whereType<Map<String, dynamic>>().toList()
      ..sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('殿堂入り')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: loadHallOfFame(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.6,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final data = list[index];
              final score = ((data['score'] ?? 0) as num).toDouble();

              return _HallOfFameCard(
                title: data['title'] ?? '',
                imageUrl: data['imageUrl'],
                score: score,
                synopsis: data['synopsis'],
              );
            },
          );
        },
      ),
    );
  }
}

/// ===============================
/// 殿堂入りカード
/// ===============================
class _HallOfFameCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final double score;
  final String? synopsis;

  const _HallOfFameCard({
    required this.title,
    required this.imageUrl,
    required this.score,
    required this.synopsis,
  });

  @override
  Widget build(BuildContext context) {
    final displaySynopsis =
        (synopsis == null || synopsis!.trim().isEmpty)
            ? 'あらすじが登録されていません。'
            : synopsis!;

    return SizedBox(
      height: 300, // カード全体の高さを固定
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFFF4C1),
              Color(0xFFFFD700),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // 画像
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                  ),

                  // タイトル・点数・あらすじ部分
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // タイトル
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          // 点数
                          Text(
                            '${score.toInt()} 点',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          buildStarRating(score),
                          const Divider(),
                          // あらすじ（スクロール可能）
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                displaySynopsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: synopsis == null || synopsis!.trim().isEmpty
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 殿堂入りバッジ
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '殿堂入り',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
