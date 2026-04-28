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


class SavedInfographicTemplate {
  final int id;
  final String templateName;
  final String chartType;
  final String colorScheme;
  final String? description;
  final bool isActive;

  const SavedInfographicTemplate({
    required this.id,
    required this.templateName,
    required this.chartType,
    required this.colorScheme,
    required this.description,
    required this.isActive,
  });

  factory SavedInfographicTemplate.fromJson(Map<String, dynamic> json) {
    return SavedInfographicTemplate(
      id: _readInt(json['id']),
      templateName: _readString(json['templateName']),
      chartType: _readString(json['chartType']),
      colorScheme: _readString(json['colorScheme']),
      description: _readNullableString(json['description']),
      isActive: _readBool(json['isActive']),
    );
  }

  String get title {
    final parts = [
      templateName,
      _chartTypeTitle(chartType),
      _colorSchemeTitle(colorScheme),
    ].where((part) => part.trim().isNotEmpty).toList();

    return parts.join(' • ');
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


bool _readBool(dynamic value) {
  if (value is bool) {
    return value;
  }

  final text = value?.toString().trim().toLowerCase();

  return text == 'true' || text == '1' || text == 'yes';
}

String _chartTypeTitle(String value) {
  switch (value) {
    case 'bar':
      return 'столбчатая';
    case 'line':
      return 'линейная';
    case 'pie':
      return 'круговая';
    case 'doughnut':
      return 'кольцевая';
    case 'card':
      return 'карточки';
    default:
      return value;
  }
}

String _colorSchemeTitle(String value) {
  switch (value) {
    case 'blue':
      return 'синяя';
    case 'green':
      return 'зелёная';
    case 'orange':
      return 'оранжевая';
    case 'purple':
      return 'фиолетовая';
    case 'default':
      return 'по умолчанию';
    default:
      return value;
  }
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