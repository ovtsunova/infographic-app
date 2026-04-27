import 'dart:typed_data';

void downloadFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError(
    'Скачивание файлов доступно только в веб-версии приложения.',
  );
}