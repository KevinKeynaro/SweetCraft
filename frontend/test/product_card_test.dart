import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/product_card.dart';

void main() {
  test('formatRupiah memakai pemisah ribuan', () {
    expect(formatRupiah(75000), 'Rp75.000');
    expect(formatRupiah(1250000), 'Rp1.250.000');
    expect(formatRupiah(null), 'Rp0');
  });

  test('stockLabel mengikuti semantik stok', () {
    expect(stockLabel(null), 'Tersedia');
    expect(stockLabel(0), 'Habis');
    expect(stockLabel(3), 'Sisa 3');
    expect(stockLabel(10), 'Tersedia');
  });

  test('displayCategoryName mengubah Artisan Bread menjadi Bread', () {
    expect(displayCategoryName('Artisan Bread'), 'Bread');
    expect(displayCategoryName('artisan bread'), 'Bread');
    expect(displayCategoryName('Pastry'), 'Pastry');
  });

  testWidgets('ProductCard menampilkan nama, kategori, harga, dan stok', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 360,
              child: ProductCard(
                cake: {
                  'name': 'Tart Stroberi',
                  'category': 'Tart',
                  'price': 75000,
                  'stock': 3,
                  'image_url': null,
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tart Stroberi'), findsOneWidget);
    expect(find.text('Tart'), findsOneWidget);
    expect(find.text('Rp75.000'), findsOneWidget);
    expect(find.text('Sisa 3'), findsOneWidget);
  });
}
