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
  bool _includeMyRanking = false;
  bool _includeHallOfFame = false;

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

  // =============================
  // 自分のレビュー読み込み
  // =============================
  Future<void> _loadMyReview() async {
    try {
      final voteDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Creatmypage')
          .doc(widget.animeId)
          .collection('votes')
          .doc(uid)
          .get();

      if (voteDoc.exists) {
        final d = voteDoc.data()!;
        _score = d['score'] ?? 0;
        _scoreController.text = '$_score';
        _commentController.text = d['comment'] ?? '';
        _includeGlobal = d['includeGlobal'] ?? false;
        _includeMyRanking = d['includeMyRanking'] ?? false;
        _includeHallOfFame = d['includeHallOfFame'] ?? false;
      }

      final animeDoc = await FirebaseFirestore.instance
          .collection('animes')
          .doc(widget.animeId)
          .get();

      if (animeDoc.exists) {
        final d = animeDoc.data()!;
        _animeTitle = d['title'] ?? '';
        _animeImageUrl = d['imageUrl'] ?? '';
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  // =============================
  // 平均更新（殿堂入り除外）
  // =============================
  Future<void> _updateAverageScore() async {
    final snap =
        await FirebaseFirestore.instance.collectionGroup('votes').get();

    final scores = snap.docs
        .where((d) => (d['includeGlobal'] ?? false) == true)
        .where((d) => (d['includeHallOfFame'] ?? false) == false)
        .where((d) => d.reference.parent.parent?.id == widget.animeId)
        .map((d) => (d['score'] ?? 0) as int)
        .toList();

    if (scores.isEmpty) return;

    final avg = scores.reduce((a, b) => a + b) / scores.length;

    await FirebaseFirestore.instance
        .collection('animes')
        .doc(widget.animeId)
        .update({
      'averageScore': avg,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =============================
  // チェックONで votes に保存
  // =============================
  Future<void> _saveReviewToMyRanking(String creatmypageDocId) async {
    final votesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Creatmypage')
        .doc(creatmypageDocId)
        .collection('votes')
        .doc(uid);

    await votesRef.set({
      'userId': uid,
      'score': _score,
      'comment': _commentController.text,
      'includeGlobal': _includeGlobal,
      'includeMyRanking': true,
      'includeHallOfFame': _includeHallOfFame,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (_includeGlobal) {
      await _updateAverageScore();
    }
  }

  // =============================
  // 保存＝更新／削除
  // =============================
  Future<void> _saveReview() async {
    final voteDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Creatmypage')
        .doc(widget.animeId)
        .collection('votes')
        .doc(uid);

    final hallDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Halloffame')
        .doc(widget.animeId);

    // 全OFFなら削除
    if (!_includeMyRanking && !_includeGlobal && !_includeHallOfFame) {
      if ((await voteDocRef.get()).exists) {
        await voteDocRef.delete();
      }
      if ((await hallDocRef.get()).exists) {
        await hallDocRef.delete();
      }
      await _updateAverageScore();
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    // ONあり → votes 更新
    if (_includeMyRanking || _includeGlobal) {
      await voteDocRef.set({
        'userId': uid,
        'score': _score,
        'comment': _commentController.text,
        'includeGlobal': _includeGlobal,
        'includeMyRanking': _includeMyRanking,
        'includeHallOfFame': _includeHallOfFame,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 殿堂入り更新
    if (_includeHallOfFame) {
      await hallDocRef.set({
        'userId': uid,
        'score': _score,
        'comment': _commentController.text,
        'includeGlobal': _includeGlobal,
        'includeMyRanking': _includeMyRanking,
        'includeHallOfFame': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      if ((await hallDocRef.get()).exists) {
        await hallDocRef.delete();
      }
    }

    await _updateAverageScore();

    if (!mounted) return;
    Navigator.pop(context);
  }

  // =============================
  // マイランキング一覧（チェックON/OFFで votes 更新、王冠付き）
  // =============================
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
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('まだ作品がありません'));
              }

              return GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 3, // 縦に長すぎないように調整
  ),
  itemCount: docs.length,
  itemBuilder: (context, index) {
    final data = docs[index].data() as Map<String, dynamic>;
    final docRef = docs[index].reference;

    return GestureDetector(
      onTap: () {
        // タイトルタップでもチェック切り替え
        final newValue = !(data['includeMyRanking'] ?? false);
        docRef.set({'includeMyRanking': newValue}, SetOptions(merge: true));
        setState(() {
          data['includeMyRanking'] = newValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Checkbox(
              value: data['includeMyRanking'] ?? false,
              onChanged: (v) {
                docRef.set({'includeMyRanking': v}, SetOptions(merge: true));
                setState(() {
                  data['includeMyRanking'] = v;
                });
              },
            ),
            Expanded(
              child: Text(
                data['title'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
        title: Text(_animeTitle.isNotEmpty ? _animeTitle : '評価'),
        backgroundColor: Colors.black87,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_animeImageUrl.isNotEmpty)
                    Card(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 800,
                            height: 400,
                            child: Image.network(_animeImageUrl, fit: BoxFit.cover),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              _animeTitle,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Text('スコア'),
                                  Expanded(
                                    child: TextField(
                                      controller: _scoreController,
                                      textAlign: TextAlign.right,
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) {
                                        final parsed = int.tryParse(v);
                                        if (parsed != null) {
                                          setState(() => _score = parsed);
                                        }
                                      },
                                    ),
                                  ),
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Card(
                              child: SwitchListTile(
                                title: const Text('全体ランキング'),
                                value: _includeGlobal,
                                onChanged: (v) => setState(() => _includeGlobal = v),
                              ),
                            ),
                            Card(
                              child: SwitchListTile(
                                title: const Text('殿堂入り'),
                                value: _includeHallOfFame,
                                onChanged: (v) => setState(() => _includeHallOfFame = v),
                              ),
                            ),
                            Card(
                              child: ListTile(
                                title: const Text('マイランキング一覧'),
                                onTap: _showMyRankingDialog,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
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
