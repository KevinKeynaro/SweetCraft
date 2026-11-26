import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kartu produk kue SweetCraft dengan estetika artisanal bakery.
///
/// Menampilkan foto kue, badge status stok, kategori, nama kue,
/// harga terformat Rupiah, dan tombol aksi cepat.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.cake, this.onTap});

  final Map<String, dynamic> cake;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stock = cake['stock'];
    final isOutOfStock = stock is num && stock == 0;
    final name = cake['name'] as String? ?? 'Tanpa nama';
    final category = displayCategoryName(cake['category'] as String?);
    final imageUrl = cake['image_url'] as String?;

    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DDD0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2B2118),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Gambar Kue & Badge Stok
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

          // 2. Konten Kartu (Kategori, Nama, Harga & Aksi)
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
                      if (category.isNotEmpty) ...[
                        Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            height: 14 / 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: const Color(0xFF9C8370),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2B2118),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          formatRupiah(cake['price']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            height: 20 / 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8C4A27),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? const Color(0xFFEFE9E1)
                              : const Color(0xFFFAF7F2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isOutOfStock
                                ? const Color(0xFFE6DDD0)
                                : const Color(0xFF8C4A27),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: isOutOfStock
                              ? const Color(0xFFA79A8C)
                              : const Color(0xFF8C4A27),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: isOutOfStock ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: isOutOfStock ? Opacity(opacity: 0.55, child: card) : card,
    );
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
        return const ColoredBox(
          color: Color(0xFFFAF7F2),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF8C4A27),
              ),
            ),
          ),
        );
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
    return Container(
      color: const Color(0xFFFAF7F2),
      child: const Center(
        child: Icon(Icons.cake_outlined, size: 36, color: Color(0xFF9C8370)),
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            height: 14 / 11,
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

/// Menyeragamkan label kategori tampilan UI tanpa mengubah data backend.
String displayCategoryName(String? name) {
  final trimmed = (name ?? '').trim();
  if (trimmed.toLowerCase() == 'artisan bread') return 'Bread';
  return trimmed;
}
