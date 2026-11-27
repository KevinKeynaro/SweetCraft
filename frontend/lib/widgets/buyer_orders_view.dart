import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api.dart';
import 'order_shared_widgets.dart';
import 'product_card.dart';

/// Tampilan Daftar & Lacak Pesanan untuk Pembeli (`GET /api/orders` & `POST /api/orders`).
class BuyerOrdersView extends StatefulWidget {
  const BuyerOrdersView({
    super.key,
    this.refreshSignal = 0,
    this.onBrowseCatalog,
    this.initialOrders,
    this.onDecide,
    this.onCancel,
  });

  /// Bertambah setiap kali pesanan baru berhasil dibuat dari tab Home.
  final int refreshSignal;
  final VoidCallback? onBrowseCatalog;

  /// Opsional untuk pengujian widget tanpa memanggil API langsung.
  final List<Map<String, dynamic>>? initialOrders;
  final Future<Map<String, dynamic>> Function(int orderId, String status)?
  onDecide;
  final Future<Map<String, dynamic>> Function(int orderId)? onCancel;

  @override
  State<BuyerOrdersView> createState() => _BuyerOrdersViewState();
}

class _BuyerOrdersViewState extends State<BuyerOrdersView> {
  List<Map<String, dynamic>> _orders = [];
  late List<Map<String, dynamic>> _seedOrders;
  bool _loading = true;
  String? _error;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _seedOrders = widget.initialOrders == null
        ? const []
        : List<Map<String, dynamic>>.from(widget.initialOrders!);
    if (widget.initialOrders != null) {
      _orders = List<Map<String, dynamic>>.from(_seedOrders);
      _loading = false;
      return;
    }
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
    if (widget.initialOrders != null) {
      setState(() {
        _orders = _seedOrders
            .where(
              (o) =>
                  _selectedStatus == 'all' || o['status'] == _selectedStatus,
            )
            .map((o) => Map<String, dynamic>.from(o))
            .toList();
        _loading = false;
      });
      return;
    }

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
      if (orderId != null && widget.initialOrders == null) {
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
      builder: (ctx) => _BuyerOrderSheet(
        order: detail,
        onDecide: widget.onDecide,
        onCancel: widget.onCancel,
        onUpdated: (updated) {
          setState(() {
            final idx = _orders.indexWhere((o) => o['id'] == updated['id']);
            if (idx != -1) _orders[idx] = {..._orders[idx], ...updated};
          });
        },
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OrderFilterChipsRow(
              selectedStatus: _selectedStatus,
              onSelected: (statusKey) {
                setState(() => _selectedStatus = statusKey);
                _loadOrders();
              },
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
        return OrderSummaryCard(
          order: order,
          onTap: () => _openOrderDetail(order),
        );
      },
    );
  }
}

/// Detail pesanan pembeli + aksi keputusan pre-order dan pembatalan.
///
/// Aturan backend yang dicerminkan di sini:
/// - custom `pending`: setujui/tolak harga final, atau batalkan.
/// - ready-stock `pending`/`approved`: batalkan dalam 60 menit sejak dibuat.
class _BuyerOrderSheet extends StatefulWidget {
  const _BuyerOrderSheet({
    required this.order,
    required this.onUpdated,
    this.onDecide,
    this.onCancel,
  });

  final Map<String, dynamic> order;
  final ValueChanged<Map<String, dynamic>> onUpdated;
  final Future<Map<String, dynamic>> Function(int orderId, String status)?
  onDecide;
  final Future<Map<String, dynamic>> Function(int orderId)? onCancel;

  @override
  State<_BuyerOrderSheet> createState() => _BuyerOrderSheetState();
}

class _BuyerOrderSheetState extends State<_BuyerOrderSheet> {
  late Map<String, dynamic> _order = Map<String, dynamic>.from(widget.order);
  bool _saving = false;

  static const _cancelWindow = Duration(minutes: 60);

  String get _status => _order['status'] as String? ?? 'pending';
  bool get _isCustom => _order['order_type'] == 'custom';
  bool get _hasPrice => _order['agreed_price'] != null;

  bool get _withinCancelWindow {
    final raw = _order['created_at']?.toString();
    if (raw == null || raw.isEmpty) return true;
    final createdAt = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (createdAt == null) return true;
    return DateTime.now().difference(createdAt) < _cancelWindow;
  }

  bool get _canCancel {
    if (_isCustom) return _status == 'pending';
    return (_status == 'pending' || _status == 'approved') &&
        _withinCancelWindow;
  }

