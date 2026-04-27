import 'package:flutter/material.dart';

class SavedInfographicsPage extends StatelessWidget {
  const SavedInfographicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        Text(
          'Сохранённые инфографики',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Здесь будет отображаться список ранее сформированных и сохранённых инфографических материалов.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        SizedBox(height: 24),
        Card(
          child: Padding(
            padding: EdgeInsets.all(22),
            child: Text(
              'Список сохранённых результатов пока пуст.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ),
      ],
    );
  }
}