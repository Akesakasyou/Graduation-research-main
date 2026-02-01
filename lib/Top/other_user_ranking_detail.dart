import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtherUserRankingDetailPage extends StatelessWidget {
  final String userId;

  const OtherUserRankingDetailPage({
    super.key,
    required this.userId,
  });

  Future<List<Map<String, dynamic>>> _getUserRanking() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Creatmypage')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイランキング詳細'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getUserRanking(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(child: Text('ランキングがありません'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: item["images"] != null
                    ? Image.network(
                        item["images"],
                        width: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image),
                title: Text(item["title"] ?? ""),
                subtitle: Text("作品数：${item["sakuhin"] ?? ""}"),
              );
            },
          );
        },
      ),
    );
  }
}
//