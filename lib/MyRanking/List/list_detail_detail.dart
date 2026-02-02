import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListDetailPage extends StatefulWidget {
  final int rank;
  final String animeId;
  final String voteId;
  final String title;
  final String imageUrl;
  final double score;
  final String comment;

  const ListDetailPage({
    super.key,
    required this.rank,
    required this.animeId,
    required this.voteId,
    required this.title,
    required this.imageUrl,
    required this.score,
    required this.comment,
  });

  @override
  State<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  late double _score;
  late TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _score = widget.score;
    _commentController = TextEditingController(text: widget.comment);
  }

  /// =============================
  /// 保存
  /// =============================
  Future<void> _saveEdit() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Creatmypage')
        .doc(widget.animeId)
        .collection('votes')
        .doc(widget.voteId)
        .update({
      'score': _score,
      'comment': _commentController.text,
    });

    Navigator.pop(context);
  }

  /// =============================
  /// 削除
  /// =============================
  Future<void> _deleteVote() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('Creatmypage')
        .doc(widget.animeId)
        .collection('votes')
        .doc(widget.voteId)
        .delete();

    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この作品の評価を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteVote();
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// =============================
  /// スター
  /// =============================
  Widget buildStarRating(double score) {
    final star = (score / 100) * 5;

    return Row(
      children: List.generate(5, (index) {
        if (star >= index + 1) {
          return const Icon(Icons.star, color: Colors.amber ,size: 60);
        } else if (star > index) {
          return const Icon(Icons.star_half, color: Colors.amber,size:60);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber,size:60);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.rank}位'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 画像 + 評価
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.imageUrl,
                        width: 800,
                        height: 400,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image, size: 120),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'あなたの評価',
                        style: TextStyle(fontSize: 20),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${_score.toInt()}点',
                        style: const TextStyle(
                          fontSize: 130,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      buildStarRating(_score),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// タイトル + ボタン
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _confirmDelete,
                ),

                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveEdit,
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// スコア調整
/// スコア調整
Row(
  children: [
    Text(
      '現在の点数：${_score.toInt()}点',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),

    const SizedBox(width: 12),

    SizedBox(
      width: 60,
      child: TextField(
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: '点数',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
        controller: TextEditingController(text: _score.toInt().toString()),
        onChanged: (value) {
          final v = double.tryParse(value);
          if (v == null) return;

          setState(() {
            if (v < 0) {
              _score = 0;
            } else if (v > 100) {
              _score = 100;
            } else {
              _score = v;
            }
          });
        },
      ),
    ),
  ],
),

Slider(
  value: _score,
  min: 0,
  max: 100,
  divisions: 100,
  label: _score.toInt().toString(),
  onChanged: (v) => setState(() => _score = v),
),



            const SizedBox(height: 20),

            /// 感想
            const Text('感想'),

            TextField(
              controller: _commentController,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}
