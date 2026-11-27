import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/seller_dashboard_widgets.dart';
import 'package:frontend/widgets/seller_orders_view.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(backgroundColor: const Color(0xFFFDFBF7), body: child),
  );
}

List<Map<String, dynamic>> _sampleOrders() => [
  {
    'id': 11,
    'buyer_name': 'Siti Pembeli',
    'order_type': 'custom',
    'custom_description': 'Kue ulang tahun 2 tingkat rasa matcha cokelat',
    'decoration_note': 'Happy Birthday Rina',
    'agreed_price': null,
    'pickup_date': '2026-12-05 14:00:00',
    'status': 'pending',
  },
  {
    'id': 12,
    'buyer_name': 'Budi Santoso',
    'cake_name': 'Strawberry Fruit Tart',
    'order_type': 'ready_stock',
    'decoration_note': null,
    'agreed_price': 85000,
    'pickup_date': null,
    'status': 'processing',
  },
  {
    'id': 13,
    'buyer_name': 'Ani Wijaya',
    'cake_name': 'Matcha Almond Biscotti',
    'order_type': 'ready_stock',
    'agreed_price': 52000,
    'status': 'ready',
  },
];

void main() {
  testWidgets(
    'SellerOrdersView merender header sejajar, pencarian, filter status tanpa overflow di 360dp',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(SellerOrdersView(initialOrders: _sampleOrders())),
      );
      await tester.pump();

      expect(find.byType(SellerCurvedHeader), findsOneWidget);
      expect(find.text('Pesanan Masuk'), findsOneWidget);
      expect(find.text('3 Order'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Menunggu'), findsWidgets);
      expect(find.text('Custom Cake Pre-Order'), findsOneWidget);
      expect(find.text('Strawberry Fruit Tart'), findsOneWidget);

      // Filter status "Diproses" -> sisa 1 pesanan
      await tester.tap(find.text('Diproses').first);
      await tester.pump();
      expect(find.text('1 Order'), findsOneWidget);
      expect(find.text('Strawberry Fruit Tart'), findsOneWidget);
      expect(find.text('Custom Cake Pre-Order'), findsNothing);

      // Reset ke Semua dan cari nama pembeli "Ani"
      await tester.tap(find.text('Semua'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Ani');
      await tester.pump();
      expect(find.text('1 Order'), findsOneWidget);
      expect(find.text('Matcha Almond Biscotti'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Kurasi custom pre-order: penjual hanya menetapkan harga final, bukan menyetujui',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int? updatedPriceOrderId;
      double? updatedPriceValue;
      int? updatedStatusOrderId;

      await tester.pumpWidget(
        _wrap(
          SellerOrdersView(
            initialOrders: _sampleOrders(),
            onUpdatePrice: (orderId, price) async {
              updatedPriceOrderId = orderId;
              updatedPriceValue = price;
              return {'id': orderId, 'agreed_price': price};
            },
            onUpdateStatus: (orderId, status) async {
              updatedStatusOrderId = orderId;
              return {'id': orderId, 'status': status};
            },
          ),
        ),
      );
      await tester.pump();

      // Buka detail custom order #11
      await tester.tap(find.text('Custom Cake Pre-Order'));
      await tester.pumpAndSettle();

      expect(find.text('Pesanan #11'), findsOneWidget);
      expect(find.text('Pembeli: Siti Pembeli'), findsOneWidget);
      expect(find.text('Harga Final Custom (Rp)'), findsOneWidget);
      expect(find.text('Kirim Harga ke Pembeli'), findsOneWidget);
      expect(find.text('Tolak Pesanan'), findsOneWidget);

      // Coba kirim tanpa isi harga -> tampil error validasi
      await tester.ensureVisible(find.text('Kirim Harga ke Pembeli'));
      await tester.tap(find.text('Kirim Harga ke Pembeli'));
      await tester.pump();
      expect(find.text('Harga final wajib diisi'), findsOneWidget);
      expect(updatedPriceOrderId, isNull);
      expect(updatedStatusOrderId, isNull);

      // Isi harga 250000 lalu kirim; status tetap pending menunggu pembeli
      await tester.enterText(find.byType(TextField).last, '250000');
      await tester.pump();
      await tester.ensureVisible(find.text('Kirim Harga ke Pembeli'));
      await tester.tap(find.text('Kirim Harga ke Pembeli'));
      await tester.pumpAndSettle();

      expect(updatedPriceOrderId, equals(11));
      expect(updatedPriceValue, equals(250000));
      expect(updatedStatusOrderId, isNull);
      expect(find.text('Rp250.000'), findsOneWidget);
      expect(find.text('Menunggu'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ready-stock pending: hanya Terima & Proses dan Tolak Pesanan (tanpa Setujui)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? lastStatus;

      await tester.pumpWidget(
        _wrap(
          SellerOrdersView(
            initialOrders: [
              {
                'id': 14,
                'buyer_name': 'Dewi Pembeli',
                'cake_name': 'Cokelat Fudge Slice',
                'order_type': 'ready_stock',
                'agreed_price': 45000,
                'status': 'pending',
              },
            ],
            onUpdateStatus: (orderId, status) async {
              lastStatus = status;
              return {'id': orderId, 'status': status};
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Cokelat Fudge Slice'));
      await tester.pumpAndSettle();

      expect(find.text('Terima & Proses'), findsOneWidget);
      expect(find.text('Tolak Pesanan'), findsOneWidget);
      expect(find.text('Setujui'), findsNothing);

      await tester.ensureVisible(find.text('Terima & Proses'));
      await tester.tap(find.text('Terima & Proses'));
      await tester.pumpAndSettle();
      expect(lastStatus, equals('processing'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Transisi status ready-stock (processing -> ready -> completed) berjalan dengan benar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? lastStatus;

      await tester.pumpWidget(
        _wrap(
          SellerOrdersView(
            initialOrders: _sampleOrders(),
            onUpdateStatus: (orderId, status) async {
              lastStatus = status;
              return {'id': orderId, 'status': status};
            },
          ),
        ),
      );
      await tester.pump();

      // Order #12 berstatus processing -> Tandai Siap Diambil
      await tester.tap(find.text('Strawberry Fruit Tart'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tandai Siap Diambil'));
      await tester.tap(find.text('Tandai Siap Diambil'));
      await tester.pumpAndSettle();
      expect(lastStatus, equals('ready'));

      // Order #13 berstatus ready -> Selesaikan Pesanan
      await tester.tap(find.text('Matcha Almond Biscotti'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Selesaikan Pesanan'));
      await tester.tap(find.text('Selesaikan Pesanan'));
      await tester.pumpAndSettle();
      expect(lastStatus, equals('completed'));
      expect(tester.takeException(), isNull);
    },
  );
}
