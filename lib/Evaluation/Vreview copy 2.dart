import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VotePage extends StatefulWidget {
  final String animeId;

  const VotePage({super.key, required this.animeId});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final _commentController = TextEditingController();
  final _scoreController = TextEditingController();
  int _score = 0;
  bool _includeGlobal = false;
  bool _includeMyRanking = true;
  bool _loading = true;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String _animeTitle = '';
  String _animeImageUrl = '';

  @override
  void initState() {
    super.initState();
    _scoreController.text = '$_score';
    _loadMyReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _loadMyReview() async {
    try {
      final votesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Creatmypage')
          .doc(widget.animeId)
          .collection('votes')
          .where('userId', isEqualTo: uid)
          .get();

      if (votesSnap.docs.isNotEmpty) {
        final sorted = votesSnap.docs.toList()
          ..sort((a, b) {
            final aTime = a['createdAt'] ?? Timestamp(0, 0);
            final bTime = b['createdAt'] ?? Timestamp(0, 0);
            return bTime.compareTo(aTime);
          });

        final latest = sorted.first.data();
        _score = latest['score'] ?? 0;
        _scoreController.text = '$_score';
        _commentController.text = latest['comment'] ?? '';
        _includeGlobal = latest['includeGlobal'] ?? false;
        _includeMyRanking = latest['includeMyRanking'] ?? true;
      }

      final animeDoc = await FirebaseFirestore.instance
          .collection('animes')
          .doc(widget.animeId)
          .get();

      if (animeDoc.exists) {
        final data = animeDoc.data()!;
        _animeTitle = data['title'] ?? '';
        _animeImageUrl = data['imageUrl'] ?? '';
      }
    } catch (e) {
      print("レビュー読み込みエラー: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateAverageScore() async {
    try {
      final snap = await FirebaseFirestore.instance.collectionGroup('votes').get();
      final scores = snap.docs
          .where((d) => (d['includeGlobal'] ?? false) == true)
          .where((d) => d.reference.parent.parent?.id == widget.animeId)
          .map((d) => (d['score'] ?? 0) as int)
          .toList();
      if (scores.isEmpty) return;
      final avg = scores.reduce((a, b) => a + b) / scores.length;

      await FirebaseFirestore.instance.collection('animes').doc(widget.animeId).update({
        'averageScore': avg,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("平均スコア更新エラー: $e");
    }
  }

  Future<void> _saveReviewToMyRanking(String creatmypageDocId) async {
    final votesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Creatmypage')
        .doc(creatmypageDocId)
        .collection('votes');

    await votesRef.add({
      'userId': uid,
      'score': _score,
      'comment': _commentController.text,
      'includeGlobal': _includeGlobal,
      'includeMyRanking': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _updateAverageScore();
  }

  Future<void> _saveReview() async {
    final votesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Creatmypage')
        .doc(widget.animeId)
        .collection('votes');

    final existing = await votesRef
        .where('userId', isEqualTo: uid)
        .where('score', isEqualTo: _score)
        .where('comment', isEqualTo: _commentController.text)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await votesRef.add({
        'userId': uid,
        'score': _score,
        'comment': _commentController.text,
        'includeGlobal': _includeGlobal,
        'includeMyRanking': _includeMyRanking,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _updateAverageScore();
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showMyRankingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('マイランキング'),
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('Creatmypage')
                .orderBy('order')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('まだ作品がありません'));

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.65,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () async {
                      final docRef = docs[index].reference;
                      final newValue = !(data['includeMyRanking'] ?? false);
                      await docRef.set({'includeMyRanking': newValue}, SetOptions(merge: true));
                      if (newValue) await _saveReviewToMyRanking(docRef.id);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: (data['image'] ?? '').toString().isNotEmpty
                                ? Image.network(data['image'], fit: BoxFit.cover)
                                : _noImage(),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              data['title'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Checkbox(
                            value: data['includeMyRanking'] ?? false,
                            onChanged: (v) async {
                              final docRef = docs[index].reference;
                              await docRef.set({'includeMyRanking': v}, SetOptions(merge: true));
                              if (v == true) await _saveReviewToMyRanking(docRef.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _noImage() => Container(
        color: Colors.grey,
        child: const Center(child: Text('No Image')),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_animeTitle.isNotEmpty ? _animeTitle : '評価する'),
        backgroundColor: Colors.black87,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_animeImageUrl.isNotEmpty)
                    Center(
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 800,
                              height: 400,
                              child: Image.network(
                                _animeImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 300,
                                  height: 180,
                                  color: Colors.grey,
                                  child: const Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _animeTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 横並びカード（幅均等）
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // スコアカード
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Text('スコア: '),
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                          controller: _scoreController,
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) {
                                            final parsed = int.tryParse(v);
                                            if (parsed != null && parsed >= 0 && parsed <= 100) {
                                              setState(() => _score = parsed);
                                            }
                                          },
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('点'),
                                  ],
                                ),
                                Slider(
                                  value: _score.toDouble(),
                                  min: 0,
                                  max: 100,
                                  divisions: 100,
                                  onChanged: (v) {
                                    setState(() {
                                      _score = v.round();
                                      _scoreController.text = '$_score';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // マイランキング + 全体評価
                      Expanded(
                        child: Column(
                          children: [
                            Card(
                              child: ListTile(
                                title: const Text('マイランキングに追加'),
                                onTap: _showMyRankingDialog,
                              ),
                            ),
                            Card(
                              child: SwitchListTile(
                                title: const Text('全体ランキングに含める'),
                                value: _includeGlobal,
                                onChanged: (v) => setState(() => _includeGlobal = v),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // コメント入力
                  TextField(controller: _commentController, maxLines: 4),

                  const SizedBox(height: 16),

                  // 保存ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveReview,
                      child: const Text('保存する'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
