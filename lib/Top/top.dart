import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/Top/infinitescroll.dart';
import '/Header/header.dart';
import '/Footer/footer.dart';
import 'user_mylist.dart';
import '/Top/user_halloffame.dart';
import '/Top/infinitescroll.dart';
import '/Top/other_users_my_ranking.dart';

class MainPageWidget extends StatefulWidget {
  const MainPageWidget({super.key});

  @override
  State<MainPageWidget> createState() => _MainPageWidgetState();
}

class _MainPageWidgetState extends State<MainPageWidget> {
  final List<Map<String, String>> sliderItems = [
    {"image": "assets/img1.jpg", "title": "作品1", "nickname": "ユーザーA"},
    {"image": "assets/img2.jpg", "title": "作品2", "nickname": "ユーザーB"},
    {"image": "assets/img3.jpg", "title": "作品3", "nickname": "ユーザーC"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomHeader(),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 無限スクロールスライダー
            AutoScrollSlider(
              items: sliderItems,
            ),

            const Userhalloffame(),
            // Firestore 連動のユーザーマイリストスライダー
            const Usermylist(),

            const OtherUsersMyRanking(),

            const SizedBox(height: 20),

            const SizedBox(height: 30),
            const Footer(),
          ],
        ),
      ),
    );
  }
}
//