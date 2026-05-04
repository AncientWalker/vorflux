import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vorflux/providers/auth_provider.dart';
import 'package:vorflux/screens/login_screen.dart';
import 'package:vorflux/services/firebase_config.dart';

void main() {
  testWidgets('Login screen should build', (WidgetTester tester) async {
    FirebaseConfig.setAvailable(false);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Vorflux'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