  bool get _canDecide => _isCustom && _status == 'pending' && _hasPrice;

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFF991B1B)
            : const Color(0xFF166534),
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String actionLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2B2118),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF6E5D4F),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx, false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      foregroundColor: const Color(0xFF6E5D4F),
                    ),
                    child: const Text('Kembali'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogCtx, true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 44),
                      backgroundColor: const Color(0xFF991B1B),
                      foregroundColor: const Color(0xFFFFFFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  Future<void> _send({
    required bool isCancel,
    required String status,
    required String success,
  }) async {
    final id = _order['id'];
    if (id == null || _saving) return;

    setState(() => _saving = true);
    try {
      Map<String, dynamic>? updated;
      if (isCancel) {
        if (widget.onCancel != null) {
          updated = await widget.onCancel!(id as int);
        } else {
          final res = await ApiService.post('/orders/$id/cancel', const {});
          updated = (res as Map<String, dynamic>?)?['order']
              as Map<String, dynamic>?;
        }
      } else {
        if (widget.onDecide != null) {
          updated = await widget.onDecide!(id as int, status);
        } else {
          final res = await ApiService.put('/orders/$id/decision', {
            'status': status,
          });
          updated = (res as Map<String, dynamic>?)?['order']
              as Map<String, dynamic>?;
        }
      }
      if (!mounted) return;

      final merged = {..._order, ...?updated, 'status': status};
      setState(() => _order = merged);
      widget.onUpdated(merged);
      _showSnack(success);
      Navigator.pop(context);
    } on ApiException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (_) {
      _showSnack('Gagal memproses pesanan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _decide(String status) async {
    final id = _order['id'];
    if (id == null) return;
    final accepting = status == 'approved';
    final confirmed = await _confirm(
      title: accepting ? 'Setujui Harga?' : 'Tolak Harga?',
      body: accepting
          ? 'Harga final akan disetujui dan pesanan masuk ke produksi.'
          : 'Penawaran harga akan ditolak dan pre-order berakhir.',
      actionLabel: accepting ? 'Setujui' : 'Tolak',
    );
    if (!confirmed || !mounted) return;
    await _send(
      isCancel: false,
      status: status,
      success: accepting ? 'Harga disetujui' : 'Harga ditolak',
    );
  }

  Future<void> _cancel() async {
    final id = _order['id'];
    if (id == null) return;
    final confirmed = await _confirm(
      title: 'Batalkan Pesanan?',
      body: 'Pesanan #$id akan dibatalkan dan tidak dapat diproses lagi.',
      actionLabel: 'Batalkan',
    );
    if (!confirmed || !mounted) return;
    await _send(
      isCancel: true,
      status: 'cancelled',
      success: 'Pesanan dibatalkan',
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCustom
        ? 'Custom Cake Pre-Order'
        : (_order['cake_name'] as String? ?? 'Pesanan Kue');
    final customImageUrl = _order['custom_image_url'] as String?;
    final customDesc = _order['custom_description'] as String?;
    final note = _order['decoration_note'] as String?;
    final pickup = _order['pickup_date']?.toString();
    final agreedPrice = _order['agreed_price'];

    return SafeArea(
      child: SingleChildScrollView(
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
                  'Pesanan #${_order['id'] ?? '-'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6E5D4F),
                  ),
                ),
                OrderStatusBadge(status: _status),
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
              OrderCustomImagePreview(imageUrl: customImageUrl),
            ],
            if (customDesc != null && customDesc.isNotEmpty) ...[
              const SizedBox(height: 14),
              OrderDetailBlock(label: 'Deskripsi Custom', value: customDesc),
            ],
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 10),
              OrderDetailBlock(label: 'Catatan Dekorasi', value: note),
            ],
            if (pickup != null && pickup.isNotEmpty) ...[
              const SizedBox(height: 10),
              OrderDetailBlock(
                label: 'Jadwal Ambil',
                value: formatOrderDate(pickup),
              ),
            ],
            if (_canDecide) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : () => _decide('approved'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFF8C4A27),
                  foregroundColor: const Color(0xFFFFFFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Setujui Harga'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _saving ? null : () => _decide('rejected'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF991B1B),
                  side: const BorderSide(color: Color(0xFF991B1B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Tolak Harga'),
              ),
            ],
            if (_canCancel) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _saving ? null : _cancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: const Color(0xFF991B1B),
                  side: const BorderSide(color: Color(0xFF991B1B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Batalkan Pesanan'),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
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
  }
}
