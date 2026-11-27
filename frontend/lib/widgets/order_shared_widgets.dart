import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'product_card.dart';

/// Daftar filter status pesanan standar (konsisten dengan enum backend `orders.status`).
const List<({String key, String label})> orderStatusFilters = [
  (key: 'all', label: 'Semua'),
  (key: 'pending', label: 'Menunggu'),
  (key: 'approved', label: 'Disetujui'),
  (key: 'processing', label: 'Diproses'),
  (key: 'ready', label: 'Siap Diambil'),
  (key: 'completed', label: 'Selesai'),
  (key: 'cancelled', label: 'Dibatalkan'),
  (key: 'rejected', label: 'Ditolak'),
];

/// Badge status pesanan dengan warna semantik seragam antara pembeli dan penjual.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'approved' => (
        'Disetujui',
        const Color(0xFFDBEAFE),
        const Color(0xFF1E40AF),
      ),
      'processing' => (
        'Diproses',
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
      ),
      'ready' => (
        'Siap Diambil',
        const Color(0xFFDCFCE7),
        const Color(0xFF166534),
      ),
      'completed' => (
        'Selesai',
        const Color(0xFFE6F4EA),
        const Color(0xFF166534),
      ),
      'rejected' => (
        'Ditolak',
        const Color(0xFFFEE2E2),
        const Color(0xFF991B1B),
      ),
      'cancelled' => (
        'Dibatalkan',
        const Color(0xFFF3EFEA),
        const Color(0xFF6E5D4F),
      ),
      _ => ('Menunggu', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

/// Memformat tanggal MySQL/ISO pesanan menjadi `dd/MM yyyy HH:mm`.
String formatOrderDate(String raw) {
  final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (parsed == null) return raw;
  final d = parsed.day.toString().padLeft(2, '0');
  final m = parsed.month.toString().padLeft(2, '0');
  final hh = parsed.hour.toString().padLeft(2, '0');
  final mm = parsed.minute.toString().padLeft(2, '0');
  return '$d/$m ${parsed.year} $hh:$mm';
}

/// Baris chip filter status pesanan yang wrap rapi tanpa scroll horizontal.
class OrderFilterChipsRow extends StatelessWidget {
  const OrderFilterChipsRow({
    super.key,
    required this.selectedStatus,
    required this.onSelected,
  });

  final String selectedStatus;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in orderStatusFilters)
          InkWell(
            onTap: () => onSelected(item.key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: selectedStatus == item.key
                    ? const Color(0xFF5C341E)
                    : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedStatus == item.key
                      ? const Color(0xFF5C341E)
                      : const Color(0xFFE6DDD0),
                ),
              ),
              child: Text(
                item.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selectedStatus == item.key
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF2B2118),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Blok informasi detail pesanan pada modal bottom sheet.
class OrderDetailBlock extends StatelessWidget {
  const OrderDetailBlock({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6DDD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6E5D4F),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: const Color(0xFF2B2118),
            ),
          ),
        ],
      ),
    );
  }
}

/// Preview gambar referensi custom order dengan fallback aman.
class OrderCustomImagePreview extends StatelessWidget {
  const OrderCustomImagePreview({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xFFFAF7F2),
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Color(0xFF9C8370),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu ringkasan pesanan reusable untuk daftar pesanan pembeli maupun penjual.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showBuyerName = false,
  });

  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final bool showBuyerName;

  @override
  Widget build(BuildContext context) {
    final orderType = order['order_type'] as String? ?? 'ready_stock';
    final isCustom = orderType == 'custom';
    final status = order['status'] as String? ?? 'pending';
    final title = isCustom
        ? 'Custom Cake Pre-Order'
        : (order['cake_name'] as String? ?? 'Pesanan Kue');
    final buyerName = order['buyer_name'] as String?;
    final note = order['decoration_note'] as String?;
    final desc = order['custom_description'] as String?;
    final agreedPrice = order['agreed_price'];
    final pickup = order['pickup_date']?.toString();

    return Material(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      showBuyerName &&
                              buyerName != null &&
                              buyerName.isNotEmpty
                          ? '${isCustom ? 'Custom Pre-Order' : 'Ready Stock'} • $buyerName'
                          : (isCustom ? 'Custom Pre-Order' : 'Ready Stock'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8C4A27),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OrderStatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B2118),
                ),
              ),
              if (isCustom && desc != null && desc.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF6E5D4F),
                  ),
                ),
              ] else if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Catatan: $note',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: const Color(0xFF6E5D4F),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      agreedPrice != null
                          ? formatRupiah(agreedPrice)
                          : (showBuyerName
                                ? 'Belum ada harga final'
                                : 'Menunggu harga penjual'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: agreedPrice != null
                            ? const Color(0xFF8C4A27)
                            : const Color(0xFF92400E),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (pickup != null && pickup.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Ambil: ${formatOrderDate(pickup)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF6E5D4F),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
