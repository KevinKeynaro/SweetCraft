import 'package:flutter/material.dart';

import 'pages/catalog_page.dart';
import 'pages/home_page.dart';
import 'services/api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await _restoreSession();
  runApp(SweetCraftApp(session: session));
}

Future<({String name, String role})?> _restoreSession() async {
  final token = await ApiService.getToken();
  if (token == null) return null;

  try {
    final data = await ApiService.get('/auth/me');
    final payload = data as Map<String, dynamic>;
    final user = payload['user'] as Map<String, dynamic>;
    return (name: user['name'] as String, role: user['role'] as String);
  } on ApiException catch (error) {
    if (error.isUnauthorized) {
      await ApiService.logout();
    }
    return null;
  } catch (_) {
    return null;
  }
}

class SweetCraftApp extends StatelessWidget {
  const SweetCraftApp({super.key, this.session});

  final ({String name, String role})? session;

  @override
  Widget build(BuildContext context) {
    final session = this.session;

    return MaterialApp(
      title: 'SweetCraft',
      debugShowCheckedModeBanner: false,
      home: session == null
          ? const CatalogPage()
          : HomePage(name: session.name, role: session.role),
    );
  }
}
