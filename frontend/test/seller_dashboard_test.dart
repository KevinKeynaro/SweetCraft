import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/add_edit_cake_page.dart';
import 'package:frontend/widgets/seller_dashboard_widgets.dart';
import 'package:frontend/widgets/seller_home_view.dart';
import 'package:frontend/widgets/seller_menu_view.dart';

Widget _mobileWrap(Widget child) {
  return MaterialApp(
    home: Scaffold(backgroundColor: const Color(0xFFF5F3EE), body: child),
  );
}

List<Map<String, dynamic>> _testCakes() => [
  {
    'id': 1,
    'category_id': 1,
    'category': 'Cupcake',
    'name': 'Vanilla Berry Cupcake',
    'price': 24000,
    'stock': 0,
    'is_custom': false,
    'description': 'Cupcake vanila dengan berry segar.',
    'image_url': null,
  },
  {
    'id': 2,
    'category_id': 2,
    'category': 'Cookies',
    'name': 'Matcha Almond Biscotti',
    'price': 52000,
    'stock': 0,
    'is_custom': false,
    'description': 'Biscotti matcha dengan almond panggang.',
    'image_url': null,
  },
  {
    'id': 3,
    'category_id': 2,
    'category': 'Cookies',
    'name': 'Belgian Choco Chip Cookies',
    'price': 48000,
    'stock': 3,
    'is_custom': false,
    'description': 'Cookies cokelat Belgia dengan tekstur renyah.',
    'image_url': null,
  },
];

List<Map<String, dynamic>> _testCategories() => [
  {'id': 1, 'name': 'Cupcake'},
  {'id': 2, 'name': 'Cookies'},
];

void main() {
  testWidgets(
    'Beranda menampilkan ringkasan stok dan daftar restock tanpa overflow di 360dp',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cakes = _testCakes();
      int? lastAdjustedId;
      int? lastDelta;

      await tester.pumpWidget(
        _mobileWrap(
          SellerHomeView(
            ownerName: 'Siti Bakery',
            cakes: cakes,
            loading: false,
            error: null,
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
      expect(find.text('Total Produk'), findsOneWidget);
      expect(find.text('Menipis'), findsWidgets);
      expect(find.text('Habis'), findsWidgets);
      expect(find.text('Perlu Di-Restock'), findsOneWidget);
      expect(find.text('Vanilla Berry Cupcake'), findsOneWidget);

      // Ketuk tombol + pada item restock pertama
      await tester.tap(find.byTooltip('Tambah 1 stok').first);
      await tester.pump();
      expect(lastAdjustedId, equals(1));
      expect(lastDelta, equals(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Daftar produk mendukung pencarian, filter kategori, update stok manual & hapus',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final cakes = _testCakes();
      final categories = _testCategories();
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

      expect(find.text('3 Menu'), findsOneWidget);

      // Filter kategori Cookies (ada 2 produk)
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
    'Form Tambah Produk membatasi input dan memvalidasi field wajib',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _mobileWrap(
          AddEditCakePage(embedded: true, initialCategories: _testCategories()),
        ),
      );
      await tester.pump();

      // Opsi Produk Custom / Pre-Order tidak boleh ada di form tambah/edit produk.
      expect(find.text('Produk Custom / Pre-Order'), findsNothing);
      expect(find.byType(Switch), findsNothing);

      // Submit saat kosong -> muncul pesan validasi
      final submitBtn = find.text('Simpan Produk');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(find.text('Nama produk wajib diisi'), findsOneWidget);
      expect(find.text('Harga wajib diisi'), findsOneWidget);
      expect(find.text('Stok wajib diisi'), findsOneWidget);

      // Petunjuk format gambar tidak lagi membatasi tipe file.
      expect(find.text('Format JPG, PNG, atau WEBP maks 2 MB'), findsNothing);
      expect(find.text('Maksimal 2 MB'), findsOneWidget);

      // Harga & stok hanya menerima digit.
      final priceField = find.byType(TextFormField).at(1);
      await tester.enterText(priceField, '12a3');
      await tester.pump();
      expect(
        tester.widget<TextFormField>(priceField).controller?.text,
        equals('123'),
      );

      final stockField = find.byType(TextFormField).at(2);
      await tester.enterText(stockField, '9x9');
      await tester.pump();
      expect(
        tester.widget<TextFormField>(stockField).controller?.text,
        equals('99'),
      );

      // Harga 0 ditolak dengan pesan jelas.
      await tester.enterText(priceField, '0');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      expect(find.text('Minimal lebih dari 0'), findsOneWidget);

      // Nama produk dibatasi 150 karakter.
      final nameField = find.byType(TextFormField).at(0);
      await tester.enterText(nameField, List.filled(151, 'A').join());
      await tester.pump();
      expect(
        tester.widget<TextFormField>(nameField).controller?.text.length,
        equals(150),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AddEditCakePage menyinkronkan initialCategories saat parent memperbarui daftar kategori',
    (tester) async {
      await tester.pumpWidget(
        _mobileWrap(const AddEditCakePage(embedded: true)),
      );
      await tester.pump(const Duration(seconds: 16));

      expect(find.text('Cookies'), findsNothing);

      await tester.pumpWidget(
        _mobileWrap(
          AddEditCakePage(embedded: true, initialCategories: _testCategories()),
        ),
      );
      await tester.pump();

      expect(find.text('Cupcake'), findsOneWidget);
    },
  );

  testWidgets(
    'Header SellerCurvedHeader pada Beranda dan Produk memiliki tinggi yang sama',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _mobileWrap(
          SellerHomeView(
            ownerName: 'Siti Bakery',
            cakes: _testCakes(),
            loading: false,
            error: null,
            updatingIds: const {},
            onRefresh: () async {},
            onOpenProductsTab: ({String stockFilter = 'all'}) {},
            onOpenAddTab: () {},
            onAdjustStock: (_, _) async {},
            onSetManualStock: (_, _) async {},
          ),
        ),
      );
      await tester.pump();
      final homeHeaderSize = tester.getSize(find.byType(SellerCurvedHeader));

      await tester.pumpWidget(
        _mobileWrap(
          SellerMenuView(
            cakes: _testCakes(),
            categories: _testCategories(),
            loading: false,
            error: null,
            updatingIds: const {},
            onRefresh: () async {},
            onAdjustStock: (_, _) async {},
            onSetManualStock: (_, _) async {},
            onEditCake: (_) async {},
            onDeleteCake: (_) async {},
            onOpenAddTab: () {},
          ),
        ),
      );
      await tester.pump();
      final menuHeaderSize = tester.getSize(find.byType(SellerCurvedHeader));

      expect(homeHeaderSize.width, equals(menuHeaderSize.width));
      expect(homeHeaderSize.height, equals(menuHeaderSize.height));
      expect(tester.takeException(), isNull);
    },
  );
}
