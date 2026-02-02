import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/Evaluation/Vreview.dart';

/// ⭐ スター表示
Widget buildStarRating(double score) {
  final star = (score / 100) * 5;

  return Row(
    children: List.generate(5, (index) {
      if (star >= index + 1) {
        return const Icon(Icons.star, color: Colors.amber, size: 60);
      } else if (star > index) {
        return const Icon(Icons.star_half, color: Colors.amber, size: 60);
      } else {
        return const Icon(Icons.star_border, color: Colors.amber, size: 60);
      }
    }),
  );
}

class ListDetailPage extends StatefulWidget {
  final String animeId;
  final String title;
  final String voteId; 

  const ListDetailPage({
    super.key,
    required this.animeId,
    required this.title,
    required this.voteId, 
  });

  @override
  State<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  Map<String, dynamic>? myVote;     // 自分の評価
  Map<String, dynamic>? animeData; // 作品データ（画像）

  Future<void> loadDetail() async {
  final animeSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('Creatmypage')
      .doc(widget.animeId)
      .get();

  final voteSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('Creatmypage')
      .doc(widget.animeId)
      .collection('votes')
      .doc(widget.voteId)
      .get();

  setState(() {
    animeData = animeSnap.data() ?? {};
    myVote = voteSnap.data() ?? {};
  });
}


  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    if (animeData == null || myVote == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 画像 + スコア
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 画像（作品側）
                animeData!['imageUrl'] != null && animeData!['imageUrl'] != ''
                    ? Image.network(
                        animeData!['imageUrl'],
                        width: 800,
                        height: 400,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 800,
                        height: 400,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 60),
                      ),

                const SizedBox(width: 16),

                // スコア
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'あなたの評価',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${myVote!['score'] ?? 0} 点',
                        style: const TextStyle(
                            fontSize: 60, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      buildStarRating((myVote!['score'] ?? 0).toDouble()),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // タイトル
            Text(
              widget.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // 感想
            const Text(
              '感想',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              myVote!['comment'] != null && myVote!['comment'] != ''
                  ? myVote!['comment']
                  : '記入されていません。',
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            // 編集ボタン
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VotePage(animeId: widget.animeId),
                    ),
                  );

                  if (updated == true) {
                    await loadDetail();
                  }
                },
                child: const Text('レビュー編集'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
