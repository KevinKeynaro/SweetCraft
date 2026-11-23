import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/register_page.dart';

Widget _wrap(Widget screen) => MaterialApp(home: screen);

void main() {
  testWidgets('tanpa sesi menampilkan katalog publik', (tester) async {
    await tester.pumpWidget(const SweetCraftApp());
    await tester.pump(const Duration(seconds: 16));

    expect(find.text('SweetCraft'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('dengan sesi pembeli menampilkan tab pembeli', (tester) async {
    await tester.pumpWidget(
      SweetCraftApp(session: (name: 'Siti', role: 'pembeli')),
    );
    await tester.pump(const Duration(seconds: 16));

    expect(find.text('Katalog'), findsWidgets);
    expect(find.text('Pesanan'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('login menampilkan error saat field kosong', (tester) async {
    await tester.pumpWidget(_wrap(const LoginPage()));

    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('login menolak format email salah', (tester) async {
    await tester.pumpWidget(_wrap(const LoginPage()));

    await tester.enterText(find.byType(TextFormField).at(0), 'bukan-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'rahasia');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email tidak valid'), findsOneWidget);
  });

  testWidgets('register menampilkan error saat field wajib kosong', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const RegisterPage()));

    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pump();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('home penjual menampilkan tab khusus penjual', (tester) async {
    await tester.pumpWidget(
      _wrap(const HomePage(name: 'Penjual SweetCraft', role: 'penjual')),
    );
    await tester.pump();

    expect(find.text('Pesanan'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(
      find.text('Menu penjual akan tersedia di milestone berikutnya.'),
      findsOneWidget,
    );
  });
}
