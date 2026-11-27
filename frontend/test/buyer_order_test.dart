import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/create_order_page.dart';
import 'package:frontend/widgets/buyer_orders_view.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: child,
    ),
  );
}

void main() {
  testWidgets(
    'CreateOrderPage mode custom menampilkan urutan upload foto -> deskripsi -> catatan dekorasi -> ajukan & memvalidasi deskripsi minimal 5 karakter',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(const CreateOrderPage()));
      await tester.pump();

      expect(find.text('Pesan Custom Cake'), findsOneWidget);
      expect(find.text('Upload Foto Referensi (Opsional)'), findsOneWidget);
      expect(find.text('Pilih Foto Referensi'), findsOneWidget);
      expect(find.text('Deskripsi Kue Custom *'), findsOneWidget);
      expect(
        find.text('Catatan Dekorasi / Ucapan (Opsional)'),
        findsOneWidget,
      );

      final uploadTop = tester
          .getTopLeft(find.text('Upload Foto Referensi (Opsional)'))
          .dy;
      final descTop = tester.getTopLeft(find.text('Deskripsi Kue Custom *')).dy;
      final noteTop = tester
          .getTopLeft(find.text('Catatan Dekorasi / Ucapan (Opsional)'))
          .dy;
      final submitBtn = find.text('Ajukan Pre-Order Custom');
      final submitTop = tester.getTopLeft(submitBtn).dy;

      expect(uploadTop, lessThan(descTop));
      expect(descTop, lessThan(noteTop));
      expect(noteTop, lessThan(submitTop));

      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      expect(find.text('Deskripsi kue custom wajib diisi'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Kue');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(find.text('Deskripsi minimal 5 karakter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CreateOrderPage mode ready-stock menampilkan ringkasan kue & jadwal ambil tanpa overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          const CreateOrderPage(
            cake: {
              'id': 1,
              'name': 'Strawberry Fruit Tart',
              'category': 'Artisan Bread',
              'price': 85000,
              'stock': 4,
              'image_url': null,
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Konfirmasi Pesanan'), findsOneWidget);
      expect(find.text('Strawberry Fruit Tart'), findsOneWidget);
      expect(find.text('Bread'), findsOneWidget);
      expect(find.text('Kirim Pesanan (Rp85.000)'), findsOneWidget);

      // Tambah jumlah pesanan (1 -> 2 -> 3 -> 4, mentok di stok 4)
      final addBtn = find.byTooltip('Tambah jumlah');
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Kirim 2 Pesanan (Rp170.000)'), findsOneWidget);

      await tester.tap(addBtn);
      await tester.pump();
      await tester.tap(addBtn);
      await tester.pump();
      await tester.tap(addBtn); // tidak melebihi stok 4
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Kirim 4 Pesanan (Rp340.000)'), findsOneWidget);

      await tester.tap(find.byTooltip('Kurangi jumlah'));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Kirim 3 Pesanan (Rp255.000)'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CreateOrderPage mode embedded menampilkan header Pre-Order Custom Cake tanpa overflow di 360dp',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(const CreateOrderPage(embedded: true)));
      await tester.pump();

      expect(find.text('Pre-Order Custom Cake'), findsOneWidget);
      expect(find.text('Ajukan Pre-Order Custom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BuyerOrdersView merender header, filter status tanpa overflow di 360dp',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(const BuyerOrdersView()));
      await tester.pump(const Duration(seconds: 16));
      await tester.pump();

      expect(find.text('Pesanan Saya'), findsOneWidget);
      expect(find.text('Custom Cake'), findsNothing);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Siap Diambil'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
