import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Usermylist extends StatelessWidget {
  const Usermylist({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "～ ユーザマイリスト ～",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getMyCreatmypage(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final myItems = snapshot.data!;

              if (myItems.isEmpty) {
                return const Center(child: Text("作品がありません"));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: myItems.length,
                itemBuilder: (context, index) {
                  return _buildCard(myItems[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 自分の Creatmypage を取得
  Future<List<Map<String, dynamic>>> _getMyCreatmypage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('Creatmypage')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // 必要ならドキュメントIDも追加
      return data;
    }).toList();
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item["images"] != null && item["images"].toString().isNotEmpty
                ? Image.network(
                    item["images"],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Center(child: Text("No Image")),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            item["title"] ?? "",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text("作品数：${item["sakuhin"] ?? ""}"),
        ],
      ),
    );
  }
}
