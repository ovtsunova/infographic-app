import 'package:client/src/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Приложение запускается и отображает главную страницу', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const InfographicApp());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Веб-приложение для генерации инфографики'),
      findsOneWidget,
    );

    expect(
      find.textContaining('Система предназначена для загрузки'),
      findsOneWidget,
    );
  });
}