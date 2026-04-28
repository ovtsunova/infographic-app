import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:client/src/features/educational_data/presentation/bloc/educational_data_bloc.dart';

class CsvImportDialog extends StatefulWidget {
  const CsvImportDialog({super.key});

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  EducationalCsvImportType _selectedType = EducationalCsvImportType.students;
  String? _fileName;
  String? _csvText;
  String? _errorMessage;
  bool _isPicking = false;

  bool get _canSubmit {
    return !_isPicking &&
        _fileName != null &&
        _fileName!.trim().isNotEmpty &&
        _csvText != null &&
        _csvText!.trim().isNotEmpty;
  }

  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt'],
        withData: true,
        allowMultiple: false,
      );

      if (!mounted) {
        return;
      }

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isPicking = false;
        });
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _errorMessage =
              'Не удалось прочитать файл. Выберите CSV-файл повторно.';
          _fileName = null;
          _csvText = null;
          _isPicking = false;
        });
        return;
      }

      final text = utf8.decode(bytes, allowMalformed: true).replaceFirst(
            RegExp('^\uFEFF'),
            '',
          );

      if (text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Выбранный CSV-файл пустой.';
          _fileName = file.name;
          _csvText = null;
          _isPicking = false;
        });
        return;
      }

      setState(() {
        _fileName = file.name;
        _csvText = text;
        _errorMessage = null;
        _isPicking = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Ошибка выбора файла: $error';
        _fileName = null;
        _csvText = null;
        _isPicking = false;
      });
    }
  }

  void _submit() {
    if (!_canSubmit) {
      return;
    }

    Navigator.of(context).pop(
      CsvImportDialogResult(
        importType: _selectedType,
        fileName: _fileName!,
        csvText: _csvText!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Импорт CSV'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите тип данных и CSV-файл. Файл должен быть сохранён в кодировке UTF-8. Разделитель может быть запятой, точкой с запятой или табуляцией.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<EducationalCsvImportType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип импортируемых данных',
                  border: OutlineInputBorder(),
                ),
                items: EducationalCsvImportType.values.map((type) {
                  return DropdownMenuItem<EducationalCsvImportType>(
                    value: type,
                    child: Text(type.title),
                  );
                }).toList(),
                onChanged: _isPicking
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedType = value;
                          _fileName = null;
                          _csvText = null;
                          _errorMessage = null;
                        });
                      },
              ),
              const SizedBox(height: 18),
              _ImportFormatHint(importType: _selectedType),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _isPicking ? null : _pickFile,
                icon: _isPicking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(
                  _isPicking ? 'Выбор файла...' : 'Выбрать CSV-файл',
                ),
              ),
              if (_fileName != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fileName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isPicking ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton.icon(
          onPressed: _canSubmit ? _submit : null,
          icon: const Icon(Icons.file_upload_rounded),
          label: const Text('Импортировать'),
        ),
      ],
    );
  }
}

class _ImportFormatHint extends StatelessWidget {
  final EducationalCsvImportType importType;

  const _ImportFormatHint({
    required this.importType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ожидаемые столбцы',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatText,
            style: const TextStyle(
              color: Color(0xFF374151),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String get _formatText {
    switch (importType) {
      case EducationalCsvImportType.students:
        return 'lastName;firstName;patronymic;recordBookNumber;groupName\n'
            'или русские заголовки: Фамилия;Имя;Отчество;Номер зачетной книжки;Группа';
      case EducationalCsvImportType.grades:
        return 'recordBookNumber;disciplineName;studyYear;semester;gradeValue;controlType;gradeDate\n'
            'или русские заголовки: Номер зачетной книжки;Дисциплина;Учебный год;Семестр;Оценка;Форма контроля;Дата оценки';
      case EducationalCsvImportType.attendance:
        return 'recordBookNumber;disciplineName;studyYear;semester;attendedCount;missedCount\n'
            'или русские заголовки: Номер зачетной книжки;Дисциплина;Учебный год;Семестр;Посещено;Пропущено';
    }
  }
}

class CsvImportDialogResult {
  final EducationalCsvImportType importType;
  final String fileName;
  final String csvText;

  const CsvImportDialogResult({
    required this.importType,
    required this.fileName,
    required this.csvText,
  });
}