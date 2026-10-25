import 'package:flutter_test/flutter_test.dart';
import 'package:cube_iii/main.dart';
import 'package:provider/provider.dart';
import 'package:cube_iii/providers/theme_provider.dart';
import 'package:cube_iii/providers/locale_provider.dart';
import 'package:cube_iii/providers/game_provider.dart';
import 'package:cube_iii/providers/user_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => GameProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: const MusabaqatApp(),
      ),
    );

    // Initial frame shows the app
    expect(find.byType(MusabaqatApp), findsOneWidget);
  });
}
