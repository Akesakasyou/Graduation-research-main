import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Mlist extends StatefulWidget {
  const Mlist({super.key});

  @override
  State<Mlist> createState() => _MyRankingState();
}

class _MyRankingState extends State<Mlist> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('マイページ', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showEditListDialog(context),
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  label: const Text('編集', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black26),
                    elevation: 0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 30),
                  onPressed: () => _showAddAnimeDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Creatmypage')
                    .orderBy('order')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('まだ作品がありません'));
                  }

                  final docs = snapshot.data!.docs;

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: (data['image'] ?? '')
                                      .toString()
                                      .isNotEmpty
                                  ? Image.network(
                                      data['image'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          _noImage(),
                                    )
                                  : _noImage(),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                data['title'] ?? 'タイトル未設定',
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noImage() {
    return Container(
      color: Colors.grey.shade400,
      child: const Center(
        child: Text(
          'No Image',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  // -------------------------
  // 並び替え・編集ダイアログ
  // -------------------------
  void _showEditListDialog(BuildContext context) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Creatmypage')
        .orderBy('order')
        .get();

    List<QueryDocumentSnapshot> docs = snapshot.docs;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('作品の順番編集'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ReorderableListView.builder(
                itemCount: docs.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final moved = docs.removeAt(oldIndex);
                  docs.insert(newIndex, moved);
                  setState(() {});

                  for (int i = 0; i < docs.length; i++) {
                    await docs[i].reference.update({'order': i});
                  }
                },
                itemBuilder: (context, index) {
                  final data =
                      docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    key: ValueKey(docs[index].id),
                    leading: (data['image'] ?? '')
                            .toString()
                            .isNotEmpty
                        ? Image.network(
                            data['image'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey,
                          ),
                    title: Text(data['title'] ?? 'タイトルなし'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showEditAnimeDialog(context, docs[index]),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await docs[index].reference.delete();
                            setState(() {
                              docs.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          );
        });
      },
    );
  }

  // -------------------------
  // 作品追加 / 編集
  // -------------------------
  void _showAddAnimeDialog(BuildContext context) {
    _showAnimeDialog(context);
  }

  void _showEditAnimeDialog(
      BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _showAnimeDialog(context, doc: doc, existingData: data);
  }

  void _showAnimeDialog(BuildContext context,
      {QueryDocumentSnapshot? doc,
      Map<String, dynamic>? existingData}) {
    final title =
        TextEditingController(text: existingData?['title'] ?? '');
    final description =
        TextEditingController(text: existingData?['description'] ?? '');
    final imageUrl =
        TextEditingController(text: existingData?['image'] ?? '');

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(doc != null ? '作品編集' : '作品追加'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _field(title, 'タイトル'),
                _field(description, '説明', lines: 3),
                _field(imageUrl, '画像URL'),
                if (imageUrl.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Image.network(
                      imageUrl.text,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Text('画像を読み込めません'),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.text.isEmpty) return;

                final dataMap = {
                  'title': title.text,
                  'description': description.text,
                  'image': imageUrl.text,
                  'createdAt': existingData?['createdAt'] ??
                      FieldValue.serverTimestamp(),
                };

                if (doc != null) {
                  await doc.reference.update(dataMap);
                } else {
                  final snapshot = await FirebaseFirestore.instance
                      .collection('Creatmypage')
                      .orderBy('order', descending: true)
                      .limit(1)
                      .get();

                  int newOrder = snapshot.docs.isNotEmpty
                      ? (snapshot.docs.first['order'] ?? 0) + 1
                      : 0;

                  final newDoc = await FirebaseFirestore.instance
                      .collection('Creatmypage')
                      .add({...dataMap, 'order': newOrder});

                  await newDoc.update({'docId': newDoc.id});
                }

                Navigator.pop(context);
              },
              child: Text(doc != null ? '保存' : '追加'),
            ),
          ],
        );
      },
    );
  }

  Widget _field(TextEditingController c, String label,
      {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: lines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
