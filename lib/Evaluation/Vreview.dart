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
  bool _includeHallOfFame = false;

  bool _loading = true;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String _animeTitle = '';
  String _animeImageUrl = '';
  String _animeSynopsis = '';

  // マイリスト一時保持
  final Map<String, bool> _myListTemp = {};

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
        _animeSynopsis = d['synopsis'] ?? '';
      }

      // マイリスト初期化
      final pages = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Creatmypage')
          .get();

      for (final p in pages.docs) {
        final vote = await p.reference.collection('votes').doc(uid).get();
        _myListTemp[p.id] = vote.exists && vote.data()!['includeMyRanking'] == true;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =============================
  // 平均点再計算
  // =============================
  Future<void> _updateAverageScore() async {
    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.animeId)
        .collection('users')
        .where('includeGlobal', isEqualTo: true)
        .get();

    double avg = 0;

    if (snap.docs.isNotEmpty) {
      final scores = snap.docs.map((d) => d['score'] as int).toList();
      avg = scores.reduce((a, b) => a + b) / scores.length;
    }

    await FirebaseFirestore.instance
        .collection('animes')
        .doc(widget.animeId)
        .update({
      'averageScore': avg,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


// =============================
// AverageScoreに保存
// =============================
Future<void> _saveReview() async {
  if (uid == null) {
    print('エラー: ログインユーザーの uid が取得できません');
    return;
  }

  try {
    // reviewsコレクションのアニメID配下にユーザーIDで保存（上書き可）
    final reviewRef = FirebaseFirestore.instance
        .collection('reviews')
        .doc(widget.animeId)
        .collection('users')
        .doc(uid);

    await reviewRef.set({
      'userId': uid,
      'title': _animeTitle,
      'score': _score,
      'comment': _commentController.text,
      'includeGlobal': _includeGlobal,
      'includeHallOfFame': _includeHallOfFame,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge:trueで既存データを保持しつつ更新

    // ユーザー側のマイ投票リストにも保存
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('AverageScore')
        .doc()
        .set({
      'score': _score,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 平均スコア更新処理
    await _updateAverageScore();

    if (!mounted) return;
    Navigator.pop(context);
    print('レビュー保存完了: ${reviewRef.id}');
  } catch (e) {
    print('Firestore 保存エラー: $e');
  }
}

// =============================
// MyList保存
// =============================
Future<void> _saveMyList() async {
  try {
    final batch = FirebaseFirestore.instance.batch();

    for (final entry in _myListTemp.entries) {
      if (!entry.value) continue;

      final animeId = entry.key;

      final pageDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Creatmypage')
          .doc(animeId)
          .get();

      if (!pageDoc.exists) continue;

      final pageData = pageDoc.data()!;

      final voteRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Creatmypage')
          .doc(animeId)
          .collection('votes')
          .doc();

      batch.set(voteRef, {
        'animeId': animeId,
        'title': _animeTitle,
        'imageUrl': _animeImageUrl,
        'score': _score,
        'comment': _commentController.text,
        'includeMyRanking': true,
        'updatedAt': Timestamp.now(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();

    debugPrint('✅ batch commit 完了');

    if (mounted) Navigator.pop(context);
  } catch (e, s) {
    debugPrint('🔥 Firestore error: $e');
    debugPrint('$s');
  }
}


// =============================
// チェック外しで削除
// =============================
Future<void> _deleteUnchecked() async {
  for (final entry in _myListTemp.entries) {
    final animeId = entry.key;
    final checked = entry.value;

    if (!checked) {
      final votesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Creatmypage')
          .doc(animeId)
          .collection('votes');

      final snapshot = await votesCollection.get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }
}


  // =============================
  // マイランキングダイアログ
  // =============================
  void _showMyRankingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
        title: Row(
          children: [
            const Expanded(child: Text('マイリスト')),
            TextButton(
              onPressed: _saveMyList,
              child: const Text('保存'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: StatefulBuilder(
            builder: (context, setLocal) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('Creatmypage')
                    .snapshots(), // orderBy は削除して安全化
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pages = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      final checked = _myListTemp[page.id] ?? false;

                      return Card(
                        child: ListTile(
                          title: Text(page['title'] ?? ''),
                          trailing: Checkbox(
                            value: checked,
                            onChanged: (v) {
                              setLocal(() {
                                _myListTemp[page.id] = v ?? false;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: 600,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 400,
                                    height: 200,
                                    child: Transform.translate(
                                      offset: const Offset(20, 0),
                                      child: Image.network(
                                        _animeImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(child: Text('画像なし')),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _animeTitle,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: _animeSynopsis.isNotEmpty
                                  ? Text(
                                      _animeSynopsis,
                                      style: const TextStyle(
                                          fontSize: 16, height: 1.4),
                                    )
                                  : const Text(
                                      'あらすじなし',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic),
                                    ),
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
                          margin: const EdgeInsets.all(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('スコア'),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                          controller: _scoreController,
                                          textAlign: TextAlign.right,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 0),
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (v) {
                                            final parsed = int.tryParse(v);
                                            if (parsed != null) {
                                              setState(() => _score = parsed);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('点'),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                onChanged: (v) async {
                                  setState(() => _includeHallOfFame = v);

                                  final hallRef = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .collection('Halloffame')
                                      .doc(widget.animeId);

                                  if (v) {
                                    await hallRef.set({
                                      'animeId': widget.animeId,
                                      'title': _animeTitle,
                                      'imageUrl': _animeImageUrl,
                                      'score': _score,
                                      'comment': _commentController.text,
                                      'createdAt': FieldValue.serverTimestamp(),
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    });
                                  } else {
                                    await hallRef.delete();
                                  }
                                },
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
Column(
  crossAxisAlignment: CrossAxisAlignment.start, // ←これで子要素を左揃えに
  children: [
    const SizedBox(height: 16),
    const Text(
      '感想',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
    TextField(
      controller: _commentController,
      maxLines: 4,
      textAlign: TextAlign.left, // 入力文字も左揃え
    ),
  ],
)



                  ,
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
