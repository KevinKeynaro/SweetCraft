import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.cake});

  final Map<String, dynamic> cake;

  @override
  Widget build(BuildContext context) {
    final stock = cake['stock'];
    final isOutOfStock = stock is num && stock == 0;
    final name = cake['name'] as String? ?? 'Tanpa nama';
    final category = cake['category'] as String? ?? '';
    final imageUrl = cake['image_url'] as String?;

    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DDD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CakeImage(imageUrl: imageUrl),
                Positioned(top: 8, left: 8, child: _StockBadge(stock: stock)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2B2118),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          height: 22 / 14,
                          color: const Color(0xFF6E5D4F),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatRupiah(cake['price']),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2B2118),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return isOutOfStock ? Opacity(opacity: 0.6, child: card) : card;
  }
}

class _CakeImage extends StatelessWidget {
  const _CakeImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const _ImagePlaceholder();
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(color: Color(0xFFF5EFE6));
      },
      errorBuilder: (context, error, stackTrace) {
        return const _ImagePlaceholder();
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF5EFE6),
      child: Center(
        child: Icon(Icons.cake_outlined, size: 40, color: Color(0xFFA79A8C)),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});

  final dynamic stock;

  @override
  Widget build(BuildContext context) {
    final label = stockLabel(stock);

    return Semantics(
      label: 'Status stok: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _stockBackground(stock),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            color: _stockForeground(stock),
          ),
        ),
      ),
    );
  }
}

String stockLabel(dynamic stock) {
  if (stock is num) {
    if (stock == 0) return 'Habis';
    if (stock <= 5) return 'Sisa ${stock.toInt()}';
  }
  return 'Tersedia';
}

Color _stockBackground(dynamic stock) {
  if (stock is num) {
    if (stock == 0) return const Color(0xFFFEE2E2);
    if (stock <= 5) return const Color(0xFFFEF3C7);
  }
  return const Color(0xFFDCFCE7);
}

Color _stockForeground(dynamic stock) {
  if (stock is num) {
    if (stock == 0) return const Color(0xFF991B1B);
    if (stock <= 5) return const Color(0xFF92400E);
  }
  return const Color(0xFF166534);
}

String formatRupiah(dynamic value) {
  final number = value is num
      ? value.round()
      : int.tryParse('${value ?? ''}') ?? 0;
  final digits = number.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }

  return 'Rp$buffer';
}
