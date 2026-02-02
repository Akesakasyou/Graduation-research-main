import 'package:flutter/material.dart';

class OtherUserRankingPage extends StatelessWidget {
  final Map<String, dynamic> rankingData;

  const OtherUserRankingPage({
    super.key,
    required this.rankingData,
  });

  @override
  Widget build(BuildContext context) {
    final List items = rankingData["items"] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(rankingData["title"] ?? "マイランキング"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 作成者
            Text(
              "作成者：${rankingData["user"] ?? "不明"}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // ランキング一覧
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: item["image"] != null
                          ? Image.network(
                              item["image"],
                              width: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.movie),
                      title: Text(item["title"] ?? ""),
                      trailing: Text(
                        "${item["rank"] ?? index + 1}位",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}