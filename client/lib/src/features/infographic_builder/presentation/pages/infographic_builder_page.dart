import 'package:flutter/material.dart';

class InfographicBuilderPage extends StatelessWidget {
  const InfographicBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Генерация инфографики',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'В этом разделе пользователь выбирает данные, параметры анализа, тип диаграммы, цветовую схему и формирует итоговую инфографику.',
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
                  'Параметры построения',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: const [
                    SizedBox(
                      width: 260,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Учебная группа',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Дисциплина',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Тип диаграммы',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.auto_graph_rounded),
                  label: Text('Сформировать инфографику'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}