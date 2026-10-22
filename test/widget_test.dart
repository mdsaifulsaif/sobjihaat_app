import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sobjihaat_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sobjihaat_app/main.dart';

void main() {
  testWidgets('App initializes without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const SobjiHaatApp(),
      ),
    );

    expect(find.byType(SobjiHaatApp), findsOneWidget);
    // Drain pending splash timer
    await tester.pump(const Duration(seconds: 2));
  });
}
