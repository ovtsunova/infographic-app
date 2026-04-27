class SavedInfographic {
  final int id;
  final String title;
  final String chartType;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> resultData;
  final String creationDate;
  final int? templateId;
  final String? templateName;
  final String? author;
  final String? authorEmail;

  const SavedInfographic({
    required this.id,
    required this.title,
    required this.chartType,
    required this.parameters,
    required this.resultData,
    required this.creationDate,
    this.templateId,
    this.templateName,
    this.author,
    this.authorEmail,
  });

  factory SavedInfographic.fromJson(Map<String, dynamic> json) {
    return SavedInfographic(
      id: _readInt(json['id']),
      title: _readString(json['title']),
      chartType: _readString(json['chartType']),
      parameters: _readMap(json['parameters']),
      resultData: _readMap(json['resultData']),
      creationDate: _readString(json['creationDate']),
      templateId: _readNullableInt(json['templateId']),
      templateName: _readNullableString(json['templateName']),
      author: _readNullableString(json['author']),
      authorEmail: _readNullableString(json['authorEmail']),
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

String _readString(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _readNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';

  if (text.isEmpty) {
    return null;
  }

  return text;
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return {};
}