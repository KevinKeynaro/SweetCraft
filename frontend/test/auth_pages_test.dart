import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/login_page.dart';
import 'package:frontend/pages/register_page.dart';
import 'package:frontend/widgets/app_bottom_nav.dart';
import 'package:frontend/widgets/catalog_view.dart';

Widget _wrap(Widget screen, {double textScale = 1}) {
  return MaterialApp(
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      );
    },
    home: screen,
  );
}

const _errorColor = Color(0xFFDC2626);
const _neutralBorder = Color(0xFF8C8C8C);

Color? _enabledBorderColor(WidgetTester tester, int index) {
  final field = tester.widget<TextField>(find.byType(TextField).at(index));
  final border = field.decoration?.enabledBorder;
  return border is OutlineInputBorder ? border.borderSide.color : null;
}

void main() {
  testWidgets(
    'login memenuhi touch target minimum 48dp dan spacing ergonomis',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(const LoginPage()));
      await tester.pump();

      // Verifikasi 2 field input (Email & Password) memenuhi tinggi >= 48dp
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));
      for (var i = 0; i < 2; i++) {
        expect(tester.getSize(fields.at(i)).height, greaterThanOrEqualTo(48));
      }

      // Verifikasi tombol submit memenuhi tinggi >= 52dp
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(52),
      );

      // Verifikasi suffix icon toggle password memenuhi touch target >= 48dp
      final toggleIcon = find.byTooltip('Tampilkan password');
      expect(toggleIcon, findsOneWidget);
      expect(tester.getSize(toggleIcon).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(toggleIcon).height, greaterThanOrEqualTo(48));

      // Verifikasi logo 2x hadir
      expect(find.bySemanticsLabel('Logo SweetCraft'), findsOneWidget);
      final logoImage = tester.widget<Image>(find.byType(Image));
      expect(logoImage.width, equals(480));
      expect(logoImage.height, equals(240));
    },
  );

  testWidgets('register tidak overflow pada layar kecil dan teks besar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrap(const RegisterPage(), textScale: 2));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('tanpa sesi menampilkan katalog publik sesuai referensi', (
    tester,
  ) async {
    await tester.pumpWidget(const SweetCraftApp());
    await tester.pump(const Duration(seconds: 16));

    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Search'), findsWidgets);
    expect(find.text('Special Offer'), findsOneWidget);
    expect(find.text('Get Special Offer'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    // Verifikasi tinggi bottom nav tepat 64dp dan CatalogView memiliki ruang penuh
    final bottomNav = find.byType(AppBottomNav);
    expect(bottomNav, findsOneWidget);
    expect(tester.getSize(bottomNav).height, equals(64));
    final catalogView = find.byType(CatalogView);
    expect(catalogView, findsOneWidget);
    expect(tester.getSize(catalogView).height, greaterThan(400));
  });

  testWidgets('dengan sesi pembeli menampilkan tab pembeli 5 menu statis', (
    tester,
  ) async {
    await tester.pumpWidget(
      SweetCraftApp(session: (name: 'Siti', role: 'pembeli')),
    );
    await tester.pump(const Duration(seconds: 16));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsWidgets);
    expect(find.text('Pre-Order'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Pre-Order'));
    await tester.pump();
    expect(find.text('Pre-Order Custom Cake'), findsOneWidget);
    expect(find.text('Ajukan Pre-Order Custom'), findsOneWidget);
  });

  testWidgets('indikator navigasi aktif lebih besar, gelap, dan teks tebal', (
    tester,
  ) async {
    await tester.pumpWidget(const SweetCraftApp());
    await tester.pump(const Duration(seconds: 16));

    final square = find.byKey(const ValueKey('bottom-nav-active-square'));
    expect(square, findsOneWidget);
    expect(tester.getSize(square), const Size(62, 62));

    final container = tester.widget<Container>(square);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFF3A2114));
    expect(decoration.borderRadius, BorderRadius.circular(18));

    final label = tester.widget<Text>(find.text('Home'));
    expect(label.style?.fontWeight, FontWeight.w800);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kotak kategori lebih besar, gelap, dan label tebal', (
    tester,
  ) async {
    await tester.pumpWidget(const SweetCraftApp());
    await tester.pump(const Duration(seconds: 16));

    final squares = find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('category-square-');
    });
    expect(squares, findsWidgets);

    final square = squares.first;
    final size = tester.getSize(square);
    expect(size.width, greaterThan(48));
    expect(size.width, lessThanOrEqualTo(64));
    expect(size.width, equals(size.height));

    final container = tester.widget<Container>(square);
    final decoration = container.decoration as BoxDecoration;
    expect(const [
      Color(0xFF7A2E2E),
      Color(0xFF9A4A2E),
      Color(0xFF8A5A1E),
      Color(0xFF5A3A2A),
      Color(0xFF4F5D3A),
    ], contains(decoration.color));
    expect(decoration.borderRadius, BorderRadius.circular(16));

    final key = container.key! as ValueKey<String>;
    final name = key.value.substring('category-square-'.length);
    final label = tester.widget<Text>(
      find.byKey(ValueKey('category-label-$name')),
    );
    expect(label.style?.fontSize, 12.5);
    expect(label.style?.fontWeight, FontWeight.w800);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login menampilkan error saat field kosong', (tester) async {
    await tester.pumpWidget(_wrap(const LoginPage()));

    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    // Tidak ada label visual dan tidak ada teks warning.
    expect(find.text('Email'), findsNothing);
    expect(find.text('Password'), findsNothing);
    expect(find.text('Email wajib diisi'), findsNothing);
    expect(find.text('Password wajib diisi'), findsNothing);

    // Error hanya ditandai merah.
    expect(_enabledBorderColor(tester, 0), _errorColor);
    expect(_enabledBorderColor(tester, 1), _errorColor);
    expect(find.byIcon(Icons.error_outline), findsNWidgets(2));
  });

  testWidgets('login menolak format email salah', (tester) async {
    await tester.pumpWidget(_wrap(const LoginPage()));

    await tester.enterText(find.byType(TextField).at(0), 'bukan-email');
    await tester.enterText(find.byType(TextField).at(1), 'rahasia');
    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email tidak valid'), findsNothing);
    expect(_enabledBorderColor(tester, 0), _errorColor);
    expect(_enabledBorderColor(tester, 1), _neutralBorder);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('register menampilkan error saat field wajib kosong', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const RegisterPage()));

    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pump();

    // Tidak ada teks warning; error hanya merah.
    expect(find.text('Nama wajib diisi'), findsNothing);
    expect(find.text('Email wajib diisi'), findsNothing);
    expect(find.text('Password wajib diisi'), findsNothing);

    expect(_enabledBorderColor(tester, 0), _errorColor);
    expect(_enabledBorderColor(tester, 1), _errorColor);
    expect(_enabledBorderColor(tester, 2), _neutralBorder); // phone opsional
    expect(_enabledBorderColor(tester, 3), _errorColor);
    expect(find.byIcon(Icons.error_outline), findsNWidgets(3));
  });

  testWidgets('home penjual menampilkan tab khusus penjual', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(const HomePage(name: 'Penjual SweetCraft', role: 'penjual')),
    );
    await tester.pump(const Duration(seconds: 16));
    await tester.pump();

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byKey(const ValueKey('bottom-nav-active-square')), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Produk'), findsOneWidget);
    expect(find.text('Tambah'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Dashboard Toko'), findsOneWidget);
    expect(find.text('Tidak Dapat Memuat Data'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pump();
    expect(find.text('Halo, Penjual SweetCraft'), findsOneWidget);
    expect(find.text('Masuk sebagai Penjual.'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
