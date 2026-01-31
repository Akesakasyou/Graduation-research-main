import 'package:flutter/material.dart';
import '/Header/profiel.dart';
import '/MyRanking/List/list.dart';
import 'search_result_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/Admin/AdminPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/MyRanking/total.dart';
import '/Evaluation/Vreview.dart';
import '/Evaluation/Vselect.dart';
import '/main.dart';

import '../MyRanking/List/Halloffame.dart';

// =============================
// 共通ヘッダー
// =============================
class CustomHeader extends StatefulWidget implements PreferredSizeWidget {
  const CustomHeader({super.key});

  @override
  State<CustomHeader> createState() => _CustomHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomHeaderState extends State<CustomHeader> {
  bool isDark = true;

  final TextEditingController _searchController = TextEditingController();

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
    });
  }

  void _showProfileMenu(BuildContext context, Offset offset) async {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  final selected = await showMenu<int>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromPoints(offset, offset.translate(0, 40)),
      Offset.zero & overlay.size,
    ),
    items: const [
      PopupMenuItem<int>(value: 0, child: Text('マイページ')),
      PopupMenuItem<int>(value: 1, child: Text('ログアウト')),
    ],
  );

  if (selected == 0) {
    // マイページに遷移
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditPage()),
    );
  } else if (selected == 1) {
    // ログアウト
    await FirebaseAuth.instance.signOut();

    // ログアウト後にログイン画面に遷移
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MyApp(), // ここはあなたのログイン画面に置き換えてください
      ),
    );
  }
}



  void _onSearch(String keyword) {
    if (keyword.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultPage(keyword: keyword),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: isDark ? Colors.black : Colors.white,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      
      centerTitle: true,
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon:
                Icon(Icons.person, color: isDark ? Colors.white : Colors.black),
            onPressed: () {
              final RenderBox button = context.findRenderObject() as RenderBox;
              final offset = button.localToGlobal(Offset.zero);
              _showProfileMenu(context, offset);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: toggleTheme,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// =============================
// ドロワーメニュー
// =============================

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    print("UID: ${user?.uid}");

    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    print("User doc exists: ${doc.exists}");
    print("User data: ${doc.data()}");

    return doc.data()?['isAdmin'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<bool>(
        future: _isAdmin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isAdmin = snapshot.data!;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.black87),
                child: Text(
                  'メニュー',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),

              // ===== 共通メニュー =====
              ListTile(
                leading: const Icon(Icons.how_to_vote),
                title: const Text('投票する'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SelectPage(),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('マイランキング'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Mlist(),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('殿堂入り'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Halloffame(),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.leaderboard),
                title: const Text('総合ランキング'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RankingPage()),
                ),
              ),

              // ===== 管理者専用 =====
              if (isAdmin) ...[
                const Divider(),
                const ListTile(
                  title: Text(
                    '管理者',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings),
                  title: const Text('管理者画面'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPage()),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// =============================
// アニメ詳細ページ（固定表示用）
// =============================
class AnimeDetailPageStatic extends StatefulWidget {
  const AnimeDetailPageStatic({super.key});
  @override
  State<AnimeDetailPageStatic> createState() => _AnimeDetailPageStaticState();
}

class _AnimeDetailPageStaticState extends State<AnimeDetailPageStatic>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アニメ詳細'), backgroundColor: Colors.black),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _header(),
          _imageAndSummary(),
          const SizedBox(height: 16),
          _ratingAndFavorite(),
          const SizedBox(height: 16),
          const Divider(),
          _tabs(),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Text('1', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          const Text(
            'アニメタイトル',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _imageAndSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 150,
            color: Colors.grey[400],
            alignment: Alignment.center,
            child: const Text('画像'),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('あらすじ', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                  'ここにアニメのあらすじが入ります…',
                  style: TextStyle(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingAndFavorite() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            ...List.generate(
                5, (_) => const Icon(Icons.star, color: Colors.amber)),
            const SizedBox(width: 6),
            const Text('(4.5)'),
          ]),
          GestureDetector(
            onTap: () => setState(() => isFavorite = !isFavorite),
            child: Row(
              children: [
                Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.black54),
                const SizedBox(width: 4),
                const Text('お気に入り'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'レビュー・感想'),
            Tab(text: 'カテゴリ'),
            Tab(text: 'スレッド'),
          ],
          labelColor: Colors.black,
          indicatorColor: Colors.black,
        ),
        SizedBox(
          height: 250,
          child: TabBarView(
            controller: _tabController,
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('レビューが表示されます'),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('カテゴリ情報'),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('スレッド一覧'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
