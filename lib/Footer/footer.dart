// lib/widgets/footer.dart
import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 30,
        runSpacing: 10,
        children: [
          _footerLink(context, '/about', 'Anime Reserchとは'),
          _footerLink(context, '/contacts', 'お問い合わせ'),
          _footerLink(context, '/policy', 'プライバシーポリシー'),
          _footerLink(context, '/', '©Anime Reserch'),
        ],
      ),
    );
  }

  Widget _footerLink(BuildContext context, String route, String text) {
    return GestureDetector(
      onTap: () {
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
