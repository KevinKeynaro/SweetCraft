import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/add_edit_cake_page.dart';
import 'package:frontend/widgets/seller_dashboard_widgets.dart';
import 'package:frontend/widgets/seller_home_view.dart';
import 'package:frontend/widgets/seller_menu_view.dart';

Widget _mobileWrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFFFAF6EC),
      body: child,
    ),
  );
}

void main() {
  testWidgets(
    'Beranda menampilkan ringkasan stok 8 produk mock dan daftar restock tanpa overflow di 360dp',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cakes = buildMockBakeryCakes();
      int? lastAdjustedId;
      int? lastDelta;

      await tester.pumpWidget(
        _mobileWrap(
          SellerHomeView(
            ownerName: 'Siti Bakery',
            cakes: cakes,
            loading: false,
            error: null,
            isMockMode: true,
            updatingIds: const {},
            onRefresh: () async {},
            onOpenProductsTab: ({String stockFilter = 'all'}) {},
            onOpenAddTab: () {},
            onAdjustStock: (cake, delta) async {
              lastAdjustedId = cake['id'] as int?;
              lastDelta = delta;
            },
            onSetManualStock: (cake, newStock) async {},
            onOpenProfileDialog: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Dashboard Toko'), findsOneWidget);
      expect(find.text('8'), findsOneWidget); // 8 total mock products
      expect(find.text('3'), findsOneWidget); // 3 low stock (2, 4, 3)
      expect(find.text('2'), findsOneWidget); // 2 out of stock (0, 0)
      expect(find.text('Perlu Di-Restock'), findsOneWidget);
      expect(find.text('Vanilla Berry Cupcake'), findsOneWidget);

      // Ketuk tombol + pada item restock pertama
      await tester.tap(find.byTooltip('Tambah 1 stok').first);
      await tester.pump();
      expect(lastAdjustedId, equals(-3)); // Vanilla Berry Cupcake (stok 0)
      expect(lastDelta, equals(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Daftar produk mendukung pencarian, filter kategori, update stok manual & hapus',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cakes = buildMockBakeryCakes();
      final categories = buildMockBakeryCategories();
      int? manualStockSet;
      Map<String, dynamic>? deletedCake;

      await tester.pumpWidget(
        _mobileWrap(
          SellerMenuView(
            cakes: cakes,
            categories: categories,
            loading: false,
            error: null,
            updatingIds: const {},
            onRefresh: () async {},
            onAdjustStock: (_, _) async {},
            onSetManualStock: (_, newStock) async {
              manualStockSet = newStock;
            },
            onEditCake: (_) async {},
            onDeleteCake: (cake) async {
              deletedCake = cake;
            },
            onOpenAddTab: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('8 Menu'), findsOneWidget);

      // Filter kategori Cookies (ada 2 produk di mock)
      await tester.tap(find.text('Cookies').first);
      await tester.pump();
      expect(find.text('2 Menu'), findsOneWidget);
      expect(find.text('Belgian Choco Chip Cookies'), findsOneWidget);

      // Cari kata kunci "Matcha"
      await tester.enterText(find.byType(TextField), 'Matcha');
      await tester.pump();
      expect(find.text('1 Menu'), findsOneWidget);
      expect(find.text('Matcha Almond Biscotti'), findsOneWidget);

      // Tap angka stok untuk input manual
      await tester.tap(find.byTooltip('Ketuk untuk ubah stok manual').first);
      await tester.pumpAndSettle();
      expect(find.text('Atur Stok Produk'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '25');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(manualStockSet, equals(25));

      // Tap hapus
      await tester.tap(find.byTooltip('Hapus produk').first);
      await tester.pump();
      expect(deletedCake?['name'], equals('Matcha Almond Biscotti'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Form Tambah Produk memvalidasi field wajib dan menyimpan produk baru dalam mode mock',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Map<String, dynamic>? saved;

      await tester.pumpWidget(
        _mobileWrap(
          AddEditCakePage(
            embedded: true,
            initialCategories: buildMockBakeryCategories(),
            isMockMode: true,
            onSaved: (cake) => saved = cake,
          ),
        ),
      );
      await tester.pump();

      // Submit saat kosong -> muncul pesan validasi
      final submitBtn = find.text('Simpan Produk');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(find.text('Nama produk wajib diisi'), findsOneWidget);
      expect(find.text('Harga wajib diisi'), findsOneWidget);
      expect(find.text('Stok wajib diisi'), findsOneWidget);

      // Isi form dengan benar
      await tester.enterText(find.byType(TextFormField).at(0), 'Lemon Tartlet');
      await tester.enterText(find.byType(TextFormField).at(1), '38000');
      await tester.enterText(find.byType(TextFormField).at(2), '9');

      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved?['name'], equals('Lemon Tartlet'));
      expect(saved?['price'], equals(38000));
      expect(saved?['stock'], equals(9));
      expect(tester.takeException(), isNull);
    },
  );
}
