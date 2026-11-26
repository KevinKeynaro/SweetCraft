import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api.dart';
import 'product_card.dart';

/// Tampilan Daftar & Lacak Pesanan untuk Pembeli (`GET /api/orders` & `POST /api/orders`).
class BuyerOrdersView extends StatefulWidget {
  const BuyerOrdersView({
    super.key,
    this.refreshSignal = 0,
    this.onBrowseCatalog,
  });

  /// Bertambah setiap kali pesanan baru berhasil dibuat dari tab Home.
  final int refreshSignal;
  final VoidCallback? onBrowseCatalog;

  @override
  State<BuyerOrdersView> createState() => _BuyerOrdersViewState();
}

class _BuyerOrdersViewState extends State<BuyerOrdersView> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _error;
  String _selectedStatus = 'all';

  static const _statusFilters = [
    (key: 'all', label: 'Semua'),
    (key: 'pending', label: 'Menunggu'),
    (key: 'approved', label: 'Disetujui'),
    (key: 'processing', label: 'Diproses'),
    (key: 'ready', label: 'Siap Diambil'),
    (key: 'completed', label: 'Selesai'),
    (key: 'rejected', label: 'Ditolak'),
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void didUpdateWidget(covariant BuyerOrdersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshSignal != oldWidget.refreshSignal) {
      _loadOrders();
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final endpoint = _selectedStatus == 'all'
          ? '/orders'
          : '/orders?status=$_selectedStatus';
      final res = await ApiService.get(endpoint);
      final list =
          ((res as Map<String, dynamic>?)?['orders'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      if (!mounted) return;
      setState(() {
        _orders = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat pesanan. Periksa koneksi Anda.';
        _loading = false;
      });
    }
  }

  Future<void> _openOrderDetail(Map<String, dynamic> summary) async {
    final orderId = summary['id'];
    Map<String, dynamic> detail = summary;

    try {
      if (orderId != null) {
        final res = await ApiService.get('/orders/$orderId');
        final fetched = (res as Map<String, dynamic>?)?['order'];
        if (fetched is Map<String, dynamic>) {
          detail = fetched;
        }
      }
    } catch (_) {
      // Tetap tampilkan data ringkasan bila refresh detail gagal
    }

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final orderType = detail['order_type'] as String? ?? 'ready_stock';
        final isCustom = orderType == 'custom';
        final status = detail['status'] as String? ?? 'pending';
        final title = isCustom
            ? 'Custom Cake Pre-Order'
            : (detail['cake_name'] as String? ?? 'Pesanan Kue');
        final customImageUrl = detail['custom_image_url'] as String?;
        final customDesc = detail['custom_description'] as String?;
        final note = detail['decoration_note'] as String?;
        final pickup = detail['pickup_date']?.toString();
        final agreedPrice = detail['agreed_price'];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6DDD0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pesanan #${detail['id'] ?? '-'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6E5D4F),
                      ),
                    ),
                    _OrderStatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2B2118),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  agreedPrice != null
                      ? 'Total Harga: ${formatRupiah(agreedPrice)}'
                      : 'Harga final menunggu konfirmasi penjual',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8C4A27),
                  ),
                ),
                if (customImageUrl != null && customImageUrl.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        customImageUrl,
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
                  ),
                ],
                if (customDesc != null && customDesc.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _detailBlock('Deskripsi Custom', customDesc),
                ],
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailBlock('Catatan Dekorasi', note),
                ],
                if (pickup != null && pickup.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailBlock('Jadwal Ambil', _formatOrderDate(pickup)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF8C4A27),
                    foregroundColor: const Color(0xFFFFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailBlock(String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'Pesanan Saya',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2B2118),
              ),
            ),
          ),

          // Filter status menggunakan Wrap (tanpa scroll horizontal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _statusFilters)
                  InkWell(
                    onTap: () {
                      setState(() => _selectedStatus = item.key);
                      _loadOrders();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedStatus == item.key
                            ? const Color(0xFF5C341E)
                            : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedStatus == item.key
                              ? const Color(0xFF5C341E)
                              : const Color(0xFFE6DDD0),
                        ),
                      ),
                      child: Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _selectedStatus == item.key
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFF2B2118),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              color: const Color(0xFF8C4A27),
              backgroundColor: const Color(0xFFFFFFFF),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8C4A27)),
      );
    }

    if (_error != null && _orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: Color(0xFF991B1B),
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF6E5D4F),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(140, 46),
                backgroundColor: const Color(0xFF8C4A27),
              ),
            ),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.shopping_bag_outlined,
            size: 56,
            color: Color(0xFF9C8370),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada pesanan',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2B2118),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih kue dari katalog atau ajukan pesanan custom cake Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF6E5D4F),
            ),
          ),
          const SizedBox(height: 18),
          if (widget.onBrowseCatalog != null)
            Center(
              child: FilledButton(
                onPressed: widget.onBrowseCatalog,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(180, 48),
                  backgroundColor: const Color(0xFF8C4A27),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Jelajahi Katalog'),
              ),
            ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _BuyerOrderCard(
          order: order,
          onTap: () => _openOrderDetail(order),
        );
      },
    );
  }
}

class _BuyerOrderCard extends StatelessWidget {
  const _BuyerOrderCard({required this.order, required this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final orderType = order['order_type'] as String? ?? 'ready_stock';
    final isCustom = orderType == 'custom';
    final status = order['status'] as String? ?? 'pending';
    final title = isCustom
        ? 'Custom Cake Pre-Order'
        : (order['cake_name'] as String? ?? 'Pesanan Kue');
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
                color: Color(0x082B2118),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isCustom ? 'Custom Pre-Order' : 'Ready Stock',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8C4A27),
                    ),
                  ),
                  _OrderStatusBadge(status: status),
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
                  Text(
                    agreedPrice != null
                        ? formatRupiah(agreedPrice)
                        : 'Menunggu harga penjual',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: agreedPrice != null
                          ? const Color(0xFF8C4A27)
                          : const Color(0xFF92400E),
                    ),
                  ),
                  if (pickup != null && pickup.isNotEmpty)
                    Text(
                      'Ambil: ${_formatOrderDate(pickup)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF6E5D4F),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'approved' => ('Disetujui', const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
      'processing' => ('Diproses', const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'ready' => ('Siap Diambil', const Color(0xFFDCFCE7), const Color(0xFF166534)),
      'completed' => ('Selesai', const Color(0xFFE6F4EA), const Color(0xFF1E6B3A)),
      'rejected' => ('Ditolak', const Color(0xFFFDE8E8), const Color(0xFFA63232)),
      'cancelled' => ('Dibatalkan', const Color(0xFFF3EFEA), const Color(0xFF6E5D4F)),
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

String _formatOrderDate(String raw) {
  final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (parsed == null) return raw;
  final d = parsed.day.toString().padLeft(2, '0');
  final m = parsed.month.toString().padLeft(2, '0');
  final hh = parsed.hour.toString().padLeft(2, '0');
  final mm = parsed.minute.toString().padLeft(2, '0');
  return '$d/$m ${parsed.year} $hh:$mm';
}
