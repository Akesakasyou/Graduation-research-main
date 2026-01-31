import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'header.dart';
import '/Evaluation/AnimeDetailPage.dart';
class SearchResultPage extends StatelessWidget {
  final String keyword;

  const SearchResultPage({
    super.key,
    required this.keyword,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('animes')
            .where('title', isGreaterThanOrEqualTo: keyword)
            .where('title', isLessThan: keyword + '\uf8ff')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('該当する作品がありません'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final animeId = docs[index].id; // ドキュメントID
              final title = data['title'] ?? 'タイトル不明';
              final imageUrl = data['imageUrl'] ?? '';

              return ListTile(
                leading: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 50,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // ✅ AnimeDetailPage.dart 側の動的ページへ遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimeDetailPage(
                        animeId: animeId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
