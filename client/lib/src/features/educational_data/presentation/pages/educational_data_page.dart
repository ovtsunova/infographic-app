import 'package:flutter/material.dart';

class EducationalDataPage extends StatelessWidget {
  const EducationalDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Учебные данные',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Раздел предназначен для загрузки, просмотра, фильтрации и редактирования данных об учебных группах, студентах, дисциплинах, успеваемости и посещаемости.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Загрузка данных',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Позже здесь будет форма импорта CSV/XLSX и таблица загруженных учебных данных.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.upload_file_rounded),
                  label: Text('Загрузить файл'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}