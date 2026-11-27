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

      await tester.pumpWidget(
        _wrap(const BuyerOrdersView(initialOrders: [])),
      );
      await tester.pump();

      expect(find.text('Pesanan Saya'), findsOneWidget);
      expect(find.text('Custom Cake'), findsNothing);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Siap Diambil'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BuyerOrdersView menampilkan filter Dibatalkan tanpa overflow di 360dp',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(const BuyerOrdersView(initialOrders: [])),
      );
      await tester.pump();

      expect(find.text('Dibatalkan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Pre-order custom: pembeli menyetujui harga final',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int? decidedOrderId;
      String? decidedStatus;

      await tester.pumpWidget(
        _wrap(
          BuyerOrdersView(
            initialOrders: [
              {
                'id': 21,
                'order_type': 'custom',
                'custom_description': 'Kue ulang tahun tema bunga',
                'status': 'pending',
                'agreed_price': 250000,
                'created_at': '2026-11-27 10:00:00',
              },
            ],
            onDecide: (orderId, status) async {
              decidedOrderId = orderId;
              decidedStatus = status;
              return {'id': orderId, 'status': status};
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Custom Cake Pre-Order'));
      await tester.pumpAndSettle();

      expect(find.text('Setujui Harga'), findsOneWidget);
      expect(find.text('Tolak Harga'), findsOneWidget);
      expect(find.text('Batalkan Pesanan'), findsOneWidget);

      await tester.tap(find.text('Setujui Harga'));
      await tester.pumpAndSettle();
      expect(find.text('Setujui Harga?'), findsOneWidget);

      await tester.tap(find.text('Setujui').last);
      await tester.pumpAndSettle();

      expect(decidedOrderId, equals(21));
      expect(decidedStatus, equals('approved'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ready-stock: pembeli membatalkan pesanan pending',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int? cancelledOrderId;

      await tester.pumpWidget(
        _wrap(
          BuyerOrdersView(
            initialOrders: [
              {
                'id': 22,
                'order_type': 'ready_stock',
                'cake_name': 'Strawberry Fruit Tart',
                'status': 'pending',
                'agreed_price': 85000,
                'created_at': DateTime.now()
                    .subtract(const Duration(minutes: 10))
                    .toString(),
              },
            ],
            onCancel: (orderId) async {
              cancelledOrderId = orderId;
              return {'id': orderId, 'status': 'cancelled'};
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Strawberry Fruit Tart'));
      await tester.pumpAndSettle();

      expect(find.text('Batalkan Pesanan'), findsOneWidget);

      await tester.tap(find.text('Batalkan Pesanan'));
      await tester.pumpAndSettle();
      expect(find.text('Batalkan Pesanan?'), findsOneWidget);

      await tester.tap(find.text('Batalkan').last);
      await tester.pumpAndSettle();

      expect(cancelledOrderId, equals(22));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ready-stock lewat 60 menit tidak menampilkan tombol batal',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          BuyerOrdersView(
            initialOrders: [
              {
                'id': 23,
                'order_type': 'ready_stock',
                'cake_name': 'Matcha Almond Biscotti',
                'status': 'pending',
                'agreed_price': 52000,
                'created_at': DateTime.now()
                    .subtract(const Duration(hours: 2))
                    .toString(),
              },
            ],
            onCancel: (orderId) async => {'id': orderId},
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Matcha Almond Biscotti'));
      await tester.pumpAndSettle();

      expect(find.text('Batalkan Pesanan'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
