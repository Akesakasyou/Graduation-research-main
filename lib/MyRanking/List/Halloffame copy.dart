import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Widget buildStarRating(double score) {
  final star = (score / 100) * 5;

  return Row(
    children: List.generate(5, (index) {
      if (star >= index + 1) {
        return const Icon(Icons.star, color: Colors.amber, size: 16);
      } else if (star > index) {
        return const Icon(Icons.star_half, color: Colors.amber, size: 16);
      } else {
        return const Icon(Icons.star_border, color: Colors.amber, size: 16);
      }
    }),
  );
}

class Halloffame1 extends StatefulWidget {
  const Halloffame1({super.key});

  @override
  State<Halloffame1> createState() => _HalloffameState();
}

class _HalloffameState extends State<Halloffame1> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

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
    '恋愛': Colors.pink,
    '日常': Colors.yellow,
    'ファンタジー': Colors.purple,
    'SF': Colors.blue,
    'ホラー': Colors.black,
    'バトル': Colors.deepPurple,
  };

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
      'score': doc['score'], // Halloffame 内のスコア
    };
  });

  final result = await Future.wait(futures);

  return result.whereType<Map<String, dynamic>>().toList()
    ..sort((a, b) => b['score'].compareTo(a['score']));
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
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.65,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final data = list[index];

              final seasonsList = data['season'] is List
                  ? List<String>.from(data['season'])
                  : [data['season']];

              final genresList = data['genre'] is List
                  ? List<String>.from(data['genre'])
                  : [data['genre']];

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      (data['imageUrl'] ?? '').toString().isNotEmpty
                          ? Image.network(
                              data['imageUrl'],
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            )
                          : Container(
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

                      const SizedBox(height: 6),
                      const Text('制作年', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${data['year']}'),

                      const SizedBox(height: 4),
                      const Text('季節', style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 4,
                        children: seasonsList.map((s) {
                          return Chip(
                            label: Text(seasons[s] ?? s,
                                style: TextStyle(color: seasonColors[s])),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: seasonColors[s]!, width: 1),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 4),
                      const Text('ジャンル', style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: genresList.map((g) {
                          return Chip(
                            label: Text(g,
                                style: TextStyle(color: genreColors[g])),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: genreColors[g]!, width: 1),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 4),
                      const Text('あらすじ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['synopsis'] ?? '', maxLines: 3),

                      const Spacer(),

                      buildStarRating(data['score'].toDouble()),
                      Text(
                        'あなたの評価：${data['score']} 点',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
