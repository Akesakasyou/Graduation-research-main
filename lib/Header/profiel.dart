import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  // ▼ 入力コントローラ
  final _nicknameCtrl = TextEditingController(text: "福沢 楸86");
  final _soulCommentCtrl = TextEditingController();
  final _memberCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _selectedPrefecture;
  String? _selectedGender = "男性";
  String? _selectedYear = "2003";
  String? _selectedMonth = "11";
  String? _selectedDay = "11";

  final List<String> _prefectures = const [
    "",
    "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
    "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
    "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県",
    "岐阜県", "静岡県", "愛知県", "三重県",
    "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県",
    "鳥取県", "島根県", "岡山県", "広島県", "山口県",
    "徳島県", "香川県", "愛媛県", "高知県",
    "福岡県", "佐賀県", "長崎県", "熊本県", "大分県",
    "宮崎県", "鹿児島県", "沖縄県",
  ];

  List<String> get _yearList =>
      List.generate(2025 - 1900 + 1, (i) => (1900 + i).toString())
          .reversed
          .toList();

  List<String> get _monthList =>
      List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));

  List<String> get _dayList =>
      List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _soulCommentCtrl.dispose();
    _memberCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // 🔹 Firebase 更新処理
  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログイン状態が不明です')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nickname': _nicknameCtrl.text.trim(),
        'comment': _soulCommentCtrl.text.trim(),
        'prefecture': _selectedPrefecture,
        'gender': _selectedGender,
        'birthday': '${_selectedYear}-${_selectedMonth}-${_selectedDay}',
        'member': _memberCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
      }
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新に失敗しました：${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予期せぬエラーが発生しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("プロフィールの設定"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _rowColumn(
              "ニックネーム",
              TextField(
                controller: _nicknameCtrl,
                maxLength: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            _rowColumn(
              "ヒトコト",
              TextField(
                controller: _soulCommentCtrl,
                maxLength: 100,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            _rowColumn(
              "都道府県",
              _dropdown(_prefectures, _selectedPrefecture, (v) {
                setState(() => _selectedPrefecture = v);
              }),
            ),
            _rowColumn(
              "性別",
              _dropdown(["", "男性", "女性", "その他"], _selectedGender, (v) {
                setState(() => _selectedGender = v);
              }),
            ),
            _rowColumn(
              "誕生日",
              Row(
                children: [
                  Expanded(
                    child: _dropdown(_yearList, _selectedYear, (v) {
                      setState(() => _selectedYear = v);
                    }),
                  ),
                  const Text(" 年 "),
                  Expanded(
                    child: _dropdown(_monthList, _selectedMonth, (v) {
                      setState(() => _selectedMonth = v);
                    }),
                  ),
                  const Text(" 月 "),
                  Expanded(
                    child: _dropdown(_dayList, _selectedDay, (v) {
                      setState(() => _selectedDay = v);
                    }),
                  ),
                  const Text(" 日"),
                ],
              ),
            ),
            _rowColumn(
              "所属",
              TextField(
                controller: _memberCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            _rowColumn(
              "自由帳",
              TextField(
                controller: _noteCtrl,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ImageButton(
              imagePath: "assets/update_btn.png",
              onPressed: _updateProfile,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _rowColumn(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _dropdown(List<String> list, String? value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        underline: Container(),
        items: list
            .map((e) => DropdownMenuItem(value: e, child: Text(e.isEmpty ? " " : e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class ImageButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed;

  const ImageButton({super.key, required this.imagePath, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Image.asset(imagePath, height: 50),
    );
  }
}
