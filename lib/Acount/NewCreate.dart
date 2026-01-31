import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  String? _gender;
  bool _obscure1 = true;
  bool _obscure2 = true;

  // 🔹 Firebase登録処理
  Future<void> _onRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      // Firebase Authentication でユーザー作成
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // Firestore にプロフィール保存
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'email': _emailCtrl.text.trim(),
        'nickname': _nicknameCtrl.text.trim(),
        'gender': _gender,
        'comment': _commentCtrl.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登録完了しました！ログインしてください')),
        );
        Navigator.pop(context); // ログイン画面へ戻る
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登録に失敗しました：${e.message}')),
      );
    } catch (e) {
      print('Other Exception: $e');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nicknameCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    '新規登録',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // メールアドレス
                const Text('メールアドレス', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'example@example.com',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'メールアドレスを入力してください';
                    if (!RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$').hasMatch(v)) {
                      return '正しい形式で入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // パスワード
                const Text('パスワード', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: '6文字以上で入力',
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure1 ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'パスワードを入力してください';
                    if (v.length < 6) return '6文字以上にしてください';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // パスワード確認
                const Text('パスワード（確認）', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure2 ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return '確認用パスワードを入力してください';
                    if (v != _passwordCtrl.text) return 'パスワードが一致しません';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // ニックネーム
                const Text('ニックネーム', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nicknameCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'ニックネームを入力',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'ニックネームを入力してください';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // 性別
                const Text('性別', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  value: _gender,
                  items: const [
                    DropdownMenuItem(value: '男性', child: Text('男性')),
                    DropdownMenuItem(value: '女性', child: Text('女性')),
                    DropdownMenuItem(value: 'その他', child: Text('その他')),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                  validator: (v) => v == null ? '性別を選択してください' : null,
                ),
                const SizedBox(height: 20),
                // コメント
                const Text('コメント', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '自由にコメントを入力',
                  ),
                ),
                const SizedBox(height: 30),
                // 登録ボタン
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _onRegister,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('登録', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
