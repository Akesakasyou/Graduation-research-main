import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/Top/infinitescroll.dart';
import '/Header/header.dart';
import '/Footer/footer.dart';
import 'user_mylist.dart';
import '/Top/user_mylist.dart';

class MainPageWidget extends StatefulWidget {
  const MainPageWidget({super.key});

  @override
  State<MainPageWidget> createState() => _MainPageWidgetState();
}

class _MainPageWidgetState extends State<MainPageWidget> {
  final List<Map<String, String>> _sliderItems = const [
    {
      "image": "Image/GNOCIA.png",
      "title": "合わなかった…のかなぁ、なんだろうなぁ。",
      "nickname": "take_0(ゼロ)"
    },
    {
      "image": "Image/GNOCIA.png",
      "title": "合わなかった…のかなぁ、なんだろうなぁ。",
      "nickname": "take_0(ゼロ)"
    },
    {
      "image": "Image/GNOCIA.png",
      "title": "合わなかった…のかなぁ、なんだろうなぁ。",
      "nickname": "take_0(ゼロ)"
    },
    {
      "image": "Image/GNOCIA.png",
      "title": "合わなかった…のかなぁ、なんだろうなぁ。",
      "nickname": "take_0(ゼロ)"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHtmlSlider(),
            const SizedBox(height: 20),,
            const SizedBox(height: 30),
            const Footer(),
            const SizedBox(height: 30),
            const AllUserRanking(),
          ],
        ),
      ),
    );
  }

  Widget _buildHtmlSlider() {
    return SizedBox(
      height: 260,
      child: AutoScrollSlider(items: _sliderItems),
    );
  }
}

// =====================================================
// 無限横スクロール Slider
// =====================================================
class AutoScrollSlider extends StatefulWidget {
  final List<Map<String, String>> items;

  const AutoScrollSlider({super.key, required this.items});

  @override
  State<AutoScrollSlider> createState() => _AutoScrollSliderState();
}

class _AutoScrollSliderState extends State<AutoScrollSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 80),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildRow() {
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: widget.items.map((item) {
        return Container(
          width: 260,
          height: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  item["image"]!,
                  height: 160,
                  width: 260,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                width: 260,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["title"]!,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item["nickname"]!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double fullWidth = MediaQuery.of(context).size.width;

    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final double offset = -fullWidth * _controller.value;

          return Transform.translate(
            offset: Offset(offset, 0),
            child: Row(
              children: [
                _buildRow(),
                _buildRow(),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =====================================================
// みんなのマイランキング
// =====================================================
class AllUserRanking extends StatelessWidget {
  const AllUserRanking({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "🔥 みんなのマイランキング",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 230,
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection("myRankings").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("ランキングがありません"));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _rankingCard(context, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _rankingCard(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherUserRankingPage(
              rankingData: data,
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data["title"] ?? "タイトルなし",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "作成者：${data["user"] ?? "不明"}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),
            Text(
              "作品数：${(data["items"] as List?)?.length ?? 0}",
            ),
          ],
        ),
      ),
    );
  }
}

