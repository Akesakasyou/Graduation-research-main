import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/MyRanking/List/list_detail.dart';

class Mlist extends StatefulWidget {
  const Mlist({super.key});

  @override
  State<Mlist> createState() => _MyRankingState();
}

class _MyRankingState extends State<Mlist> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _ref => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('Creatmypage');

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
                stream: _ref.orderBy('order').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('まだ作品がありません'));
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 6,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
  final data = docs[index].data() as Map<String, dynamic>;

  return GestureDetector(
  onTap: () {
    final docId = docs[index].id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyRankingPage(
          animeId: docId,
          title: data['title'] ?? '',
        ),
      ),
    );
  },
  child: Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade200, // 少し明るめに
      borderRadius: BorderRadius.circular(12), // 角を少し丸く
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(2, 2),
        ),
      ],
    ),
    child: Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Container(
      height: 200,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: (data['image'] ?? '').toString().isNotEmpty
            ? Image.network(
                data['image'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _noImage(),
              )
            : _noImage(),
      ),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        data['title'] ?? '',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    // ここで説明を追加
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        data['description'] ?? '',
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),

  ),
);

                    }

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
      color: Colors.grey,
      child: const Center(child: Text('No Image')),
    );
  }

  // =====================
  // 編集一覧
  // =====================

  Future<void> _showEditListDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('順番編集'),
        content: SizedBox(
          height: 400,
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: _ref.orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              return ReorderableListView.builder(
                itemCount: docs.length,
                onReorder: (oldIndex, newIndex) async {
                  if (newIndex > oldIndex) newIndex--;

                  final moved = docs.removeAt(oldIndex);
                  docs.insert(newIndex, moved);

                  for (int i = 0; i < docs.length; i++) {
                    await docs[i].reference.update({'order': i});
                  }
                },
                itemBuilder: (context, index) {
                  final data =
                      docs[index].data() as Map<String, dynamic>;

                  return ListTile(
                    key: ValueKey(docs[index].id),
                    title: Text(data['title'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await _showEditAnimeDialog(
                                context, docs[index]);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await docs[index].reference.delete();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'))
        ],
      ),
    );

    setState(() {});
  }

  // =====================
  // 追加 / 編集
  // =====================

  void _showAddAnimeDialog(BuildContext context) async {
    await _showAnimeDialog(context);
  }

  Future<void> _showEditAnimeDialog(
      BuildContext context, QueryDocumentSnapshot doc) async {
    await _showAnimeDialog(context,
        doc: doc, existingData: doc.data() as Map<String, dynamic>);
  }

  Future<void> _showAnimeDialog(BuildContext context,
      {QueryDocumentSnapshot? doc,
      Map<String, dynamic>? existingData}) async {
    final title =
        TextEditingController(text: existingData?['title'] ?? '');
    final description =
        TextEditingController(text: existingData?['description'] ?? '');
    final image =
        TextEditingController(text: existingData?['image'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc != null ? '作品編集' : '作品追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(image, '画像URL'),
            _field(title, 'タイトル'),
            _field(description, '説明'),            
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              if (title.text.isEmpty) return;

              if (doc != null) {
                await doc.reference.update({
                  'title': title.text,
                  'description': description.text,
                  'image': image.text,
                });
              } else {
                final last = await _ref
                    .orderBy('order', descending: true)
                    .limit(1)
                    .get();

                int order =
                    last.docs.isNotEmpty ? last.docs.first['order'] + 1 : 0;

                await _ref.add({
                  'title': title.text,
                  'description': description.text,
                  'image': image.text,
                  'order': order,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }

              Navigator.pop(context);
              setState(() {});
            },
            child: Text(doc != null ? '保存' : '追加'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child:
          TextField(controller: c, decoration: InputDecoration(labelText: label)),
    );
  }
}
