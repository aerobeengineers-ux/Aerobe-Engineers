import 'package:flutter/material.dart';

import 'client/client_home.dart';
import 'employee/employee_home.dart';
import 'login_screen.dart';
import 'session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await session.load();
  runApp(const AerobeApp());
}

class AerobeApp extends StatelessWidget {
  const AerobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aerobe Engineers',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          if (!session.loggedIn) return const LoginScreen();
          return session.role == 'employee' ? const EmployeeHome() : const ClientHome();
        },
      ),
    );
  }
}
