import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        Text(
          'Профиль пользователя',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Раздел предназначен для просмотра и редактирования учетных данных пользователя.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        SizedBox(height: 24),
        Card(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Данные профиля',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(labelText: 'Фамилия'),
                ),
                SizedBox(height: 14),
                TextField(
                  decoration: InputDecoration(labelText: 'Имя'),
                ),
                SizedBox(height: 14),
                TextField(
                  decoration: InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}